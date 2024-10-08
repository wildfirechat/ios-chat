//
//  WFCUProfileTableViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/22.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

@class WFCCUserInfo;
@class WFCCConversation;
@interface WFCUProfileTableViewController : UIViewController
@property (nonatomic, strong)NSString *userId;
@property (nonatomic, strong)WFCCConversation *fromConversation;

@property (nonatomic, assign)WFCCFriendSourceType sourceType;
@property (nonatomic, strong)NSString *sourceTargetId;
@end
