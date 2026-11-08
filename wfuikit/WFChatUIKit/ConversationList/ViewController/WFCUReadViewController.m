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
#import "WFCUGeneralImageTextTableViewCell.h"
#import "WFCUConfigManager.h"

@interface WFCUReadViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@end

#define CELL_HEIGHT 56
@implementation WFCUReadViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    //页面宽高不再恒等于屏幕：iPad 右栏比屏幕窄，栏宽还会随旋转/分屏/台前调度变。
    //手写的 frame 是按 viewDidLoad 那一刻定死的，补一个 autoresizing 让它跟着父视图走。
    //iPhone 锁竖屏、页面恒等于整屏，这一行永远不会改变任何取值。
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }    
    [self.view addSubview:self.tableView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDomainInfoUpdated:) name:kDomainInfoUpdated object:nil];
}

- (void)onDomainInfoUpdated:(NSNotification *)notification {
    [self.tableView reloadData];
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
    WFCUGeneralImageTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(!cell) {
        cell = [[WFCUGeneralImageTextTableViewCell alloc] initWithReuseIdentifier:@"cell" cellHeight:CELL_HEIGHT];
    }
    NSString *targetId = self.userIds[indexPath.row];
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:targetId inGroup:self.groupId refresh:NO];
    
    [cell.portraitIV sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage:[WFCUImage imageNamed:@"PersonalChat"]];
    NSString *name = userInfo.friendAlias;
    if(!name.length) {
        name = userInfo.groupAlias;
        if(!name.length) {
            name = userInfo.displayName;
            if(!name.length) {
                name = [WFCCUtilities getTargetWithoutDomain:targetId];
            }
        }
    }

    if([WFCCUtilities isExternalTarget:targetId]) {
        NSString *domainId = [WFCCUtilities getExternalDomain:targetId];
        cell.titleLable.attributedText = [WFCCUtilities getExternal:domainId
                                                           withName:name
                                                          withColor:[WFCUConfigManager globalManager].externalNameColor
                                                           withSize:10];
    } else {
        cell.titleLable.attributedText = nil;
        cell.titleLable.text = name;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
