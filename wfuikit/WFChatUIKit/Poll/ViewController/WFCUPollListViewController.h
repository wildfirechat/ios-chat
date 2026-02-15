//
//  WFCUPollListViewController.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 我的投票列表页面
 */
@interface WFCUPollListViewController : UIViewController

/// 群ID（可选，如果传入则只显示该群组的投票）
@property (nonatomic, strong, nullable) NSString *groupId;

@end

NS_ASSUME_NONNULL_END
