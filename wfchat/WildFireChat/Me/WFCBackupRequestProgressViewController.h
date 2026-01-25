//
//  WFCBackupRequestProgressViewController.h
//  WildFireChat
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 备份请求进度窗口
 * 等待PC端响应备份请求
 */
@interface WFCBackupRequestProgressViewController : UIViewController

@property (nonatomic, strong) NSArray *conversations;
@property (nonatomic, assign) BOOL includeMedia;

/**
 * 开始发送备份请求并显示进度
 */
- (void)startBackupRequest;

@end

NS_ASSUME_NONNULL_END
