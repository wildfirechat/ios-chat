//
//  WFCConversationSelectViewController.h
//  WildFireChat
//
//  Created by Claude on 2025-01-09.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ConversationSelectMode) {
    ConversationSelectModeBackup,    // 备份模式
    ConversationSelectModeRestore    // 恢复模式（预留）
};

/**
 * 会话选择界面
 * 用于选择要备份的会话
 */
@interface WFCConversationSelectViewController : UIViewController

@property (nonatomic, assign) ConversationSelectMode mode;

@end

NS_ASSUME_NONNULL_END
