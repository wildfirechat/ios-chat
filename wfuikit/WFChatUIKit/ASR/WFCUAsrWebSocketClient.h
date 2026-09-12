//
//  WFCUAsrWebSocketClient.h
//  WFChatUIKit
//
//  Created by WildFireChat.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCUAsrWebSocketClient;

/**
 * 实时语音识别 WebSocket 客户端回调（主线程回调）
 */
@protocol WFCUAsrWebSocketClientDelegate <NSObject>

@optional
/**
 * 连接成功，连接成功之前缓存的音频已经发送
 */
- (void)asrWebSocketClientDidConnect:(WFCUAsrWebSocketClient *)client;

/**
 * 正在说的这句的中间结果，之后会被新的中间结果或这句的最终结果替换
 */
- (void)asrWebSocketClient:(WFCUAsrWebSocketClient *)client didReceivePartialResult:(NSString *)text;

/**
 * 识别出一句的最终结果
 */
- (void)asrWebSocketClient:(WFCUAsrWebSocketClient *)client didReceiveResult:(NSString *)text;

/**
 * eos 之前的识别结果已全部返回
 */
- (void)asrWebSocketClientDidReceiveEos:(WFCUAsrWebSocketClient *)client;

/**
 * 连接失败或连接被断开
 */
- (void)asrWebSocketClient:(WFCUAsrWebSocketClient *)client didFailWithError:(NSString *)error;

@end

/**
 * 实时语音识别 WebSocket 客户端
 *
 * 连接 asr-api 的 /api/stream，由 asr-api 鉴权后转发给 wf-voice；内网测试时也可以直连 wf-voice。
 * 协议详见 wf-voice 项目的 docs/server-api.md:
 * 1. 连接后发送的第一条文本消息是 clientId；需要边说边出字时，接着发送 partial
 * 2. 二进制消息发送 16kHz、16-bit、单声道 PCM
 * 3. 服务端每识别完一句，推送一条文本消息：[段开始毫秒时间戳+时长秒] 识别文本
 * 4. 发送过 partial 时，说话过程中还会推送正在说的这句的中间结果：[PARTIAL] 识别文本
 * 5. 说话结束时发送 eos，服务端推送完剩余识别结果后回复 [EOS]
 *
 * 每次识别使用一个新实例。连接成功之前就可以发送音频，音频先缓存，连接成功后跟在 clientId 后面发送。
 * 所有回调都在主线程，调用 disconnect 之后不再回调。
 */
@interface WFCUAsrWebSocketClient : NSObject

@property (nonatomic, weak) id<WFCUAsrWebSocketClientDelegate> delegate;

/**
 * 连接语音识别服务
 * @param url           WebSocket 地址，asr-api 或 wf-voice
 * @param clientId      客户端 ID，wf-voice 要求每个连接唯一
 * @param partialResult 是否边说边出字
 * @param authCode      连接 asr-api 时需要的认证码，直连 wf-voice 时传 nil
 */
- (void)connect:(NSString *)url
       clientId:(NSString *)clientId
  partialResult:(BOOL)partialResult
       authCode:(nullable NSString *)authCode;

/**
 * 发送音频数据，可以在任意线程调用。还没连接成功时先缓存，连接成功后发送
 * @param pcmData 16kHz、16-bit、单声道 PCM
 */
- (void)sendAudioData:(NSData *)pcmData;

/**
 * 通知服务端说话结束，服务端返回剩余识别结果后回调 asrWebSocketClientDidReceiveEos:
 */
- (void)sendEos;

/**
 * 断开连接，之后不再回调
 */
- (void)disconnect;

@end

NS_ASSUME_NONNULL_END
