//
//  WFCUAsrManager.m
//  WFChatUIKit
//
//  Created by WildFireChat.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "WFCUAsrManager.h"
#import "WFCUAsrAuth.h"
#import "WFCUAsrWebSocketClient.h"
#import "WFCUPcmAudioRecorder.h"
#import "WFCUConfigManager.h"
#import <WFChatClient/WFCChatClient.h>

static const NSTimeInterval kMaxRecordingDuration = 60.0;      // 最长录音时长：60秒
static const NSTimeInterval kWaitEosTimeout = 8.0;             // 停止录音后等待剩余识别结果的最长时间：8秒
// 停止录音后服务端一直没有推送消息，认为已经识别完。服务端不支持 eos 指令时不会回复 [EOS]，靠它结束识别
static const NSTimeInterval kWaitEosIdleTimeout = 3.0;
// 停止录音后收到过识别结果，之后这么久没有新消息，认为已经识别完
static const NSTimeInterval kWaitEosIdleAfterResult = 1.5;
// 16kHz、16-bit 的音频每毫秒 32 字节
static const NSInteger kPcmBytesPerMillisecond = 32;

typedef NS_ENUM(NSInteger, WFCUAsrState) {
    WFCUAsrStateIdle,       // 空闲
    WFCUAsrStateConnecting, // 连接中，已经开始录音或接收调用方提供的音频，音频先缓存
    WFCUAsrStateRecording,  // 已连接，录音中
    WFCUAsrStateFinishing   // 已停止录音，等待剩余识别结果
};

@interface WFCUAsrManager () <WFCUAsrWebSocketClientDelegate>
@property (nonatomic, assign) WFCUAsrState state;
@property (nonatomic, strong) WFCUPcmAudioRecorder *audioRecorder;
@property (nonatomic, strong) WFCUAsrWebSocketClient *wsClient;

// 本次识别已确定的文本，即各句的最终结果
@property (nonatomic, copy) NSString *recognizedText;
// 正在说的这句的中间结果，收到这句的最终结果后清空
@property (nonatomic, copy) NSString *partialText;

// 音频由调用方通过 feedAudioData: 提供，而不是自己录音
@property (nonatomic, assign) BOOL feedAudio;
// 连接成功前已经停止录音或停止提供音频，连接成功后发送完缓存的音频再结束识别
@property (nonatomic, assign) BOOL pendingStop;
// 调用方提供的音频字节数，用于估算等待剩余识别结果的时间
@property (nonatomic, assign) long long feedAudioBytes;

@property (nonatomic, copy) dispatch_block_t maxDurationBlock;
@property (nonatomic, copy) dispatch_block_t waitEosTimeoutBlock;
@property (nonatomic, copy) dispatch_block_t waitEosIdleBlock;
@end

@implementation WFCUAsrManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _state = WFCUAsrStateIdle;
        _recognizedText = @"";
        _partialText = @"";
    }
    return self;
}

- (void)setHotwordOverEnabled:(BOOL)hotwordOverEnabled {
    _hotwordOverEnabled = hotwordOverEnabled;
}

#pragma mark - 对外接口

- (void)startRecognition {
    [self startWithFeedAudio:NO];
}

- (void)startRecognitionWithAudioFeed {
    [self startWithFeedAudio:YES];
}

