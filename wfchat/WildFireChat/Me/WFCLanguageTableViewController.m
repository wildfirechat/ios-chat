//
//  WFCLanguageTableViewController.m
//  WildFireChat
//
//  Created by WildFire Chat on 2025/01/04.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCLanguageTableViewController.h"
#import "WFCLanguageManager.h"
#import <WFChatUIKit/WFChatUIKit.h>
#import "MBProgressHUD.h"

@interface WFCLanguageTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSNumber *> *languages;
@end

@implementation WFCLanguageTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.title = LocalizedString(@"Language");
    [self.view addSubview:self.tableView];

    // 初始化语言选项
    self.languages = @[
        @(WFCLanguageTypeSystem),
        @(WFCLanguageTypeSimplifiedChinese),
        @(WFCLanguageTypeEnglish),
        @(WFCLanguageTypeTraditionalChinese)
    ];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.languages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"LanguageCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    WFCLanguageType languageType = [self.languages[indexPath.row] integerValue];
    cell.textLabel.text = [[WFCLanguageManager sharedManager] getLanguageDisplayName:languageType];

    // 显示当前选中的语言
    if (languageType == [[WFCLanguageManager sharedManager] getCurrentLanguage]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.textColor = [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:1.0];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = [UIColor blackColor];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    WFCLanguageType selectedLanguage = [self.languages[indexPath.row] integerValue];
    WFCLanguageType currentLanguage = [[WFCLanguageManager sharedManager] getCurrentLanguage];

    if (selectedLanguage == currentLanguage) {
        return;
    }

    // 显示确认对话框
    NSString *message = LocalizedString(@"LanguageChangeRestart");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalizedString(@"Language")
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:LocalizedString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:LocalizedString(@"Confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf changeLanguage:selectedLanguage];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
}

#pragma mark - Private Methods

- (void)changeLanguage:(WFCLanguageType)language {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LocalizedString(@"Saving");

    __weak typeof(self) weakSelf = self;
    [[WFCLanguageManager sharedManager] switchLanguage:language completion:^{
        [hud hideAnimated:YES];

        // 显示成功提示
        MBProgressHUD *successHud = [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
        successHud.mode = MBProgressHUDModeText;
        successHud.label.text = LocalizedString(@"LanguageChangeSuccess");
        successHud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [successHud hideAnimated:YES afterDelay:1.5];

        // 延迟后退出
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        });
    }];
}

@end
