//
//  WFCCallKitManager.h
//  WildFireChat
//
//  Created by Rain on 2022/4/25.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#if USE_CALL_KIT
#import <Foundation/Foundation.h>
#import <WFChatClient/WFCChatClient.h>
#import <WFAVEngineKit/WFAVEngineKit.h>
#import <WebRTC/WebRTC.h>
#import <CallKit/CallKit.h>
#import <PushKit/PushKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCCallKitManager : NSObject <CXProviderDelegate>
- (void)didReceiveCall:(WFAVCallSession *)session;
- (void)didCallEnded:(WFAVCallEndReason)reason duration:(int)callDuration;
- (void)didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
                                  forType:(NSString *)type;
@end

NS_ASSUME_NONNULL_END
#endif
