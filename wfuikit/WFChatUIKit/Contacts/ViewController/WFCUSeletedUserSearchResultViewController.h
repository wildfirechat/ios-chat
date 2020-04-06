//
//  WFCUSeletedUserSearchResultViewController.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/4.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFCUSelectedUserInfo.h"
NS_ASSUME_NONNULL_BEGIN

@interface WFCUSeletedUserSearchResultViewController : UIViewController
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, assign)BOOL needSection;
@property (nonatomic, strong)NSDictionary *sectionDictionary;
@property (nonatomic, strong)NSArray *sectionKeys;
@property (nonatomic, strong)NSMutableArray <WFCUSelectedUserInfo *> *dataSource;
@property (nonatomic, copy) void(^ selectedUser) (WFCUSelectedUserInfo *user);

@end

NS_ASSUME_NONNULL_END
