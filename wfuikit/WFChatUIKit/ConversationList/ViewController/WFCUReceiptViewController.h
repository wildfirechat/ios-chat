//
//  WFCUReceiptViewController.h
//  WFChatUIKit
//
//  Created by heavyrain2012 on 2020/5/20.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUReceiptViewController : UIViewController
@property(nonatomic, strong)WFCCMessage *message;
@end

NS_ASSUME_NONNULL_END
