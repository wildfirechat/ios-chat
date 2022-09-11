//
//  WFCUConferenceMemberManagerViewController.h
//  WFChatUIKit
//
//  Created by Tom Lee on 2021/2/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#if WFCU_SUPPORT_VOIP
NS_ASSUME_NONNULL_BEGIN
@class WFZConferenceInfo;
@interface WFCUConferenceMemberManagerViewController : UIViewController
@property(nonatomic, strong)WFZConferenceInfo *conferenceInfo;
@end

NS_ASSUME_NONNULL_END
#endif
