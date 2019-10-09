//
//  ContactListViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/7.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface WFCUContactListViewController : UIViewController
@property (nonatomic, assign)BOOL selectContact;
@property (nonatomic, assign)BOOL multiSelect;
@property (nonatomic, assign)BOOL withoutCheckBox;
@property (nonatomic, assign)BOOL isPushed;
@property (nonatomic, strong)void (^selectResult)(NSArray<NSString *> *contacts);
@property (nonatomic, strong)void (^cancelSelect)(void);
@property (nonatomic, strong)NSArray *disableUsers;
@property (nonatomic, assign)BOOL disableUsersSelected;
@property (nonatomic, strong)NSArray *candidateUsers;
@property (nonatomic, assign)BOOL showCreateChannel;
@property (nonatomic, strong)void (^createChannel)(void);
@property (nonatomic, assign)BOOL showMentionAll;
@property (nonatomic, strong)void (^mentionAll)(void);
@end
