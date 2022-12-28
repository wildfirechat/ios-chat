//
//  WFCUOrganizationViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/7.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface WFCUOrganizationViewController : UIViewController
@property (nonatomic, strong)NSArray<NSNumber *> *organizationIds;
@property (nonatomic, assign)BOOL selectContact;
@property (nonatomic, assign)BOOL multiSelect;
@property (nonatomic, assign)int maxSelectCount;
@property (nonatomic, assign)BOOL isPushed;

@property (nonatomic, strong)NSArray *disableUsers;
@property (nonatomic, assign)BOOL disableUsersSelected;
@property (nonatomic, strong)void (^selectResult)(NSArray<NSString *> *contacts);
@property (nonatomic, strong)void (^cancelSelect)(void);
@end
