//
//  WFCUAsrWebSocketClient.m
//  WFChatUIKit
//
//  Created by WildFireChat.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "WFCUAsrWebSocketClient.h"
#import "WFCUAsrAuth.h"
#import <WFChatClient/WFCCCertificateManager.h>

static NSString *const kMessageEos = @"eos";
static NSString *const kMessagePartial = @"partial";
static NSString *const kMessageEosAck = @"[EOS]";
static NSString *const kMessagePartialPrefix = @"[PARTIAL]";
static NSString *const kMessagePong = @"pong";
static NSString *const kMessageTrialPrefix = @"[TRIAL]";

// 发送 eos 前补发约 500ms 静音，让不支持 eos 的旧版本 wf-voice 也能通过 VAD 断句，识别出最后一句。
// 静音和录音一样按 30ms（960 字节）一条消息发送，单条消息过大时 asr-api 或 wf-voice 会断开连接
static const NSInteger kSilenceFrameBytes = 960;
static const NSInteger kSilencePaddingFrames = 17;
// 心跳间隔，和 Android 端 OkHttp 的 pingInterval 保持一致
static const NSTimeInterval kPingInterval = 30.0;

@interface WFCUAsrWebSocketClient ()
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionWebSocketTask *webSocketTask API_AVAILABLE(ios(13.0));
// 连接成功之前发送的音频，连接成功后发送
@property (nonatomic, strong) NSMutableArray<NSData *> *pendingAudio;
@property (nonatomic, assign) BOOL opened;
@property (nonatomic, assign) BOOL disconnected;
@property (nonatomic, strong) NSTimer *pingTimer;
@end

@implementation WFCUAsrWebSocketClient

- (instancetype)init {
    self = [super init];
    if (self) {
        // 必须在 init 里初始化：获取 authCode、建立连接都要时间，这期间录音已经在产生音频，
        // 会先调用 sendAudioData 缓存起来。如果等到 connect 里才创建，先到的音频会被静默丢掉，
        // 表现为"开始说话到连接建立之间的录音没有发过去"（例如按按住说话滑到转文字之前的录音）
        _pendingAudio = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    [self.pingTimer invalidate];
    self.pingTimer = nil;
}

- (void)connect:(NSString *)url
       clientId:(NSString *)clientId
  partialResult:(BOOL)partialResult
       authCode:(NSString *)authCode {
    NSLog(@"[WFCUAsr][WS] 开始连接 %@", url);
    if (@available(iOS 13.0, *)) {
        NSURL *nsUrl = [NSURL URLWithString:url];
        if (!nsUrl) {
            NSLog(@"[WFCUAsr][WS] 地址无效: %@", url);
            [self notifyError:@"语音识别服务地址无效"];
            return;
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsUrl];
        if (authCode.length) {
            [request setValue:authCode forHTTPHeaderField:WFCUAsrAuth.headerAuthCode];
        }
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 5;
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        // 自签证书的 wss 地址需要统一的证书信任评估
        self.session = [NSURLSession sessionWithConfiguration:config
                                                     delegate:[WFCCCertificateURLSessionDelegate delegateWithManager:[WFCCCertificateManager sharedManager]]
                                                delegateQueue:nil];
        self.webSocketTask = [self.session webSocketTaskWithRequest:request];
        // 注意：不要在这里重建 pendingAudio，connect 之前可能已经缓存了音频（见 init）
        if (!self.pendingAudio) {
            self.pendingAudio = [NSMutableArray array];
        }
        self.opened = NO;
        self.disconnected = NO;
        [self.webSocketTask resume];
        [self receiveNextMessage];

        // 连接后发送的第一条文本消息是 clientId，发送成功说明连接已经建立
        __weak typeof(self) weakSelf = self;
        NSURLSessionWebSocketMessage *message = [[NSURLSessionWebSocketMessage alloc] initWithString:clientId];
        [self.webSocketTask sendMessage:message completionHandler:^(NSError *error) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            if (error) {
                NSLog(@"[WFCUAsr][WS] 发送 clientId 失败: %@", error.localizedDescription);
                [self handleFailure:error];
                return;
            }
            [self onOpened:clientId partialResult:partialResult];
        }];
        [self startPing];
    } else {
        [self notifyError:@"当前系统版本不支持实时语音识别"];
    }
}

