//
//  GroupMuteTableViewController.h
//  WFChatUIKit
//
//  Created by heavyrain lee on 2019/6/26.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface GroupMuteTableViewController : UIViewController
@property (nonatomic, strong)WFCCGroupInfo *groupInfo;
@end

NS_ASSUME_NONNULL_END
