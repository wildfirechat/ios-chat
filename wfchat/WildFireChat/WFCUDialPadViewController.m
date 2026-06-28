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
#import <WFChatUIKit/WFCUImage.h>
#import "UIFont+YH.h"

@interface WFCUDialPadViewController ()
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) NSMutableString *numberString;
@property (nonatomic, strong) UIButton *callButton;
@property (nonatomic, strong) NSTimer *deleteTimer;
@property (nonatomic, strong) UIImpactFeedbackGenerator *hapticGenerator;
@end

@implementation WFCUDialPadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.numberString = [NSMutableString string];
    self.hapticGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [self.hapticGenerator prepare];
    
    [self setupNavBar];
    [self setupUI];
    [self updateNumberLabel];
}

- (void)setupNavBar {
    self.title = @"落地电话";
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(onClose:)];
    self.navigationItem.leftBarButtonItem = closeItem;
}

- (void)setupUI {
    CGFloat screenW = self.view.bounds.size.width;
    CGFloat topY = [WFCUUtilities wf_navigationFullHeight] + 20;
    
    // Number display
    self.numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, topY, screenW - 40, 60)];
    self.numberLabel.font = [UIFont scaledSystemFontOfSize:36 weight:UIFontWeightMedium];
    self.numberLabel.textAlignment = NSTextAlignmentCenter;
    self.numberLabel.textColor = [UIColor blackColor];
    self.numberLabel.adjustsFontSizeToFitWidth = YES;
    self.numberLabel.minimumScaleFactor = 0.5;
    [self.view addSubview:self.numberLabel];
    
    // Delete button
    UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    deleteBtn.frame = CGRectMake(screenW - 80, topY + 10, 60, 40);
    [deleteBtn setTitle:@"⌫" forState:UIControlStateNormal];
    deleteBtn.titleLabel.font = [UIFont scaledSystemFontOfSize:24];
    [deleteBtn addTarget:self action:@selector(onDelete:) forControlEvents:UIControlEventTouchUpInside];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onDeleteLongPress:)];
    [deleteBtn addGestureRecognizer:longPress];
    [self.view addSubview:deleteBtn];
    
    // Keypad
    NSArray *keys = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"*", @"0", @"#"];
    NSArray *letters = @[@"", @"A B C", @"D E F", @"G H I", @"J K L", @"M N O", @"P Q R S", @"T U V", @"W X Y Z", @"", @"+", @""];
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
        
        UIButton *btn = [self createKeyButtonWithDigit:keys[i] letter:letters[i] frame:CGRectMake(x, y, btnW, btnH)];
        [btn addTarget:self action:@selector(onKeyTap:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = i;
        [self.view addSubview:btn];
    }
    
    // Call button
    CGFloat callBtnY = startY + 4 * (btnH + gapY) + 20;
    self.callButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.callButton.frame = CGRectMake((screenW - 72) / 2, callBtnY, 72, 72);
    self.callButton.layer.cornerRadius = 36;
    self.callButton.layer.masksToBounds = YES;
    self.callButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0];
    UIImage *callImage = [WFCUImage imageNamed:@"answer"];
    [self.callButton setImage:callImage forState:UIControlStateNormal];
    self.callButton.tintColor = [UIColor whiteColor];
    self.callButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.callButton.contentEdgeInsets = UIEdgeInsetsMake(18, 18, 18, 18);
    [self.callButton addTarget:self action:@selector(onCall:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.callButton];
}

- (UIButton *)createKeyButtonWithDigit:(NSString *)digit letter:(NSString *)letter frame:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    btn.layer.cornerRadius = frame.size.width / 2;
    btn.layer.masksToBounds = YES;
    btn.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    
    // Digit label
    CGFloat digitY = letter.length > 0 ? 10 : 0;
    CGFloat digitH = letter.length > 0 ? 30 : frame.size.height;
    UILabel *digitLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, digitY, frame.size.width, digitH)];
    digitLabel.text = digit;
    digitLabel.font = [UIFont scaledSystemFontOfSize:28 weight:UIFontWeightMedium];
    digitLabel.textAlignment = NSTextAlignmentCenter;
    digitLabel.textColor = [UIColor blackColor];
    digitLabel.userInteractionEnabled = NO;
    [btn addSubview:digitLabel];
    
    // Letter label
    if (letter.length > 0) {
        UILabel *letterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, frame.size.width, 16)];
        letterLabel.text = letter;
        letterLabel.font = [UIFont scaledSystemFontOfSize:9];
        letterLabel.textAlignment = NSTextAlignmentCenter;
        letterLabel.textColor = [UIColor grayColor];
        letterLabel.userInteractionEnabled = NO;
        [btn addSubview:letterLabel];
    }
    
    [btn addTarget:self action:@selector(keyTouchDown:) forControlEvents:UIControlEventTouchDown];
    [btn addTarget:self action:@selector(keyTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    
    return btn;
}

- (void)keyTouchDown:(UIButton *)sender {
    sender.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    [self.hapticGenerator impactOccurred];
    [self.hapticGenerator prepare];
}

- (void)keyTouchUp:(UIButton *)sender {
    sender.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
}

- (void)updateNumberLabel {
    self.numberLabel.text = self.numberString.length ? self.numberString : @" ";
    self.callButton.alpha = self.numberString.length > 0 ? 1.0 : 0.4;
    self.callButton.enabled = self.numberString.length > 0;
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

- (void)onDeleteLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self onDelete:nil];
        self.deleteTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onDelete:) userInfo:nil repeats:YES];
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        [self.deleteTimer invalidate];
        self.deleteTimer = nil;
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
