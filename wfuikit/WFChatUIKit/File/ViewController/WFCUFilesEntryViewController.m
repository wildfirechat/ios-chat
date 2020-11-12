//
//  WFCUFilesEntryViewController.m
//  WFChatUIKit
//
//  Created by dali on 2020/11/12.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUFilesEntryViewController.h"
#import "WFCUFilesViewController.h"
#import "WFCUConversationFilesViewController.h"
#import "WFCUContactListViewController.h"

@interface WFCUFilesEntryViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@end

@implementation WFCUFilesEntryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"文件";
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
    //所有，我发的，群文件，用户文件
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    if (indexPath.row == 0) {
        cell.textLabel.text = @"所有文件";
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"我的文件";
    } else if (indexPath.row == 2) {
        cell.textLabel.text = @"会话文件";
    } else if (indexPath.row == 3) {
        cell.textLabel.text = @"用户文件";
    }
    return cell;
}
#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        WFCUFilesViewController *vc = [[WFCUFilesViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    } else if(indexPath.row == 1) {
        WFCUFilesViewController *vc = [[WFCUFilesViewController alloc] init];
        vc.myFiles = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else if(indexPath.row == 2) {
        WFCUConversationFilesViewController *vc = [[WFCUConversationFilesViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    } else if(indexPath.row == 3) {
        WFCUContactListViewController *pvc = [[WFCUContactListViewController alloc] init];
        pvc.selectContact = YES;
        pvc.multiSelect = NO;
        pvc.withoutCheckBox = YES;
        
        
        __weak typeof(self)ws = self;
        pvc.selectResult = ^(NSArray<NSString *> *contacts) {
            if (contacts.count == 1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    WFCUFilesViewController *vc = [[WFCUFilesViewController alloc] init];
                    vc.userFiles = YES;
                    vc.userId = contacts[0];
                    [ws.navigationController pushViewController:vc animated:YES];
                });
            } else {
                
            }
        };
        
        pvc.disableUsersSelected = YES;
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
        [self.navigationController presentViewController:navi animated:YES completion:nil];
    }
}
@end
