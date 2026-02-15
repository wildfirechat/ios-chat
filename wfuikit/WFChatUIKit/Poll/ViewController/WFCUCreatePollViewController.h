//
//  WFCUCreatePollViewController.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 创建投票页面
 */
@interface WFCUCreatePollViewController : UIViewController

/// 群ID（必填）
@property (nonatomic, strong) NSString *groupId;

@end

NS_ASSUME_NONNULL_END
