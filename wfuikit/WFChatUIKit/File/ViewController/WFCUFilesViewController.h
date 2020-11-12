//
//  WFCUFilesViewController.h
//  WFChatUIKit
//
//  Created by dali on 2020/8/2.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WFCCConversation;
NS_ASSUME_NONNULL_BEGIN

@interface WFCUFilesViewController : UIViewController
@property(nonatomic, strong)WFCCConversation *conversation;
@end

NS_ASSUME_NONNULL_END
