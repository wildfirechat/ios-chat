//
//  WFCUPollDetailViewController.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCCMessage;
/**
 * 投票详情页面
 */
@interface WFCUPollDetailViewController : UIViewController

/// 从消息进入时使用
@property (nonatomic, strong, nullable) WFCCMessage *message;

/// 直接通过ID进入（用于我的投票列表等场景）
@property (nonatomic, assign) long long pollId;
@property (nonatomic, strong, nullable) NSString *groupId;

@end

NS_ASSUME_NONNULL_END
