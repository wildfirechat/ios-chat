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

- (instancetype)initWithConferenceInfo:(WFZConferenceInfo *)conferenceInfo muteAudio:(BOOL)muteAudio muteVideo:(BOOL)muteVideo;
@end
#endif
