//
//  FriendRequestTableViewCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/23.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>


@protocol WFCUFriendRequestTableViewCellDelegate <NSObject>
- (void)onAcceptBtn:(NSString *)targetUserId;
@end


@interface WFCUFriendRequestTableViewCell : UITableViewCell
@property (nonatomic, strong)WFCCFriendRequest *friendRequest;
@property (nonatomic, weak)id<WFCUFriendRequestTableViewCellDelegate> delegate;
@end
