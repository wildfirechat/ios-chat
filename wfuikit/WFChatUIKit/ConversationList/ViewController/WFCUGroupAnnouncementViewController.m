//
//  WFCUGroupAnnouncementViewController.m
//  WFChatUIKit
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "WFCUGroupAnnouncementViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDWebImage.h"
#import "WFCUConfigManager.h"
#import "MBProgressHUD.h"


@interface WFCUGroupAnnouncementViewController () <UITextViewDelegate>
@property(nonatomic, strong)UIImageView *portraitView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UILabel *timeLabel;

@property(nonatomic, strong)UITextView *textView;
@end

@implementation WFCUGroupAnnouncementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    int offset = 0;
    if (self.announcement.author.length && self.announcement.text.length) {
        self.portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(16, kStatusBarAndNavigationBarHeight + 16, 48, 48)];
        WFCCUserInfo *author = [[WFCCIMService sharedWFCIMService] getUserInfo:self.announcement.author refresh:NO];
        [self.portraitView sd_setImageWithURL:[NSURL URLWithString:author.portrait] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, kStatusBarAndNavigationBarHeight + 16, self.view.bounds.size.width - 80 - 16, 20)];
        self.nameLabel.text = author.displayName;
        
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, kStatusBarAndNavigationBarHeight + 48, self.view.bounds.size.width - 80 - 16, 14)];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.announcement.timestamp/1000];
        self.timeLabel.text = date.description;
        self.timeLabel.font = [UIFont systemFontOfSize:14];
        self.timeLabel.textColor = [UIColor grayColor];
        
        
        [self.view addSubview:self.portraitView];
        [self.view addSubview:self.nameLabel];
        [self.view addSubview:self.timeLabel];
        offset = 80;
    } else {
        offset = 16;
    }
    
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(16, kStatusBarAndNavigationBarHeight + offset, self.view.bounds.size.width - 32, 0.5)];
    line.backgroundColor = [UIColor grayColor];
    [self.view addSubview:line];
    
    CGFloat hintSize = 0;
    if (!self.isManager) {
        line = [[UIView alloc] initWithFrame:CGRectMake(16, self.view.bounds.size.height - kTabbarSafeBottomMargin - 40, self.view.bounds.size.width - 32, 0.5)];
        line.backgroundColor = [UIColor grayColor];
        [self.view addSubview:line];
        
        UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(16, self.view.bounds.size.height - kTabbarSafeBottomMargin - 36, self.view.bounds.size.width - 32, 16)];
        hint.textAlignment = NSTextAlignmentCenter;
        hint.text = @"仅群主和管理员可编辑";
        hint.textColor = [UIColor grayColor];
        hint.font = [UIFont systemFontOfSize:12];
        [self.view addSubview:hint];
        hintSize = 40;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"编辑" style:UIBarButtonItemStyleDone target:self action:@selector(onEditBtn:)];
    }
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(16, kStatusBarAndNavigationBarHeight + offset + 1, self.view.bounds.size.width - 31, self.view.bounds.size.height - 81 - kStatusBarAndNavigationBarHeight - kTabbarSafeBottomMargin - hintSize)];
    self.textView.editable = NO;
    self.textView.text = self.announcement.text;
    self.textView.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    self.textView.delegate = self;
    [self.view addSubview:self.textView];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)onEditBtn:(id)sender {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(onSaveBtn:)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.textView.editable = YES;
    [self.textView becomeFirstResponder];
    self.textView.selectedRange = NSMakeRange(self.announcement.text.length, 0);
}

- (void)onSaveBtn:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"保存中...";
    [hud showAnimated:YES];
    
    [[WFCUConfigManager globalManager].appServiceProvider updateGroup:self.announcement.groupId announcement:self.textView.text success:^(long timestamp) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = @"保存成功";
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
            
            self.announcement.author = [WFCCNetworkService sharedInstance].userId;
            self.announcement.text = self.textView.text;
            self.announcement.timestamp = timestamp;
            [self.navigationController popViewControllerAnimated:YES];
        });
    } error:^(int error_code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = @"保存失败";
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        });
    }];
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    if ([self.announcement.text isEqualToString:textView.text]) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}
@end