- (void)sendAudioData:(NSData *)pcmData {
    if (!pcmData.length) {
        return;
    }
    BOOL shouldSend = NO;
    @synchronized (self) {
        if (self.disconnected) {
            return;
        }
        if (!self.opened) {
            if (!self.pendingAudio) {
                self.pendingAudio = [NSMutableArray array];
            }
            [self.pendingAudio addObject:pcmData];
            return;
        }
        shouldSend = YES;
    }
    if (shouldSend) {
        [self sendDataMessage:pcmData];
    }
}

- (void)sendEos {
    @synchronized (self) {
        if (@available(iOS 13.0, *)) {
            if (!self.opened || self.disconnected || self.webSocketTask == nil) {
                return;
            }
        } else {
            // Fallback on earlier versions
        }
    }
    NSLog(@"[WFCUAsr][WS] 发送 eos");
    uint8_t silence[kSilenceFrameBytes];
    memset(silence, 0, sizeof(silence));
    NSData *silenceData = [NSData dataWithBytes:silence length:sizeof(silence)];
    for (NSInteger i = 0; i < kSilencePaddingFrames; i++) {
        [self sendDataMessage:silenceData];
    }
    [self sendTextMessage:kMessageEos];
}

- (void)disconnect {
    NSURLSessionWebSocketTask *task = nil;
    @synchronized (self) {
        if (self.disconnected) {
            return;
        }
        self.disconnected = YES;
        self.delegate = nil;
        [self.pendingAudio removeAllObjects];
        task = self.webSocketTask;
        self.webSocketTask = nil;
    }
    [self.pingTimer invalidate];
    self.pingTimer = nil;
    if (@available(iOS 13.0, *)) {
        [task cancelWithCloseCode:NSURLSessionWebSocketCloseCodeNormalClosure reason:nil];
    }
    [self.session invalidateAndCancel];
    self.session = nil;
}

#pragma mark - 私有方法

- (void)onOpened:(NSString *)clientId partialResult:(BOOL)partialResult {
    NSArray<NSData *> *pending = nil;
    @synchronized (self) {
        if (self.disconnected) {
            return;
        }
        if (partialResult) {
            [self sendTextMessage:kMessagePartial];
        }
        pending = [self.pendingAudio copy];
        [self.pendingAudio removeAllObjects];
        self.opened = YES;
    }
    NSUInteger pendingBytes = 0;
    for (NSData *data in pending) {
        pendingBytes += data.length;
        [self sendDataMessage:data];
    }
    NSLog(@"[WFCUAsr][WS] 连接成功 partial=%d，补发连接前缓存的音频 %lu 帧 / %lu 字节",
          partialResult, (unsigned long)pending.count, (unsigned long)pendingBytes);
    WFCUAsrWebSocketClient *client = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (client.disconnected) {
            return;
        }
        if ([client.delegate respondsToSelector:@selector(asrWebSocketClientDidConnect:)]) {
            [client.delegate asrWebSocketClientDidConnect:client];
        }
    });
}

- (void)sendDataMessage:(NSData *)data {
    if (@available(iOS 13.0, *)) {
        NSURLSessionWebSocketTask *task = self.webSocketTask;
        if (!task) {
            return;
        }
        NSURLSessionWebSocketMessage *message = [[NSURLSessionWebSocketMessage alloc] initWithData:data];
        [task sendMessage:message completionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"[WFCUAsr][WS] 发送音频数据失败: %@", error.localizedDescription);
            }
        }];
    }
}

- (void)sendTextMessage:(NSString *)text {
    if (@available(iOS 13.0, *)) {
        NSURLSessionWebSocketTask *task = self.webSocketTask;
        if (!task) {
            return;
        }
        NSURLSessionWebSocketMessage *message = [[NSURLSessionWebSocketMessage alloc] initWithString:text];
        [task sendMessage:message completionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"[WFCUAsr][WS] 发送消息失败: %@", error.localizedDescription);
            }
        }];
    }
}

- (void)receiveNextMessage {
    if (@available(iOS 13.0, *)) {
        NSURLSessionWebSocketTask *task = self.webSocketTask;
        if (!task) {
            return;
        }
        __weak typeof(self) weakSelf = self;
        [task receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage *message, NSError *error) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            if (self.disconnected) {
                return;
            }
            if (error) {
                [self handleFailure:error];
                return;
            }
            if (message.type == NSURLSessionWebSocketMessageTypeString && message.string.length) {
                [self handleText:message.string];
            }
            [self receiveNextMessage];
        }];
    }
}