- (void)startWithFeedAudio:(BOOL)feedAudio {
    if (self.state != WFCUAsrStateIdle) {
        NSLog(@"[WFCUAsr] 正在识别中，无需重复开始");
        return;
    }
    NSString *url = [WFCUConfigManager globalManager].asrStreamServiceUrl;
    if (!url.length) {
        [self notifyError:@"未配置语音识别服务地址"];
        return;
    }

    self.feedAudio = feedAudio;
    self.state = WFCUAsrStateConnecting;
    self.recognizedText = @"";
    self.partialText = @"";
    self.pendingStop = NO;
    self.feedAudioBytes = 0;

    WFCUAsrWebSocketClient *client = [[WFCUAsrWebSocketClient alloc] init];
    client.delegate = self;
    self.wsClient = client;

    if (!feedAudio) {
        // 获取认证码、连接识别服务可能要一两秒，用户点完就开始说话。先开始录音，音频由 wsClient 缓存到连接成功后发送
        [self startAudioRecording];
    }
    // wf-voice 要求每个连接的 clientId 唯一，并会用作服务端录音文件名。连接 asr-api 时由 asr-api 重新生成
    NSString *userId = [WFCCNetworkService sharedInstance].userId ?: @"";
    NSString *clientId = [NSString stringWithFormat:@"%@-%@", userId, [[NSUUID UUID].UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""]];
    BOOL partialResult = [WFCUConfigManager globalManager].enableAsrPartialResult;

    if (![WFCUAsrAuth isAsrApiUrl:url]) {
        // 直连 wf-voice，不需要鉴权
        [client connect:url clientId:clientId partialResult:partialResult authCode:nil];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [WFCUAsrAuth getAuthCode:^(NSString *authCode) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        // 获取认证码期间，识别可能已经停止或取消
        if (self.wsClient == client) {
            [client connect:url clientId:clientId partialResult:partialResult authCode:authCode];
        }
    } error:^(int errorCode) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (self.wsClient == client) {
            [self failRecognition:[NSString stringWithFormat:@"获取认证码失败: %d", errorCode]];
        }
    }];
}

- (void)stopRecognition {
    if (self.state == WFCUAsrStateConnecting) {
        if (self.pendingStop) {
            return;
        }
        BOOL hasAudio = self.audioRecorder != nil || self.feedAudioBytes > 0;
        [self stopAudioRecording];
        if (hasAudio) {
            // 连接成功后发送完缓存的音频再结束，一直连不上时超时
            NSLog(@"[WFCUAsr] 停止录音，连接成功后再结束识别");
            self.pendingStop = YES;
            [self cancelTimeout:&_maxDurationBlock];
            [self cancelTimeout:&_waitEosTimeoutBlock];
            __weak typeof(self) weakSelf = self;
            self.waitEosTimeoutBlock = [self scheduleAfter:kWaitEosTimeout block:^{
                [weakSelf onWaitEosTimeout];
            }];
        } else {
            // 还没有音频
            [self finishRecognition];
        }
    } else if (self.state == WFCUAsrStateRecording) {
        NSLog(@"[WFCUAsr] 停止录音，等待剩余识别结果");
        self.state = WFCUAsrStateFinishing;
        [self cancelTimeout:&_maxDurationBlock];
        [self stopAudioRecording];
        [self.wsClient sendEos];
        // 一次提供了较长的音频时，服务端需要更多时间识别。按音频时长增加等待时间
        long long audioMs = self.feedAudioBytes / kPcmBytesPerMillisecond;
        [self cancelTimeout:&_waitEosTimeoutBlock];
        __weak typeof(self) weakSelf = self;
        self.waitEosTimeoutBlock = [self scheduleAfter:kWaitEosTimeout + audioMs / 2000.0 block:^{
            [weakSelf onWaitEosTimeout];
        }];
        [self cancelTimeout:&_waitEosIdleBlock];
        self.waitEosIdleBlock = [self scheduleAfter:kWaitEosIdleTimeout + audioMs / 10000.0 block:^{
            [weakSelf onWaitEosIdle];
        }];
    }
}

- (void)feedAudioData:(NSData *)pcmData {
    if (!self.feedAudio || self.pendingStop || (self.state != WFCUAsrStateConnecting && self.state != WFCUAsrStateRecording)) {
        return;
    }
    [self.wsClient sendAudioData:pcmData];
    self.feedAudioBytes += pcmData.length;
}

- (void)cancelRecognition {
    if (self.state != WFCUAsrStateIdle) {
        NSLog(@"[WFCUAsr] 取消识别");
        [self cleanup];
    }
}

- (BOOL)isRecognizing {
    return self.state != WFCUAsrStateIdle;
}

#pragma mark - 超时处理

- (void)onWaitEosTimeout {
    if (self.state == WFCUAsrStateConnecting) {
        NSLog(@"[WFCUAsr] 连接语音识别服务超时");
        [self failRecognition:@"连接语音识别服务超时"];
    } else {
        NSLog(@"[WFCUAsr] 等待剩余识别结果超时，结束识别");
        [self finishRecognition];
    }
}

