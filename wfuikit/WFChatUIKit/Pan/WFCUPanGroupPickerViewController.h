//
//  WFCUPanGroupPickerViewController.h
//  WFChatUIKit
//
//  在线文档「按群分享」的群多选界面（JS 桥 chooseGroup 使用）。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCCGroupInfo;

@interface WFCUPanGroupPickerViewController : UIViewController

/// 确定后回调选中的群（至少一个）；取消不回调。
@property (nonatomic, copy, nullable) void (^selectResult)(NSArray<WFCCGroupInfo *> *groups);

@end

NS_ASSUME_NONNULL_END
