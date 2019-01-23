//
//  InviteGroupMemberViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/18.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUInviteGroupMemberViewController : UIViewController
@property (nonatomic, strong)NSString *groupId;
@property (nonatomic, copy)void (^inviteMember)(NSString *groupId, NSArray<NSString *> *memberIds);
@end
