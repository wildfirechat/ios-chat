//
//  WFCUCompositeMessageViewController.h
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WFCCMessage;

NS_ASSUME_NONNULL_BEGIN

@interface WFCUCompositeMessageViewController : UIViewController
@property (nonatomic, strong)WFCCMessage *message;
@end

NS_ASSUME_NONNULL_END
