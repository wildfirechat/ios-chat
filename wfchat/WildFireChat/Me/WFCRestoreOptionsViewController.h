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

@end

NS_ASSUME_NONNULL_END
