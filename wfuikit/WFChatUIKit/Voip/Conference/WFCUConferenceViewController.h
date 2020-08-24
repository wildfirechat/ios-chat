//
//  ViewController.h
//  WFDemo
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WFAVCallSession;
@class WFCCConversation;
@class WFCCConferenceInviteMessageContent;
@interface WFCUConferenceViewController : UIViewController
- (instancetype)initWithSession:(WFAVCallSession *)session;
- (instancetype)initWithInvite:(WFCCConferenceInviteMessageContent *)invite;

- (instancetype)initWithCallId:(NSString *_Nonnull)callId
                     audioOnly:(BOOL)audioOnly
                           pin:(NSString *_Nonnull)pin
                          host:(NSString *_Nullable)host
                         title:(NSString *_Nullable)title
                          desc:(NSString *_Nullable)desc
                      audience:(BOOL)audience
                        moCall:(BOOL)moCall;
@end

