//
//  WFCUJoinGroupRequestTableViewCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/23.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

@protocol WFCUJoinGroupRequestTableViewCellDelegate <NSObject>
- (void)onAcceptBtn:(NSString *)targetUserId inviterId:(NSString *)inviterId;
- (void)onViewUserInfo:(NSString *)userId;
@end

@interface WFCUJoinGroupRequestTableViewCell : UITableViewCell
@property (nonatomic, strong)WFCCJoinGroupRequest *joinGroupRequest;
@property (nonatomic, weak)id<WFCUJoinGroupRequestTableViewCellDelegate> delegate;
@end
