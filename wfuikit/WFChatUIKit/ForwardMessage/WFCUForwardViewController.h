//
//  ForwardViewController.h
//  WildFireChat
//
//  Created by heavyrain lee on 2018/9/27.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN
@class WFCCMessage;
@interface WFCUForwardViewController : UIViewController
@property (nonatomic, strong) WFCCMessage *message;
//可以转发一条或者转发多条
@property (nonatomic, strong) NSArray<WFCCMessage *> *messages;
@end

NS_ASSUME_NONNULL_END
