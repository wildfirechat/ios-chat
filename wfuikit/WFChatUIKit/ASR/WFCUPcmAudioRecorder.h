//
//  WFCUPcmAudioRecorder.h
//  WFChatUIKit
//
//  Created by WildFireChat.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * PCM 音频录制器，用于实时语音识别
 * 采集 16kHz、16-bit、单声道 PCM 音频数据，每 30ms（960 字节）回调一次
 */
@interface WFCUPcmAudioRecorder : NSObject

/**
 * 音频数据回调，长度为 960 字节（30ms 音频），在内部串行队列回调
 */
@property (nonatomic, copy, nullable) void (^dataCallback)(NSData *pcmData);

/**
 * 错误回调
 */
@property (nonatomic, copy, nullable) void (^errorCallback)(NSString *message);

/**
 * 开始录音
 * @return 是否成功开始录音
 */
- (BOOL)startRecording;

/**
 * 停止录音
 */
- (void)stopRecording;

/**
 * 是否正在录音
 */
@property (nonatomic, readonly, getter=isRecording) BOOL recording;

/**
 * 把 16kHz、16-bit、单声道 PCM 写成 8kHz 单声道的 WAV 文件（AMR 编码要求 8kHz）
 * @param path 目标文件路径
 * @param pcmData 16kHz、16-bit、单声道 PCM
 * @return 是否写入成功
 */
+ (BOOL)writeWavFileAtPath:(NSString *)path fromPcm16kMono:(NSData *)pcmData;

@end

NS_ASSUME_NONNULL_END
