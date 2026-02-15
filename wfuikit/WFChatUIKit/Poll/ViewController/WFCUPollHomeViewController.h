//
//  WFCUPollHomeViewController.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 投票主页 - 包含发起投票和我的投票两个入口
 */
@interface WFCUPollHomeViewController : UIViewController

/// 群ID（投票功能仅在群聊中使用）
@property (nonatomic, strong) NSString *groupId;

@end

NS_ASSUME_NONNULL_END
