//
//  ViewController.h
//  WFDemo
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#if WFCU_SUPPORT_VOIP
@class WFZConferenceInfo;
@class WFAVCallSession;
@class WFCCConversation;
@class WFCCConferenceInviteMessageContent;
@interface WFCUConferenceViewController : UIViewController
- (instancetype)initWithSession:(WFAVCallSession *)session conferenceInfo:(WFZConferenceInfo *)conferenceInfo;

- (instancetype)initWithCallId:(NSString *_Nullable)callId
                     audioOnly:(BOOL)audioOnly
                           pin:(NSString *_Nullable)pin
                          host:(NSString *_Nullable)host
                         title:(NSString *_Nullable)title
                          desc:(NSString *_Nullable)desc
                      audience:(BOOL)audience
                       advanced:(BOOL)advance
                        record:(BOOL)record
                        moCall:(BOOL)moCall
                         extra:(NSString *)extra;

- (instancetype)initWithConferenceInfo:(WFZConferenceInfo *)conferenceInfo muteAudio:(BOOL)muteAudio muteVideo:(BOOL)muteVideo;
@property(nonatomic, strong)WFZConferenceInfo *conferenceInfo;
@end
#endif
