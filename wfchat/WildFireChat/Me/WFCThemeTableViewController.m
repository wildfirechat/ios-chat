//
//  WFCThemeTableViewController.m
//  WildFireChat
//
//  Created by dali on 2020/4/11.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCThemeTableViewController.h"
#import "UIColor+YH.h"
#import "WFCThemeTableViewCell.h"
#import <WFChatUIKit/WFChatUIKit.h>

@interface WFCThemeTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;
@end

@implementation WFCThemeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect frame = self.view.frame;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.tableHeaderView = nil;
    
    self.definesPresentationContext = YES;
    
    self.tableView.sectionIndexColor = [UIColor colorWithHexString:@"0x4e4e4e"];
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
}
- (void)displayUpdatedAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"修改成功！请退回到应用主页面查看效果。" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

    }];
    
    [alert addAction:action2];
    
    [self presentViewController:alert animated:YES completion:nil];
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCThemeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[WFCThemeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    if (indexPath.row == ThemeType_WFChat) {
        cell.textLabel.text = @"蓝色";
    } else if(indexPath.row == ThemeType_White) {
        cell.textLabel.text = @"白色";
    }
    
    if ([WFCUConfigManager globalManager].selectedTheme == indexPath.row) {
        cell.checked = YES;
    } else {
        cell.checked = NO;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 48;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != [WFCUConfigManager globalManager].selectedTheme) {
        [WFCUConfigManager globalManager].selectedTheme = indexPath.row;
        [self.tableView reloadData];
        [self displayUpdatedAlert];
    }
}
@end
