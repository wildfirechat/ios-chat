//
//  WFCUReadViewController.m
//  WFChatUIKit
//
//  Created by Rain on 2023/3/25.
//  Copyright © 2023 Tom Lee. All rights reserved.
//

#import "WFCUReadViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "WFCUImage.h"

@interface WFCUReadViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@end

@implementation WFCUReadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }    
    [self.view addSubview:self.tableView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (WFCCUserInfo *userInfo in userInfoList) {
        if([self.userIds containsObject:userInfo.userId]) {
            [self.tableView reloadData];
            break;
        }
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.userIds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.userIds[indexPath.row] inGroup:self.groupId refresh:NO];
    
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage:[WFCUImage imageNamed:@"PersonalChat"]];
    NSString *name = userInfo.friendAlias;
    if(!name.length) {
        name = userInfo.groupAlias;
        if(!name.length) {
            name = userInfo.displayName;
            if(!name.length) {
                name = self.userIds[indexPath.row];
            }
        }
    }
    cell.textLabel.text = userInfo.displayName;
    
    return cell;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
