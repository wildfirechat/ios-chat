//
//  PCSessionViewController.h
//  WildFireChat
//
//  Created by heavyrain lee on 2019/3/2.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface PCSessionViewController : UIViewController
@property (nonatomic, strong)WFCCPCOnlineInfo *pcClientInfo;
@end

NS_ASSUME_NONNULL_END