- (void)startPing {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.disconnected || self.pingTimer) {
            return;
        }
        self.pingTimer = [NSTimer scheduledTimerWithTimeInterval:kPingInterval
                                                          target:self
                                                        selector:@selector(sendPing)
                                                        userInfo:nil
                                                         repeats:YES];
    });
}

- (void)sendPing {
    if (@available(iOS 13.0, *)) {
        NSURLSessionWebSocketTask *task = self.webSocketTask;
        if (!task || self.disconnected) {
            return;
        }
        [task sendPingWithPongReceiveHandler:^(NSError *error) {
            if (error) {
                NSLog(@"[WFCUAsr][WS] ping 失败: %@", error.localizedDescription);
            }
        }];
    }
}

- (void)handleText:(NSString *)message {
    // 中间结果很频繁，不打印；其余消息（每句最终结果、[EOS]、[TRIAL] 等）打出来便于排查
    if (![message isEqualToString:kMessagePong] && ![message hasPrefix:kMessagePartialPrefix]) {
        NSLog(@"[WFCUAsr][WS] 收到服务端消息: %@", message);
    }
    if ([message isEqualToString:kMessageEosAck]) {
        [self postToMain:^{
            if ([self.delegate respondsToSelector:@selector(asrWebSocketClientDidReceiveEos:)]) {
                [self.delegate asrWebSocketClientDidReceiveEos:self];
            }
        }];
    } else if ([message hasPrefix:kMessagePartialPrefix]) {
        NSString *text = [self.class trim:[message substringFromIndex:kMessagePartialPrefix.length]];
        if (text.length) {
            [self postToMain:^{
                if ([self.delegate respondsToSelector:@selector(asrWebSocketClient:didReceivePartialResult:)]) {
                    [self.delegate asrWebSocketClient:self didReceivePartialResult:text];
                }
            }];
        }
    } else if ([message hasPrefix:kMessageTrialPrefix]) {
        // 体验版每个连接只识别前 30 秒音频
        NSLog(@"[WFCUAsr][WS] %@", message);
    } else if (![message isEqualToString:kMessagePong]) {
        NSString *text = [self.class parseResultText:message];
        if (text.length) {
            [self postToMain:^{
                if ([self.delegate respondsToSelector:@selector(asrWebSocketClient:didReceiveResult:)]) {
                    [self.delegate asrWebSocketClient:self didReceiveResult:text];
                }
            }];
        }
    }
}

- (void)handleFailure:(NSError *)error {
    @synchronized (self) {
        if (self.disconnected) {
            return;
        }
    }
    NSInteger statusCode = 0;
    if (@available(iOS 13.0, *)) {
        NSURLResponse *response = self.webSocketTask.response;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            statusCode = ((NSHTTPURLResponse *)response).statusCode;
        }
    }
    NSString *message;
    if (statusCode == 401) {
        message = @"语音识别服务鉴权失败";
    } else if (error.code == NSURLErrorCancelled) {
        return;
    } else {
        message = [NSString stringWithFormat:@"连接失败: %@", error.localizedDescription ?: @""];
    }
    NSLog(@"[WFCUAsr][WS] 连接失败 status=%ld error=%@ (domain=%@ code=%ld)",
          (long)statusCode, error.localizedDescription, error.domain, (long)error.code);
    [self notifyError:message];
}

- (void)notifyError:(NSString *)error {
    WFCUAsrWebSocketClient *client = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (client.disconnected) {
            return;
        }
        if ([client.delegate respondsToSelector:@selector(asrWebSocketClient:didFailWithError:)]) {
            [client.delegate asrWebSocketClient:client didFailWithError:error];
        }
    });
}

- (void)postToMain:(dispatch_block_t)action {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.disconnected) {
            return;
        }
        action();
    });
}

/**
 * 去掉识别结果的时间前缀，例如 "[1740992313000+2.35] 你好，世界，" 返回 "你好，世界，"
 */
+ (NSString *)parseResultText:(NSString *)message {
    if ([message hasPrefix:@"["]) {
        NSRange end = [message rangeOfString:@"]"];
        if (end.location != NSNotFound) {
            message = [message substringFromIndex:end.location + 1];
        }
    }
    return [self trim:message];
}

+ (NSString *)trim:(NSString *)text {
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
