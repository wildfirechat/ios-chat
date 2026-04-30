//
//  WFCUDialPadViewController.m
//  Wildfire Chat
//
//  Created by DialIn on 2026/4/25.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "WFCUDialPadViewController.h"
#import <WFAVEngineKit/WFAVEngineKit.h>
#import <WFChatClient/WFCCConversation.h>
#import <WFChatUIKit/WFCUUtilities.h>
#import <WFChatUIKit/WFCUVideoViewController.h>

@interface WFCUDialPadViewController ()
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) NSMutableString *numberString;
@end

@implementation WFCUDialPadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.numberString = [NSMutableString string];
    
    [self setupNavBar];
    [self setupUI];
}

- (void)setupNavBar {
    self.title = @"拨号";
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(onClose:)];
    self.navigationItem.leftBarButtonItem = closeItem;
}

- (void)setupUI {
    CGFloat screenW = self.view.bounds.size.width;
    CGFloat topY = [WFCUUtilities wf_navigationFullHeight] + 20;
    
    // Number display
    self.numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, topY, screenW - 40, 60)];
    self.numberLabel.font = [UIFont systemFontOfSize:36 weight:UIFontWeightMedium];
    self.numberLabel.textAlignment = NSTextAlignmentCenter;
    self.numberLabel.textColor = [UIColor blackColor];
    self.numberLabel.adjustsFontSizeToFitWidth = YES;
    self.numberLabel.minimumScaleFactor = 0.5;
    [self.view addSubview:self.numberLabel];
    
    // Delete button
    UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    deleteBtn.frame = CGRectMake(screenW - 80, topY + 10, 60, 40);
    [deleteBtn setTitle:@"⌫" forState:UIControlStateNormal];
    deleteBtn.titleLabel.font = [UIFont systemFontOfSize:24];
    [deleteBtn addTarget:self action:@selector(onDelete:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:deleteBtn];
    
    // Keypad
    NSArray *keys = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"*", @"0", @"#"];
    CGFloat btnW = 72;
    CGFloat btnH = 72;
    CGFloat gapX = (screenW - btnW * 3) / 4;
    CGFloat gapY = 16;
    CGFloat startY = topY + 80;
    
    for (int i = 0; i < keys.count; i++) {
        int row = i / 3;
        int col = i % 3;
        CGFloat x = gapX + col * (btnW + gapX);
        CGFloat y = startY + row * (btnH + gapY);
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(x, y, btnW, btnH);
        btn.layer.cornerRadius = btnW / 2;
        btn.layer.masksToBounds = YES;
        btn.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        [btn setTitle:keys[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightMedium];
        [btn addTarget:self action:@selector(onKeyTap:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = i;
        [self.view addSubview:btn];
    }
    
    // Call button
    CGFloat callBtnY = startY + 4 * (btnH + gapY) + 20;
    UIButton *callBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    callBtn.frame = CGRectMake((screenW - 72) / 2, callBtnY, 72, 72);
    callBtn.layer.cornerRadius = 36;
    callBtn.layer.masksToBounds = YES;
    callBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0];
    [callBtn setTitle:@"📞" forState:UIControlStateNormal];
    callBtn.titleLabel.font = [UIFont systemFontOfSize:32];
    [callBtn addTarget:self action:@selector(onCall:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:callBtn];
}

- (void)updateNumberLabel {
    self.numberLabel.text = self.numberString.length ? self.numberString : @" ";
}

- (void)onClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onKeyTap:(UIButton *)sender {
    NSArray *keys = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"*", @"0", @"#"];
    [self.numberString appendString:keys[sender.tag]];
    [self updateNumberLabel];
}

- (void)onDelete:(id)sender {
    if (self.numberString.length > 0) {
        [self.numberString deleteCharactersInRange:NSMakeRange(self.numberString.length - 1, 1)];
        [self updateNumberLabel];
    }
}

- (void)onCall:(id)sender {
    NSString *number = [self.numberString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!number.length) {
        return;
    }
    
    WFCCConversation *conversation = [WFCCConversation conversationWithType:Single_Type target:self.targetUserId line:0];
    WFCUVideoViewController *videoVC = [[WFCUVideoViewController alloc] initWithTargets:@[self.targetUserId]
                                                                           conversation:conversation
                                                                              audioOnly:YES
                                                                               pstnType:1
                                                                             pstnNumber:number];
    [[WFAVEngineKit sharedEngineKit] presentViewController:videoVC];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
