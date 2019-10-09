//
//  WFCUBlackListViewController.m
//  WFChatUIKit
//
//  Created by Heavyrain.Lee on 2019/7/31.
//  Copyright © 2019 Wildfire Chat. All rights reserved.
//

#import "WFCUBlackListViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDWebImage.h"

@interface WFCUBlackListViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong)  UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArr;
@end

@implementation WFCUBlackListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = WFCString(@"Blacklist");
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.dataArr = [[[WFCCIMService sharedWFCIMService] getBlackList:YES] mutableCopy];
    [self.tableView reloadData];
    [self.view addSubview:self.tableView];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 48;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *userId = [self.dataArr objectAtIndex:indexPath.row];
        __weak typeof(self) ws = self;
        [[WFCCIMService sharedWFCIMService] setBlackList:userId isBlackListed:NO success:^{
            [ws.dataArr removeObject:userId];
            [ws.tableView reloadData];
        } error:^(int error_code) {
            
        }];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return WFCString(@"Delete");
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[self.dataArr objectAtIndex:indexPath.row] refresh:NO];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    cell.textLabel.text = userInfo.displayName;
    return cell;
}

@end
