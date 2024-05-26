//
//  FavGroupTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/13.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUDomainTableViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "UIView+Toast.h"
#import "WFCUImage.h"

@interface WFCUDomainTableViewController ()
@property (nonatomic, strong)NSArray<WFCCDomainInfo *> *domains;
@end

@implementation WFCUDomainTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.domains = [[NSMutableArray alloc] init];
    self.title = WFCString(@"Mesh");
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    if(self.isPresent) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(onClose:)];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSettingUpdated:) name:kSettingUpdated object:nil];
}

- (void)onSettingUpdated:(NSNotification *)notification {
    [self refreshList];
}

- (void)onClose:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)refreshList {
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] getRemoteDomains:^(NSArray<WFCCDomainInfo *> *domains) {
        ws.domains = domains;
        [ws.tableView reloadData];
    } error:^(int errorCode) {
        [ws.view makeToast:@"网络错误"];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshList];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.domains.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupCellId"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupCellId"];
    }
    
    cell.textLabel.text = self.domains[indexPath.row].name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.onSelect) {
        self.onSelect(self.domains[indexPath.row].domainId);
        if(self.isPresent) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
