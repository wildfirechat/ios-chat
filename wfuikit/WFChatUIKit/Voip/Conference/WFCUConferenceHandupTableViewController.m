//
//  WFCUConferenceHandupTableViewController.m
//  WFChatUIKit
//
//  Created by Rain on 2022/10/3.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#import "WFCUConferenceHandupTableViewController.h"
#import "UIColor+YH.h"
#import "WFCUConferenceMemberTableViewCell.h"
#import "WFCUConferenceManager.h"
#import <SDWebImage/SDWebImage.h>
#import "WFCUUtilities.h"
#import "WFCUImage.h"

@interface WFCUConferenceHandupTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;

@property(nonatomic, strong)UIButton *putdownAllBtn;
@end

@implementation WFCUConferenceHandupTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGRect bounds = self.view.bounds;
    CGFloat buttonHeight = 48;
    CGFloat buttonWidth = bounds.size.width - 16 - 16;
    
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
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Close") style:UIBarButtonItemStyleDone target:self action:@selector(onClose:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if([WFCUConferenceManager sharedInstance].handupMembers.count && !self.putdownAllBtn) {
        CGRect bounds = self.view.bounds;
        CGFloat buttonHeight = 48;
        CGFloat buttonWidth = bounds.size.width - 16 - 16;
        self.putdownAllBtn = [self createBtn:CGRectMake(16, bounds.size.height - [WFCUUtilities wf_safeDistanceBottom] - buttonHeight - 16, buttonWidth, buttonHeight) title:@"全部放下" action:@selector(onPutdownAllBtnPressed:)];
    }
}

- (void)onPutdownAllBtnPressed:(id)sender {
    [[WFCUConferenceManager sharedInstance] putAllHandDown];
    [self.tableView reloadData];
}

- (void)onClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    return [WFCUConferenceManager sharedInstance].handupMembers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        CGSize size = cell.bounds.size;
        size.width = self.view.bounds.size.width;
        CGFloat buttonWidth = 24;
        
        UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectMake(size.width - 8 - buttonWidth, (size.height - buttonWidth)/2, buttonWidth, buttonWidth)];
        imageview.image = [WFCUImage imageNamed:@"conference_handup"];
        [cell.contentView addSubview:imageview];
    }
    
    for (UIView *view in cell.contentView.subviews) {
        if([view isKindOfClass:[UIImageView class]]) {
            [cell.contentView bringSubviewToFront:view];
        }
    }
    
    NSString *userId = [WFCUConferenceManager sharedInstance].handupMembers[indexPath.row];
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
    cell.textLabel.text = userInfo.friendAlias.length?userInfo.friendAlias:userInfo.displayName;
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage:[WFCUImage imageNamed:@"PersonalChat"]];
    cell.tag = indexPath.row;
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *userId = [WFCUConferenceManager sharedInstance].handupMembers[indexPath.row];
}

@end
