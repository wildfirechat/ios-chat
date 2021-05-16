//
//  WFCUVerifyRequestViewController.h
//  WFChatUIKit
//
//  Created by WF Chat on 2018/11/4.
//  Copyright © 2018 WF Chat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFCUEnum.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFCUVerifyRequestViewController : UIViewController
@property (nonatomic, strong)NSString *userId;

@property (nonatomic, assign)WFCUFriendSourceType sourceType;
@property (nonatomic, strong)NSString *sourceTargetId;
@end

NS_ASSUME_NONNULL_END
