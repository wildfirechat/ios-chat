//
//  WFPttViewController.h
//  PttUIKit
//
//  Created by Hao Jia on 2021/10/14.
//

#ifdef WFC_PTT
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class WFCCConversation;
@interface WFPttViewController : UIViewController
@property(nonatomic, strong)WFCCConversation *conversation;
@end

NS_ASSUME_NONNULL_END
#endif //WFC_PTT
