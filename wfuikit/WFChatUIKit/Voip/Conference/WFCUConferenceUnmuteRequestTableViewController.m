//
//  WFCUConferenceUnmuteRequestTableViewController.m
//  WFChatUIKit
//
//  Created by Rain on 2022/10/3.
//  Copyright © 2022 Tom Lee. All rights reserved.
//

#import "WFCUConferenceUnmuteRequestTableViewController.h"
#import "UIColor+YH.h"
#import "WFCUConferenceMemberTableViewCell.h"
#import "WFCUConferenceManager.h"
#import <SDWebImage/SDWebImage.h>

@interface WFCUConferenceUnmuteRequestTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;
@end

@implementation WFCUConferenceUnmuteRequestTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.sectionIndexColor = [UIColor colorWithHexString:@"0x4e4e4e"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(onClose:)];
}

- (void)onClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onAcceptBtn:(UIButton *)sender {
    int row = (int)sender.tag;
    NSString *userId = [WFCUConferenceManager sharedInstance].applyingUnmuteMembers[row];
    [[WFCUConferenceManager sharedInstance] approveMember:userId unmute:YES];
    [self.tableView reloadData];
}

- (void)onRejectBtn:(UIButton *)sender {
    int row = (int)sender.tag;
    NSString *userId = [WFCUConferenceManager sharedInstance].applyingUnmuteMembers[row];
    [[WFCUConferenceManager sharedInstance] approveMember:userId unmute:NO];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource<NSObject>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [WFCUConferenceManager sharedInstance].applyingUnmuteMembers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        CGSize size = cell.bounds.size;
        size.width = self.view.bounds.size.width;
        CGFloat buttonWidth = 56;
        UIButton *reject = [[UIButton alloc] initWithFrame:CGRectMake(size.width - 8 - buttonWidth, 0, buttonWidth, size.height)];
        [reject setTitle:@"拒绝" forState:UIControlStateNormal];
        [reject setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [reject addTarget:self action:@selector(onRejectBtn:) forControlEvents:UIControlEventTouchDown];
        reject.layer.masksToBounds = YES;
        reject.layer.cornerRadius = 3.f;
        
        UIButton *accept = [[UIButton alloc] initWithFrame:CGRectMake(size.width - 8 - buttonWidth - 4 - buttonWidth, 0, buttonWidth, size.height)];
        [accept setTitle:@"同意" forState:UIControlStateNormal];
        [accept setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [accept addTarget:self action:@selector(onAcceptBtn:) forControlEvents:UIControlEventTouchDown];
        accept.layer.masksToBounds = YES;
        accept.layer.cornerRadius = 3.f;
        
        [cell.contentView addSubview:reject];
        [cell.contentView addSubview:accept];
    }
    
    for (UIView *view in cell.contentView.subviews) {
        if([view isKindOfClass:[UIButton class]]) {
            [cell.contentView bringSubviewToFront:view];
        }
    }
    
    NSString *userId = [WFCUConferenceManager sharedInstance].applyingUnmuteMembers[indexPath.row];
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
    cell.textLabel.text = userInfo.friendAlias.length?userInfo.friendAlias:userInfo.displayName;
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
    cell.tag = indexPath.row;
    
    return cell;
}


@end
