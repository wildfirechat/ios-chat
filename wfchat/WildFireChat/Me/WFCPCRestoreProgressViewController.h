//
//  WFCPCRestoreProgressViewController.h
//  WildFireChat
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * PC端恢复进度界面
 * 从PC端下载备份并逐步恢复
 */
@interface WFCPCRestoreProgressViewController : UIViewController

@property (nonatomic, strong) NSString *backupPath;
@property (nonatomic, strong) NSString *serverIP;
@property (nonatomic, assign) NSInteger serverPort;
@property (nonatomic, assign) BOOL overwriteExisting;

@end

NS_ASSUME_NONNULL_END
