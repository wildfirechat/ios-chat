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
@class WFZConferenceInfo;
@class WFCCConferenceInviteMessageContent;
@interface WFCUConferenceViewController : UIViewController

- (instancetype)initWithSession:(WFAVCallSession *)session;
- (instancetype)initWithConferenceInfo:(WFZConferenceInfo *)conferenceInfo muteAudio:(BOOL)muteAudio muteVideo:(BOOL)muteVideo;

@property(nonatomic, strong)WFZConferenceInfo *conferenceInfo;
@end

