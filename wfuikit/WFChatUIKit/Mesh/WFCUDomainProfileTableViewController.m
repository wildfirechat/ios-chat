//
//  WFCUDomainProfileTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/22.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUDomainProfileTableViewController.h"
#import "WFCUAddFriendViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUMessageListViewController.h"
#import "WFCUConfigManager.h"
#import "WFCUImage.h"
#import "WFCUUtilities.h"


@interface WFCUDomainProfileTableViewController () <UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic)UITableViewCell *addFriendCell;

@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<UITableViewCell *> *cells;


@property (nonatomic, strong)WFCCDomainInfo *dommainInfo;
@end

@implementation WFCUDomainProfileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dommainInfo = [[WFCCIMService sharedWFCIMService] getDomainInfo:self.domainId refresh:YES];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.1)];

    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        keyWindow.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
    [keyWindow tintColorDidChange];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)loadData {
    self.cells = [[NSMutableArray alloc] init];
    self.addFriendCell = nil;
    
    UITableViewCell *nameCell = [self getAttrCell:@"名称" rightText:self.dommainInfo.name mutable:NO];
    [self.cells addObject:nameCell];
    
    UITableViewCell *emailCell = [self getAttrCell:@"邮箱" rightText:self.dommainInfo.email mutable:NO];
    [self.cells addObject:emailCell];
    
    UITableViewCell *telCell = [self getAttrCell:@"电话" rightText:self.dommainInfo.tel mutable:NO];
    [self.cells addObject:telCell];
    
    UITableViewCell *addressCell = [self getAttrCell:@"地址" rightText:self.dommainInfo.address mutable:NO];
    [self.cells addObject:addressCell];
    
    UITableViewCell *descCell = [self getAttrCell:@"描述" rightText:self.dommainInfo.desc mutable:NO];
    [self.cells addObject:descCell];
    
    
    self.addFriendCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    for (UIView *subView in self.addFriendCell.subviews) {
        [subView removeFromSuperview];
    }
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 8, self.view.bounds.size.width - 40, 40)];
    [btn setTitle:@"在此单位中查找用户" forState:UIControlStateNormal];
    [btn setBackgroundColor:[UIColor greenColor]];
    [btn addTarget:self action:@selector(onAddFriendBtn:) forControlEvents:UIControlEventTouchDown];
    btn.layer.cornerRadius = 5.f;
    btn.layer.masksToBounds = YES;
    if (@available(iOS 14, *)) {
        [self.addFriendCell.contentView addSubview:btn];
    } else {
        [self.addFriendCell addSubview:btn];
    }
        
    [self.tableView reloadData];
}

- (void)onAddFriendBtn:(id)sender {
    WFCUAddFriendViewController *vc = [[WFCUAddFriendViewController alloc] init];
    vc.domainId = self.domainId;
    [self.navigationController pushViewController:vc animated:YES];
}

- (UITableViewCell *)getAttrCell:(NSString *)leftText rightText:(NSString *)rightText mutable:(BOOL)mutable {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
//    for (UIView *subView in cell.subviews) {
//        [subView removeFromSuperview];
//    }
    if (!mutable) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    cell.tag = -1;
    [self addLabel:leftText onCell:cell isHeaderCell:NO isLeft:YES];
//    if (rightText.length == 0) {
//        rightText = @"未填写";
//    }
    [self addLabel:rightText onCell:cell isHeaderCell:NO isLeft:NO];
    return cell;
}

- (void)addLabel:(NSString *)titleStr onCell:(UITableViewCell *)cell isHeaderCell:(BOOL)isHeaderCell isLeft:(BOOL)left {
    UILabel *title ;
    if (isHeaderCell) {
        title = [[UILabel alloc] initWithFrame:CGRectMake(8, 4, 68, 68)];
    } else {
        if (left) {
            title = [[UILabel alloc] initWithFrame:CGRectMake(8, 2, 72, 36)];
        } else {
            CGFloat width = [UIScreen mainScreen].bounds.size.width;
            title = [[UILabel alloc] initWithFrame:CGRectMake(88, 2, width - 108 - 28, 36)];
        }
    }
    
    [title setFont:[UIFont systemFontOfSize:16]];
    [title setText:titleStr];
    if (left) {
        [title setTextAlignment:NSTextAlignmentLeft];
        title.tag = 1;
    } else {
        [title setTextAlignment:NSTextAlignmentRight];
        title.tag = 2;
    }
    
    [cell addSubview:title];
}


#pragma mark - UITableViewDataSource<NSObject>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return self.cells.count;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        return self.cells[indexPath.row];
    } else {
        return self.addFriendCell;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
