//
//  WFCUAsrManager.h
//  WFChatUIKit
//
//  Created by WildFireChat.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCUAsrManager;

/**
 * 实时语音输入识别回调，均在主线程回调
 */
@protocol WFCUAsrManagerDelegate <NSObject>

/**
 * 识别文本有更新：识别出新的一句，或者正在说的这句有了新的中间结果
 * @param text 本次识别到目前为止的全部文本
 */
- (void)asrManager:(WFCUAsrManager *)manager onPartialResult:(NSString *)text;

/**
 * 识别完成，之后不再回调
 * @param text 本次识别的全部文本，可能为空
 */
- (void)asrManager:(WFCUAsrManager *)manager onFinalResult:(NSString *)text;

/**
 * 出错，之后不再回调
 */
- (void)asrManager:(WFCUAsrManager *)manager onError:(NSString *)message;

/**
 * 检测到热词，之后不再回调
 * @param hotword 检测到的热词（如 "Over"）
 * @param text 当前识别的文本（不包含热词）
 */
- (void)asrManager:(WFCUAsrManager *)manager onHotwordDetected:(NSString *)hotword text:(NSString *)text;

@end

/**
 * 实时语音输入管理器
 *
 * 录音并实时推送到 wf-voice 识别（经过 asr-api 转发，内网测试时也可以直连）。wf-voice 每识别完一句返回这句的最终结果；
 * 开启 enableAsrPartialResult 后，说话过程中还会返回正在说的这句的中间结果。
 * 服务地址见 WFCUConfigManager.asrStreamServiceUrl。
 */
@interface WFCUAsrManager : NSObject

@property (nonatomic, weak, nullable) id<WFCUAsrManagerDelegate> delegate;

/**
 * 是否启用 "Over" 热词，默认为 NO。启用后识别结果以 "Over"/"欧弗"/"结束" 结尾时回调 onHotwordDetected
 */
@property (nonatomic, assign) BOOL hotwordOverEnabled;

/**
 * 开始语音识别，调用前需要已获得录音权限。会立即开始录音，连接识别服务期间录到的音频先缓存，连接成功后再发送
 */
- (void)startRecognition;

/**
 * 开始语音识别，由调用方通过 feedAudioData: 提供音频，提供完后调用 stopRecognition。
 * 连接识别服务期间提供的音频会先缓存，连接成功后再发送
 */
- (void)startRecognitionWithAudioFeed;

/**
 * 提供音频数据，只在 startRecognitionWithAudioFeed 之后有效，需要在主线程调用
 * @param pcmData 16kHz、16-bit、单声道 PCM
 */
- (void)feedAudioData:(NSData *)pcmData;

/**
 * 停止录音或停止提供音频，剩余识别结果返回后回调 onFinalResult
 */
- (void)stopRecognition;

/**
 * 取消语音识别，丢弃还没返回的识别结果，之后不再回调
 */
- (void)cancelRecognition;

/**
 * 是否正在识别，包括停止录音后等待剩余识别结果的阶段
 */
- (BOOL)isRecognizing;

@end

NS_ASSUME_NONNULL_END
