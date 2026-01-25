//
//  WFCBackupTargetViewController.h
//  WildFireChat
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCCConversationInfo;

/**
 * 备份目标选择界面
 * 选择备份到本地或电脑端
 */
@interface WFCBackupTargetViewController : UIViewController

@property (nonatomic, strong) NSArray<WFCCConversationInfo *> *conversations;
@property (nonatomic, assign) BOOL includeMedia;

@end

NS_ASSUME_NONNULL_END
