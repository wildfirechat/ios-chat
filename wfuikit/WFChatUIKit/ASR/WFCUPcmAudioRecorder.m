//
//  WFCUPcmAudioRecorder.m
//  WFChatUIKit
//
//  Created by WildFireChat.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "WFCUPcmAudioRecorder.h"
#import <AVFoundation/AVFoundation.h>

// 音频参数配置（与 wf-voice 要求一致）
static const double kSampleRate = 16000;
// 每次读取的字节数（对应 30ms 音频）
static const NSInteger kChunkSize = 960;

@interface WFCUPcmAudioRecorder ()
@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, strong) AVAudioConverter *converter;
@property (nonatomic, strong) NSMutableData *pendingData;
@property (nonatomic, strong) dispatch_queue_t audioQueue;
@property (nonatomic, assign) BOOL recording;
@end

@implementation WFCUPcmAudioRecorder

- (instancetype)init {
    self = [super init];
    if (self) {
        _audioQueue = dispatch_queue_create("com.wildfirechat.pcm.recorder", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (BOOL)startRecording {
    if (self.recording) {
        return YES;
    }

    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    [session setCategory:AVAudioSessionCategoryRecord mode:AVAudioSessionModeMeasurement options:0 error:&error];
    if (error) {
        [self notifyError:[NSString stringWithFormat:@"设置音频会话失败: %@", error.localizedDescription]];
        return NO;
    }
    [session setActive:YES error:&error];
    if (error) {
        [self notifyError:[NSString stringWithFormat:@"激活音频会话失败: %@", error.localizedDescription]];
        return NO;
    }

    AVAudioEngine *engine = [[AVAudioEngine alloc] init];
    AVAudioInputNode *inputNode = engine.inputNode;
    AVAudioFormat *inputFormat = [inputNode outputFormatForBus:0];
    if (inputFormat.sampleRate <= 0 || inputFormat.channelCount == 0) {
        [self notifyError:@"不支持此音频配置"];
        [session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
        return NO;
    }
    AVAudioFormat *outputFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                                   sampleRate:kSampleRate
                                                                     channels:1
                                                                  interleaved:YES];
    AVAudioConverter *converter = [[AVAudioConverter alloc] initFromFormat:inputFormat toFormat:outputFormat];
    if (!converter) {
        [self notifyError:@"不支持此音频配置"];
        [session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
        return NO;
    }

    self.engine = engine;
    self.converter = converter;
    self.pendingData = [NSMutableData data];
    self.recording = YES;

    __weak typeof(self) weakSelf = self;
    [inputNode installTapOnBus:0 bufferSize:(AVAudioFrameCount)1024 format:inputFormat block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.recording) {
            return;
        }
        NSData *pcm = [self convertBuffer:buffer];
        if (pcm.length == 0) {
            return;
        }
        dispatch_async(self.audioQueue, ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self || !self.recording) {
                return;
            }
            [self emitData:pcm];
        });
    }];

    [engine prepare];
    NSError *startError = nil;
    if (![engine startAndReturnError:&startError]) {
        [inputNode removeTapOnBus:0];
        self.engine = nil;
        self.converter = nil;
        self.pendingData = nil;
        self.recording = NO;
        [session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
        [self notifyError:[NSString stringWithFormat:@"启动录音失败: %@", startError.localizedDescription ?: @""]];
        return NO;
    }

    NSLog(@"[WFCUAsr] 录音已开始: 16000Hz, 16-bit, 单声道");
    return YES;
}

- (void)stopRecording {
    if (!self.recording) {
        return;
    }
    self.recording = NO;
    if (self.engine) {
        [self.engine.inputNode removeTapOnBus:0];
        [self.engine stop];
        self.engine = nil;
    }
    self.converter = nil;
    self.pendingData = nil;
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    NSLog(@"[WFCUAsr] 录音已停止");
}

#pragma mark - 私有方法

- (BOOL)isRecording {
    return _recording;
}

+ (BOOL)writeWavFileAtPath:(NSString *)path fromPcm16kMono:(NSData *)pcmData {
    if (!path.length || pcmData.length < 2) {
        return NO;
    }
    // 16kHz 降采样到 8kHz：每两个采样取一个
    NSInteger sampleCount = pcmData.length / sizeof(int16_t);
    NSInteger outputCount = sampleCount / 2;
    NSMutableData *pcm8k = [NSMutableData dataWithLength:outputCount * sizeof(int16_t)];
    const int16_t *src = (const int16_t *)pcmData.bytes;
    int16_t *dst = (int16_t *)pcm8k.mutableBytes;
    for (NSInteger i = 0; i < outputCount; i++) {
        dst[i] = src[i * 2];
    }

    const uint32_t sampleRate = 8000;
    const uint16_t channels = 1;
    const uint16_t bitsPerSample = 16;
    uint32_t dataSize = (uint32_t)pcm8k.length;
    uint32_t byteRate = sampleRate * channels * bitsPerSample / 8;
    uint16_t blockAlign = channels * bitsPerSample / 8;
    uint32_t chunkSize = 36 + dataSize;

    NSMutableData *wav = [NSMutableData dataWithCapacity:44 + dataSize];
    void (^append)(const void *, NSInteger) = ^(const void *bytes, NSInteger length) {
        [wav appendBytes:bytes length:length];
    };
    append("RIFF", 4);
    append(&chunkSize, 4);
    append("WAVE", 4);
    append("fmt ", 4);
    uint32_t subChunk1Size = 16;
    append(&subChunk1Size, 4);
    uint16_t audioFormat = 1;
    append(&audioFormat, 2);
    append(&channels, 2);
    append(&sampleRate, 4);
    append(&byteRate, 4);
    append(&blockAlign, 2);
    append(&bitsPerSample, 2);
    append("data", 4);
    append(&dataSize, 4);
    [wav appendData:pcm8k];

    return [wav writeToFile:path atomically:YES];
}

/**
 * 把硬件的 Float32 音频转换成 16kHz、16-bit、单声道 PCM
 */
- (NSData *)convertBuffer:(AVAudioPCMBuffer *)inputBuffer {
    AVAudioConverter *converter = self.converter;
    if (!converter || inputBuffer.frameLength == 0) {
        return [NSData data];
    }
    double ratio = converter.outputFormat.sampleRate / converter.inputFormat.sampleRate;
    AVAudioFrameCount capacity = (AVAudioFrameCount)ceil(inputBuffer.frameLength * ratio) + 64;
    AVAudioPCMBuffer *outputBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:converter.outputFormat frameCapacity:capacity];
    __block BOOL provided = NO;
    NSError *error = nil;
    AVAudioConverterOutputStatus status = [converter convertToBuffer:outputBuffer
                                                              error:&error
                                                 withInputFromBlock:^AVAudioBuffer * _Nullable(AVAudioPacketCount inNumberOfPackets, AVAudioConverterInputStatus *outStatus) {
        if (provided) {
            *outStatus = AVAudioConverterInputStatus_NoDataNow;
            return nil;
        }
        provided = YES;
        *outStatus = AVAudioConverterInputStatus_HaveData;
        return inputBuffer;
    }];
    if (error) {
        NSLog(@"[WFCUAsr] 音频转换失败: %@", error.localizedDescription);
        return [NSData data];
    }
    if ((status == AVAudioConverterOutputStatus_HaveData || status == AVAudioConverterOutputStatus_InputRanDry) && outputBuffer.frameLength > 0) {
        return [NSData dataWithBytes:outputBuffer.int16ChannelData[0] length:outputBuffer.frameLength * sizeof(int16_t)];
    }
    return [NSData data];
}

/**
 * 按 960 字节（30ms）一帧回调，不足一帧的先缓存
 */
- (void)emitData:(NSData *)data {
    [self.pendingData appendData:data];
    while (self.pendingData.length >= kChunkSize) {
        NSData *frame = [self.pendingData subdataWithRange:NSMakeRange(0, kChunkSize)];
        [self.pendingData replaceBytesInRange:NSMakeRange(0, kChunkSize) withBytes:NULL length:0];
        if (self.dataCallback) {
            self.dataCallback(frame);
        }
    }
}

- (void)notifyError:(NSString *)message {
    void (^callback)(NSString *) = self.errorCallback;
    if (callback) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(message);
        });
    }
}

@end