- (void)onWaitEosIdle {
    NSLog(@"[WFCUAsr] 没有收到 [EOS]，按已返回的识别结果结束识别");
    [self finishRecognition];
}

/**
 * 停止录音后又收到识别结果，重新计算没有新消息就结束识别的时间
 */
- (void)delayIdleFinish {
    if (self.state == WFCUAsrStateFinishing) {
        [self cancelTimeout:&_waitEosIdleBlock];
        __weak typeof(self) weakSelf = self;
        self.waitEosIdleBlock = [self scheduleAfter:kWaitEosIdleAfterResult block:^{
            [weakSelf onWaitEosIdle];
        }];
    }
}

#pragma mark - WFCUAsrWebSocketClientDelegate

- (void)asrWebSocketClientDidConnect:(WFCUAsrWebSocketClient *)client {
    if (self.wsClient != client) {
        return;
    }
    self.state = WFCUAsrStateRecording;
    if (self.pendingStop) {
        self.pendingStop = NO;
        [self stopRecognition];
    }
}

- (void)asrWebSocketClient:(WFCUAsrWebSocketClient *)client didReceivePartialResult:(NSString *)text {
    if (self.wsClient != client) {
        return;
    }
    [self delayIdleFinish];
    self.partialText = text;
    [self notifyPartialResult:[self getText]];
}

- (void)asrWebSocketClient:(WFCUAsrWebSocketClient *)client didReceiveResult:(NSString *)text {
    if (self.wsClient != client) {
        return;
    }
    [self delayIdleFinish];
    [self handleSentenceResult:text];
}

- (void)asrWebSocketClientDidReceiveEos:(WFCUAsrWebSocketClient *)client {
    if (self.wsClient != client) {
        return;
    }
    [self finishRecognition];
}

- (void)asrWebSocketClient:(WFCUAsrWebSocketClient *)client didFailWithError:(NSString *)error {
    NSLog(@"[WFCUAsr] 语音识别服务错误: %@", error);
    if (self.state == WFCUAsrStateFinishing) {
        // 已经停止录音，保留已识别出的文本
        [self finishRecognition];
    } else {
        [self failRecognition:error];
    }
}

#pragma mark - 录音

- (void)startAudioRecording {
    WFCUAsrWebSocketClient *client = self.wsClient;
    WFCUPcmAudioRecorder *recorder = [[WFCUPcmAudioRecorder alloc] init];
    self.audioRecorder = recorder;
    __weak typeof(self) weakSelf = self;
    recorder.dataCallback = ^(NSData *pcmData) {
        // 在内部串行队列回调，实时发送到服务端，还没连接成功时 client 会先缓存
        [client sendAudioData:pcmData];
    };
    recorder.errorCallback = ^(NSString *message) {
        // 忽略已经停止的录音报的错误，包括停止录音时录音线程退出前报的错误
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (self.audioRecorder == recorder) {
            [self failRecognition:[NSString stringWithFormat:@"录音失败: %@", message]];
        }
    };
    BOOL success = [recorder startRecording];
    // 启动失败时 PcmAudioRecorder 会回调 errorCallback，由它结束识别
    if (success) {
        NSLog(@"[WFCUAsr] 录音已开始");
        __weak typeof(self) weakSelf2 = self;
        self.maxDurationBlock = [self scheduleAfter:kMaxRecordingDuration block:^{
            NSLog(@"[WFCUAsr] 达到最大录音时长，自动停止");
            [weakSelf2 stopRecognition];
        }];
    }
}

- (void)stopAudioRecording {
    if (self.audioRecorder) {
        [self.audioRecorder stopRecording];
        self.audioRecorder = nil;
    }
}

#pragma mark - 结果处理

