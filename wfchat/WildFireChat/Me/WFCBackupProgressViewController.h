//
//  WFCBackupProgressViewController.h
//  WildFireChat
//
//  Created by Claude on 2025-01-09.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCCConversationInfo;

/**
 * 备份/恢复进度显示界面
 */
@interface WFCBackupProgressViewController : UIViewController

// 备份模式
@property (nonatomic, strong) NSArray<WFCCConversationInfo *> *conversations;
@property (nonatomic, assign) BOOL includeMedia;

// 恢复模式
@property (nonatomic, strong) NSString *backupFilePath;
@property (nonatomic, strong) NSDictionary *backupInfo;
@property (nonatomic, assign) BOOL overwriteExisting;
@property (nonatomic, assign) BOOL isRestoreMode;
@property (nonatomic, strong, nullable) NSString *backupPassword; // 加密备份的密码

@end

NS_ASSUME_NONNULL_END
