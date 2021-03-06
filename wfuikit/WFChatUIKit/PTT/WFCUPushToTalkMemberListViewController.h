//
//  WFCUPushToTalkMemberListViewController.h
//  WFChatUIKit
//
//  Created by dali on 2021/2/18.
//  Copyright © 2021 Wildfire Chat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class WFAVCallSession;
@interface WFCUPushToTalkMemberListViewController : UIViewController
@property (nonatomic, strong) WFAVCallSession *currentSession;
@end

NS_ASSUME_NONNULL_END