- (void)handleSentenceResult:(NSString *)sentence {
    self.partialText = @"";
    self.recognizedText = [WFCUAsrManager join:self.recognizedText sentence:sentence];

    if (self.hotwordOverEnabled) {
        NSRange match = [WFCUAsrManager hotwordOverRangeIn:self.recognizedText];
        if (match.location != NSNotFound) {
            NSLog(@"[WFCUAsr] 检测到 Over 热词");
            NSString *text = [[WFCUAsrManager removeHotwordOverFrom:self.recognizedText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            id<WFCUAsrManagerDelegate> delegate = self.delegate;
            [self cleanup];
            if ([delegate respondsToSelector:@selector(asrManager:onHotwordDetected:text:)]) {
                [delegate asrManager:self onHotwordDetected:@"Over" text:text];
            }
            return;
        }
    }

    [self notifyPartialResult:[self getText]];
}

/**
 * 已确定的文本，加上正在说的这句的中间结果
 */
- (NSString *)getText {
    return [WFCUAsrManager join:self.recognizedText sentence:self.partialText];
}

/**
 * 拼接两段识别文本，两段英文之间补一个空格
 */
+ (NSString *)join:(NSString *)text sentence:(NSString *)sentence {
    if (text.length && sentence.length) {
        unichar last = [text characterAtIndex:text.length - 1];
        unichar first = [sentence characterAtIndex:0];
        if (last < 128 && ![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:last]
            && first < 128 && [[NSCharacterSet alphanumericCharacterSet] characterIsMember:first]) {
            return [NSString stringWithFormat:@"%@ %@", text, sentence];
        }
    }
    return [NSString stringWithFormat:@"%@%@", text, sentence];
}

- (void)finishRecognition {
    if (self.state == WFCUAsrStateIdle) {
        return;
    }
    id<WFCUAsrManagerDelegate> delegate = self.delegate;
    // wf-voice 会把句号替换成逗号，去掉结尾多余的逗号
    NSString *text = [WFCUAsrManager trimTrailingCommas:[self getText]];
    [self cleanup];
    if ([delegate respondsToSelector:@selector(asrManager:onFinalResult:)]) {
        [delegate asrManager:self onFinalResult:text];
    }
}

- (void)failRecognition:(NSString *)message {
    if (self.state == WFCUAsrStateIdle) {
        return;
    }
    id<WFCUAsrManagerDelegate> delegate = self.delegate;
    [self cleanup];
    if ([delegate respondsToSelector:@selector(asrManager:onError:)]) {
        [delegate asrManager:self onError:message];
    }
}

- (void)cleanup {
    self.state = WFCUAsrStateIdle;
    self.delegate = nil;
    [self cancelTimeout:&_maxDurationBlock];
    [self cancelTimeout:&_waitEosTimeoutBlock];
    [self cancelTimeout:&_waitEosIdleBlock];
    [self stopAudioRecording];
    if (self.wsClient) {
        [self.wsClient disconnect];
        self.wsClient = nil;
    }
    self.recognizedText = @"";
    self.partialText = @"";
    self.feedAudio = NO;
    self.pendingStop = NO;
    self.feedAudioBytes = 0;
}

#pragma mark - 回调

- (void)notifyPartialResult:(NSString *)text {
    id<WFCUAsrManagerDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(asrManager:onPartialResult:)]) {
        [delegate asrManager:self onPartialResult:text];
    }
}

- (void)notifyError:(NSString *)message {
    id<WFCUAsrManagerDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(asrManager:onError:)]) {
        [delegate asrManager:self onError:message];
    }
}

#pragma mark - 定时器

- (dispatch_block_t)scheduleAfter:(NSTimeInterval)delay block:(dispatch_block_t)block {
    dispatch_block_t timedBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, block);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), timedBlock);
    return timedBlock;
}

- (void)cancelTimeout:(dispatch_block_t __strong *)block {
    if (*block) {
        dispatch_block_cancel(*block);
        *block = nil;
    }
}

#pragma mark - 工具

+ (NSString *)trimTrailingCommas:(NSString *)text {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[，,]+$" options:0 error:nil];
    return [regex stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
}

+ (NSRegularExpression *)hotwordOverRegex {
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"(?i)(over|欧弗|结束)[，,.。\\s]*$" options:0 error:nil];
    });
    return regex;
}

+ (NSRange)hotwordOverRangeIn:(NSString *)text {
    NSRegularExpression *regex = [self hotwordOverRegex];
    return [regex rangeOfFirstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
}

+ (NSString *)removeHotwordOverFrom:(NSString *)text {
    NSRegularExpression *regex = [self hotwordOverRegex];
    return [regex stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
}

@end
