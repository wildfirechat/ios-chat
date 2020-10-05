//
//  WFCUUserMessageListViewController.h
//  WFChatUIKit
//
//  Created by dali on 2020/8/19.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCCConversation;
@interface WFCUUserMessageListViewController : UIViewController
@property(nonatomic, strong)NSString *userId;
@property(nonatomic, strong)WFCCConversation *conversation;
@end

NS_ASSUME_NONNULL_END
