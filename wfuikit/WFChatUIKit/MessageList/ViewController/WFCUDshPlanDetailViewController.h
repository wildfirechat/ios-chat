//
//  WFCUDshPlanDetailViewController.h
//  WFChatUIKit
//
//  DSH plan-review 全屏计划详情页（等宽字体、可滚动，底部固定 批准/拒绝 按钮）。
//

#import <UIKit/UIKit.h>

@class WFCCConversation;

NS_ASSUME_NONNULL_BEGIN

@interface WFCUDshPlanDetailViewController : UIViewController

- (instancetype)initWithConversation:(WFCCConversation *)conversation
                                 qid:(NSString *)qid
                          questionId:(NSString *)questionId
                                plan:(NSString *)plan
                        approveLabel:(NSString *)approveLabel
                         rejectLabel:(NSString *)rejectLabel;

@end

NS_ASSUME_NONNULL_END
