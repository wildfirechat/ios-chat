//
//  WFCUPushToTalkViewController.h
//  WFChatUIKit
//
//  Created by dali on 2021/2/18.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WFAVCallSession;
@class WFCCConversation;
@class WFCCPTTInviteMessageContent;

@interface WFCUPushToTalkViewController : UIViewController
- (instancetype)initWithSession:(WFAVCallSession *)session;
- (instancetype)initWithInvite:(WFCCPTTInviteMessageContent *)invite;

- (instancetype)initWithCallId:(NSString *_Nullable)callId
                     audioOnly:(BOOL)audioOnly
                           pin:(NSString *_Nullable)pin
                          host:(NSString *_Nullable)host
                         title:(NSString *_Nullable)title
                          desc:(NSString *_Nullable)desc
                      audience:(BOOL)audience
                        moCall:(BOOL)moCall;

@end
