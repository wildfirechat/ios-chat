//
//  WFCRestoreOptionsViewController.h
//  WildFireChat
//
//  Created by Claude on 2025-01-09.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 恢复选项界面
 * 设置恢复选项并执行恢复
 */
@interface WFCRestoreOptionsViewController : UIViewController

@property (nonatomic, strong) NSString *backupFilePath;
@property (nonatomic, strong) NSDictionary *backupInfo;

// 从PC恢复时的属性
@property (nonatomic, assign) BOOL isFromPC;
@property (nonatomic, copy) NSString *serverIP;
@property (nonatomic, assign) NSInteger serverPort;

@end

NS_ASSUME_NONNULL_END
