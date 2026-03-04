//
//  WFCUPanFilePickerViewController.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/25.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFCUPanFile.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^WFCUPanFilePickerCompletionBlock)(NSArray<WFCUPanFile *> *selectedFiles);
typedef void(^WFCUPanFilePickerCancelBlock)(void);

@interface WFCUPanFilePickerViewController : UIViewController

@property (nonatomic, copy) WFCUPanFilePickerCompletionBlock completionBlock;
@property (nonatomic, copy) WFCUPanFilePickerCancelBlock cancelBlock;

@end

NS_ASSUME_NONNULL_END
