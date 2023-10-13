//
//  WFCUGroupAnnouncementViewController.m
//  WFChatUIKit
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "WFCUGroupAnnouncementViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "WFCUConfigManager.h"
#import "MBProgressHUD.h"
#import "WFCUImage.h"
#import "WFCUUtilities.h"
#import "UIView+Toast.h"

@interface WFCUGroupAnnouncementViewController () <UITextViewDelegate>
@property(nonatomic, strong)UIImageView *portraitView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UILabel *timeLabel;

@property(nonatomic, strong)UILabel *maxLengthLabel;

@property(nonatomic, strong)UITextView *textView;
@end

#define MAX_TEXT_LENGTH 2000

@implementation WFCUGroupAnnouncementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    int offset = 0;
    CGFloat headHeight;
    if (self.announcement.author.length && self.announcement.text.length) {
        UIView *headView = [[UIView alloc] initWithFrame:CGRectMake(0, [WFCUUtilities wf_navigationFullHeight], self.view.bounds.size.width, 80)];
        
        self.portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 16, 48, 48)];
        WFCCUserInfo *author = [[WFCCIMService sharedWFCIMService] getUserInfo:self.announcement.author refresh:NO];
        [self.portraitView sd_setImageWithURL:[NSURL URLWithString:author.portrait] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 16, self.view.bounds.size.width - 80 - 16, 20)];
        self.nameLabel.text = author.displayName;
        
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 48, self.view.bounds.size.width - 80 - 16, 14)];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.announcement.timestamp/1000];
        self.timeLabel.text = date.description;
        self.timeLabel.font = [UIFont systemFontOfSize:14];
        self.timeLabel.textColor = [UIColor grayColor];
        
        
        [headView addSubview:self.portraitView];
        [headView addSubview:self.nameLabel];
        [headView addSubview:self.timeLabel];
        [self.view addSubview:headView];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapHeaderView:)];
        [headView addGestureRecognizer:tap];
        
        offset = 80;
        headHeight = offset;
    } else {
        offset = 16;
        headHeight = offset;
    }
    
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(16, [WFCUUtilities wf_navigationFullHeight] + offset, self.view.bounds.size.width - 32, 0.5)];
    line.backgroundColor = [UIColor grayColor];
    [self.view addSubview:line];
    
    CGFloat hintSize = 0;
    if (!self.isManager) {
        line = [[UIView alloc] initWithFrame:CGRectMake(16, self.view.bounds.size.height - [WFCUUtilities wf_safeDistanceBottom] - 40, self.view.bounds.size.width - 32, 0.5)];
        line.backgroundColor = [UIColor grayColor];
        [self.view addSubview:line];
        
        UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(16, self.view.bounds.size.height - [WFCUUtilities wf_safeDistanceBottom] - 36, self.view.bounds.size.width - 32, 16)];
        hint.textAlignment = NSTextAlignmentCenter;
        hint.text = @"仅群主和管理员可编辑";
        hint.textColor = [UIColor grayColor];
        hint.font = [UIFont systemFontOfSize:12];
        [self.view addSubview:hint];
        hintSize = 40;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Edit") style:UIBarButtonItemStyleDone target:self action:@selector(onEditBtn:)];
    }
    
    CGFloat maxLenLabelHeight = 24;
    
    CGFloat textHeigh = self.view.bounds.size.height - headHeight - [WFCUUtilities wf_navigationFullHeight] - [WFCUUtilities wf_safeDistanceBottom] - hintSize - maxLenLabelHeight;
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(16, [WFCUUtilities wf_navigationFullHeight] + offset + 1, self.view.bounds.size.width - 32, textHeigh)];
    self.textView.editable = NO;
    self.textView.text = self.announcement.text;
    self.textView.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    self.textView.delegate = self;
    [self.view addSubview:self.textView];
    offset += textHeigh;
    offset += 4;
    
    self.maxLengthLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 80 - 16, [WFCUUtilities wf_navigationFullHeight] + offset, 80, maxLenLabelHeight - 4)];
    self.maxLengthLabel.font = [UIFont systemFontOfSize:12];
    self.maxLengthLabel.textColor = [UIColor grayColor];
    self.maxLengthLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:self.maxLengthLabel];
    [self updateMaxLengthLabel];
    self.maxLengthLabel.hidden = YES;
}

- (void)updateMaxLengthLabel {
    self.maxLengthLabel.text = [NSString stringWithFormat:@"%d/%d", self.textView.text.length, MAX_TEXT_LENGTH];
}

- (void)onTapHeaderView:(id)sender {
    if([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
}

- (void)onEditBtn:(id)sender {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Save") style:UIBarButtonItemStyleDone target:self action:@selector(onSaveBtn:)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.textView.editable = YES;
    [self.textView becomeFirstResponder];
    self.textView.selectedRange = NSMakeRange(self.announcement.text.length, 0);
    self.maxLengthLabel.hidden = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (![self.textView isFirstResponder]) {
        return;
    }
    NSDictionary *userInfo = [notification userInfo];
    NSValue *value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [value CGRectValue];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    int offset = 0;
    CGFloat headHeight;
    if (self.announcement.author.length && self.announcement.text.length) {
        offset = 80;
        headHeight = offset;
    } else {
        offset = 16;
        headHeight = offset;
    }
    
    
    CGFloat hintSize = self.isManager?0:40;
    
    CGFloat maxLenLabelHeight = 24;
    
    CGFloat textHeigh = self.view.bounds.size.height - headHeight - [WFCUUtilities wf_navigationFullHeight] - [WFCUUtilities wf_safeDistanceBottom] - hintSize - maxLenLabelHeight - keyboardRect.size.height;
    CGRect textViewFrame = self.textView.frame;
    textViewFrame.size.height = textHeigh;
    
    
    offset += textHeigh;
    offset += 4;
    
    CGRect maxLenFrame = self.maxLengthLabel.frame;
    maxLenFrame.origin.y = [WFCUUtilities wf_navigationFullHeight] + offset + 1;
    
    
    [UIView animateWithDuration:duration animations:^{
        self.textView.frame = textViewFrame;
        self.maxLengthLabel.frame = maxLenFrame;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    int offset = 0;
    CGFloat headHeight;
    if (self.announcement.author.length && self.announcement.text.length) {
        offset = 80;
        headHeight = offset;
    } else {
        offset = 16;
        headHeight = offset;
    }
    
    CGFloat hintSize = self.isManager?0:40;
    CGFloat maxLenLabelHeight = 24;
    
    CGFloat textHeigh = self.view.bounds.size.height - headHeight - [WFCUUtilities wf_navigationFullHeight] - [WFCUUtilities wf_safeDistanceBottom] - hintSize - maxLenLabelHeight;
    CGRect textViewFrame = self.textView.frame;
    textViewFrame.size.height = textHeigh;
    
    offset += textHeigh;
    offset += 4;
    
    CGRect maxLenFrame = self.maxLengthLabel.frame;
    maxLenFrame.origin.y = [WFCUUtilities wf_navigationFullHeight] + offset;
    
    
    [UIView animateWithDuration:duration animations:^{
        self.textView.frame = textViewFrame;
        self.maxLengthLabel.frame = maxLenFrame;
    }];
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
    [self updateMaxLengthLabel];
    if ([self.announcement.text isEqualToString:textView.text]) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if(newText.length > MAX_TEXT_LENGTH) {
        [self.view makeToast:@"超过大小限制"];
        return NO;
    }
    
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
