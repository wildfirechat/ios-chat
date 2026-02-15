//
//  WFCUPollHomeViewController.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCUPollHomeViewController.h"
#import "WFCUCreatePollViewController.h"
#import "WFCUPollListViewController.h"
#import "WFCUConfigManager.h"
#import "WFCUUtilities.h"
#import "WFCUImage.h"

#define WFCString(key) [[NSBundle bundleForClass:[self class]] localizedStringForKey:key value:@"" table:@"wfc"]

@interface WFCUPollHomeMenuItem : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *iconName;
@property (nonatomic, copy) void (^action)(void);
+ (instancetype)itemWithTitle:(NSString *)title iconName:(NSString *)iconName action:(void (^)(void))action;
@end

@implementation WFCUPollHomeMenuItem
+ (instancetype)itemWithTitle:(NSString *)title iconName:(NSString *)iconName action:(void (^)(void))action {
    WFCUPollHomeMenuItem *item = [[WFCUPollHomeMenuItem alloc] init];
    item.title = title;
    item.iconName = iconName;
    item.action = action;
    return item;
}
@end

@interface WFCUPollHomeViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<WFCUPollHomeMenuItem *> *menuItems;
@end

@implementation WFCUPollHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = WFCString(@"Poll");
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    
    [self setupNavigationBar];
    [self setupMenuItems];
    [self setupTableView];
}

- (void)setupNavigationBar {
    // 关闭按钮
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeButton setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
    self.navigationItem.leftBarButtonItem = closeItem;
}

- (void)setupMenuItems {
    __weak typeof(self) weakSelf = self;
    
    WFCUPollHomeMenuItem *createItem = [WFCUPollHomeMenuItem itemWithTitle:WFCString(@"CreatePoll")
                                                                    iconName:@"plus.circle.fill"
                                                                      action:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            WFCUCreatePollViewController *vc = [[WFCUCreatePollViewController alloc] init];
            vc.groupId = strongSelf.groupId;
            [strongSelf.navigationController pushViewController:vc animated:YES];
        }
    }];
    
    WFCUPollHomeMenuItem *myPollsItem = [WFCUPollHomeMenuItem itemWithTitle:WFCString(@"MyPolls")
                                                                     iconName:@"list.bullet.clipboard.fill"
                                                                       action:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            WFCUPollListViewController *vc = [[WFCUPollListViewController alloc] init];
            vc.groupId = strongSelf.groupId;
            [strongSelf.navigationController pushViewController:vc animated:YES];
        }
    }];
    
    self.menuItems = @[createItem, myPollsItem];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = 60;
    [self.view addSubview:self.tableView];
}

- (void)closeButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"PollHomeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    WFCUPollHomeMenuItem *item = self.menuItems[indexPath.row];
    cell.textLabel.text = item.title;
    cell.imageView.image = [UIImage systemImageNamed:item.iconName];
    cell.imageView.tintColor = [UIColor systemBlueColor];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WFCUPollHomeMenuItem *item = self.menuItems[indexPath.row];
    if (item.action) {
        item.action();
    }
}

@end
