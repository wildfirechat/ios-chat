//
//  WFCUPanFileListViewController.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/24.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFCUPanSpace.h"
#import "WFCUPanFile.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFCUPanFileListViewController : UIViewController
@property (nonatomic, strong) WFCUPanSpace *space;
@property (nonatomic, assign) NSInteger parentId;

/// 移动模式属性
@property (nonatomic, assign) BOOL isMoveMode;
@property (nonatomic, strong) WFCUPanFile *fileToMove;
@property (nonatomic, strong) WFCUPanSpace *sourceSpace;
@property (nonatomic, assign) NSInteger sourceParentId;

/// 复制模式属性
@property (nonatomic, assign) BOOL isCopyMode;
@property (nonatomic, strong) WFCUPanFile *fileToCopy;
@property (nonatomic, strong) WFCUPanSpace *sourceCopySpace;
@property (nonatomic, assign) NSInteger sourceCopyParentId;

@end

NS_ASSUME_NONNULL_END
