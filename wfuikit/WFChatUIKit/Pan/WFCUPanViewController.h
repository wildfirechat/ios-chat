//
//  WFCUPanViewController.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/24.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFCUPanSpace.h"
#import "WFCUPanFile.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WFCUPanViewMode) {
    WFCUPanViewModeAll,           // 显示所有空间（发现入口）
    WFCUPanViewModeMySpaces,      // 只显示我的空间
    WFCUPanViewModeUserPublic     // 显示指定用户的公共空间
};

@interface WFCUPanViewController : UIViewController

@property (nonatomic, assign) WFCUPanViewMode viewMode;
@property (nonatomic, copy) NSString *targetUserId;  // 当 viewMode 为 WFCUPanViewModeUserPublic 时使用
@property (nonatomic, copy) NSString *targetUserName;

/// 移动模式属性（用于从文件列表返回空间列表时保持状态）
@property (nonatomic, assign) BOOL isMoveMode;
@property (nonatomic, strong, nullable) WFCUPanFile *fileToMove;
@property (nonatomic, strong, nullable) WFCUPanSpace *sourceSpace;
@property (nonatomic, assign) NSInteger sourceParentId;

/// 复制模式属性
@property (nonatomic, assign) BOOL isCopyMode;
@property (nonatomic, strong, nullable) WFCUPanFile *fileToCopy;
@property (nonatomic, strong, nullable) WFCUPanSpace *sourceCopySpace;
@property (nonatomic, assign) NSInteger sourceCopyParentId;

@end

NS_ASSUME_NONNULL_END
