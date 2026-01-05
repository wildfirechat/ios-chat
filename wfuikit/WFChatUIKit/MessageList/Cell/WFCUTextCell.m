//
//  TextCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUTextCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"
#import "SelectableTextView.h"
#import "WFCUConfigManager.h"
#import <MessageUI/MessageUI.h>

#define TEXT_LABEL_TOP_PADDING 3
#define TEXT_LABEL_BUTTOM_PADDING 5

@interface WFCUTextCell () <SelectableTextViewDelegate, MFMailComposeViewControllerDelegate>

@end

@implementation WFCUTextCell
+ (UIFont *)defaultFont {
//    return [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    return [UIFont systemFontOfSize:18];
}

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    NSDictionary *dict = [[WFCUConfigManager globalManager].cellSizeMap objectForKey:@(msgModel.message.messageId)];
    if (dict && ceil([dict[@"viewWidth"] floatValue]) == ceil(width)) {
        float width = [dict[@"width"] floatValue];
        float height = [dict[@"height"] floatValue];
        return CGSizeMake(width, height);
    }
    
  WFCCTextMessageContent *txtContent = (WFCCTextMessageContent *)msgModel.message.content;
    CGSize size = [WFCUUtilities getTextDrawingSize:txtContent.text font:[WFCUTextCell defaultFont] constrainedSize:CGSizeMake(width, 8000)];
    size.height += TEXT_LABEL_TOP_PADDING + TEXT_LABEL_BUTTOM_PADDING;
    if (size.width < 40) {
        size.width += 4;
        if (size.width > 40) {
            size.width = 40;
        } else if (size.width < 24) {
            size.width = 24;
        }
    }
    
    [[WFCUConfigManager globalManager].cellSizeMap setObject:@{@"viewWidth":@(width), @"width":@(size.width), @"height":@(size.height)} forKey:@(msgModel.message.messageId)];
  return size;
}

- (void)setModel:(WFCUMessageModel *)model {
  [super setModel:model];
    
  WFCCTextMessageContent *txtContent = (WFCCTextMessageContent *)model.message.content;
    CGRect frame = self.contentArea.bounds;
  self.textLabel.frame = CGRectMake(0, TEXT_LABEL_TOP_PADDING, frame.size.width, frame.size.height - TEXT_LABEL_TOP_PADDING - TEXT_LABEL_BUTTOM_PADDING);
    self.textLabel.textAlignment = NSTextAlignmentLeft;

    // 确保使用正确的字体（与计算高度时一致）
    self.textLabel.font = [WFCUTextCell defaultFont];

    [self.textLabel setText:txtContent.text];
}

- (SelectableTextView *)textLabel {
    if (!_textLabel) {
        _textLabel = [[SelectableTextView alloc] init];
        _textLabel.selectableTextViewDelegate = self;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.scrollEnabled = NO;
        _textLabel.editable = NO;
        // 重要：使用与计算高度时相同的字体
        _textLabel.font = [WFCUTextCell defaultFont];
        [self.contentArea addSubview:_textLabel];
    }
    return _textLabel;
}

#pragma mark - SelectableTextViewDelegate
- (void)didSelectUrl:(NSString *)urlString {
    [self.delegate didSelectUrl:self withModel:self.model withUrl:urlString];
}

- (void)didSelectPhoneNumber:(NSString *)phoneNumberString {
    [self.delegate didSelectPhoneNumber:self withModel:self.model withPhoneNumber:phoneNumberString];
}

- (void)didSelectEmail:(NSString *)emailString {
    [self sendEmailTo:emailString];
}

- (void)didLongPressTextView:(SelectableTextView *)textView {
    // 当 SelectableTextView 被长按时，触发 cell 的长按事件
    [self.delegate didLongPressMessageCell:self withModel:self.model];
}

// 发送邮件
- (void)sendEmailTo:(NSString *)email {
    if (!email || email.length == 0) {
        return;
    }

    // 获取当前视图控制器
    UIViewController *topVC = [self topViewController];
    if (!topVC) {
        return;
    }

    // 检查设备是否支持发送邮件
    if ([MFMailComposeViewController canSendMail]) {
        // 使用 MFMailComposeViewController
        MFMailComposeViewController *mailComposeVC = [[MFMailComposeViewController alloc] init];
        mailComposeVC.mailComposeDelegate = self;
        [mailComposeVC setToRecipients:@[email]];

        [topVC presentViewController:mailComposeVC animated:YES completion:nil];
    } else {
        // 如果不支持，使用 mailto: URL scheme
        NSString *emailString = [NSString stringWithFormat:@"mailto:%@", email];
        NSURL *emailURL = [NSURL URLWithString:emailString];

        if ([[UIApplication sharedApplication] canOpenURL:emailURL]) {
            [[UIApplication sharedApplication] openURL:emailURL options:@{} completionHandler:nil];
        } else {
            // 如果都无法发送，显示提示
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                           message:@"您的设备不支持发送邮件"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:okAction];
            [topVC presentViewController:alert animated:YES completion:nil];
        }
    }
}

// 获取当前最顶层的视图控制器
- (UIViewController *)topViewController {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootVC = keyWindow.rootViewController;

    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }

    if ([rootVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)rootVC;
        return nav.visibleViewController;
    }

    return rootVC;
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    switch (result) {
        case MFMailComposeResultSent:
            NSLog(@"邮件已发送");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"邮件已保存");
            break;
        case MFMailComposeResultCancelled:
            NSLog(@"邮件已取消");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"邮件发送失败: %@", error.localizedDescription);
            break;
        default:
            break;
    }

    UIViewController *topVC = [self topViewController];
    [topVC dismissViewControllerAnimated:YES completion:nil];
}

@end
