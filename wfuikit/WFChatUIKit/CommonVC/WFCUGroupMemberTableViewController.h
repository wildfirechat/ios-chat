//
//  GroupMemberTableViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/18.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUGroupMemberTableViewController : UITableViewController
@property (nonatomic, strong)NSString *groupId;
@property (nonatomic, assign)BOOL selectable;
@property (nonatomic, assign)BOOL multiSelect;
@property (nonatomic, copy)void (^selectResult)(NSString *groupId, NSArray<NSString *> *memberIds);
@end
