//
//  PCLoginConfirmViewController.h
//  WildFireChat
//
//  Created by heavyrain lee on 2019/3/2.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface PCLoginConfirmViewController : UIViewController
@property (nonatomic, strong)NSString *sessionId;
@property (nonatomic, assign)WFCCPlatformType platform;
@end

NS_ASSUME_NONNULL_END
