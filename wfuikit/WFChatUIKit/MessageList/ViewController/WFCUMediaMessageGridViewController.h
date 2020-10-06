//
//  WFCUMediaMessageGridViewController.h
//  WFChatUIKit
//
//  Created by dali on 2020/7/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class WFCCConversation;

@interface WFCUMediaMessageGridViewController : UIViewController
@property(nonatomic, strong)WFCCConversation *conversation;
@end

NS_ASSUME_NONNULL_END
