//
//  GroupManageTableViewController.h
//  WFChatUIKit
//
//  Created by heavyrain lee on 2019/6/26.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface GroupManageTableViewController : UIViewController
@property (nonatomic, strong)WFCCGroupInfo *groupInfo;
// 入口会话的 line（普通群=0，AI 群=2）；群通知发到该 line
@property (nonatomic, assign)int line;
@end

NS_ASSUME_NONNULL_END
