//
//  WFCBackupOptionsViewController.h
//  WildFireChat
//
//  Created by Claude on 2025-01-09.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCCConversationInfo;

/**
 * 备份选项界面
 * 选择备份模式和设置密码
 */
@interface WFCBackupOptionsViewController : UIViewController

@property (nonatomic, strong) NSArray<WFCCConversationInfo *> *conversations;

@end

NS_ASSUME_NONNULL_END
