//
//  WFCUConferenceUnmuteRequestTableViewController.m
//  WFChatUIKit
//
//  Created by Rain on 2022/10/3.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#import "WFCUConferenceUnmuteRequestTableViewController.h"
#import "UIColor+YH.h"
#import "WFCUConferenceMemberTableViewCell.h"
#import "WFCUConferenceManager.h"
#import <SDWebImage/SDWebImage.h>
#import "WFCUUtilities.h"
#import "WFCUImage.h"

@interface WFCUConferenceUnmuteRequestTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;

@property(nonatomic, strong)UIButton *acceptAllBtn;
@property(nonatomic, strong)UIButton *rejectAllBtn;
@end

@implementation WFCUConferenceUnmuteRequestTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGRect bounds = self.view.bounds;
    CGFloat buttonHeight = 48;
    CGFloat buttonWidth = bounds.size.width/2 - 16 - 8;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, bounds.size.height - [WFCUUtilities wf_safeDistanceBottom] - buttonHeight - 16)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.sectionIndexColor = [UIColor colorWithHexString:@"0x4e4e4e"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
    
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"C") style:UIBarButtonItemStyleDone target:self action:@selector(onClose:)];
    
    if([WFCUConferenceManager sharedInstance].applyingUnmuteMembers.count) {
        self.acceptAllBtn = [self createBtn:CGRectMake(16, bounds.size.height - [WFCUUtilities wf_safeDistanceBottom] - buttonHeight - 16, buttonWidth, buttonHeight) title:@"全部同意" action:@selector(onAcceptAllBtnPressed:)];
        self.rejectAllBtn = [self createBtn:CGRectMake(bounds.size.width - 16 - buttonWidth, bounds.size.height - [WFCUUtilities wf_safeDistanceBottom] - buttonHeight - 16, buttonWidth, buttonHeight) title:@"全部拒绝" action:@selector(onRejectAllBtnPressed:)];
    }
}

- (void)onAcceptAllBtnPressed:(id)sender {
    [[WFCUConferenceManager sharedInstance] approveAllMemberUnmute:YES];
    [self.tableView reloadData];
}

- (void)onRejectAllBtnPressed:(id)sender {
    [[WFCUConferenceManager sharedInstance] approveAllMemberUnmute:NO];
    [self.tableView reloadData];
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

- (UIButton *)createBtn:(CGRect)frame title:(NSString *)title action:(SEL)action {
    UIButton *btn = [[UIButton alloc] initWithFrame:frame];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:14];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn.layer.borderWidth = 1;
    btn.layer.borderColor = [UIColor grayColor].CGColor;
    btn.layer.masksToBounds = YES;
    btn.layer.cornerRadius = 5.f;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:btn];
    
    return btn;
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
        [reject setTitle:WFCString(@"Reject") forState:UIControlStateNormal];
        [reject setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [reject addTarget:self action:@selector(onRejectBtn:) forControlEvents:UIControlEventTouchDown];
        reject.layer.masksToBounds = YES;
        reject.layer.cornerRadius = 3.f;
        
        UIButton *accept = [[UIButton alloc] initWithFrame:CGRectMake(size.width - 8 - buttonWidth - 4 - buttonWidth, 0, buttonWidth, size.height)];
        [accept setTitle:WFCString(@"Agree") forState:UIControlStateNormal];
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
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage:[WFCUImage imageNamed:@"PersonalChat"]];
    cell.tag = indexPath.row;
    
    return cell;
}
@end
