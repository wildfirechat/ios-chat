//
//  WFCUMarkdownCell.m
//  WFChat UIKit
//
//  Created by Kimi on 2025/3/8.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCUMarkdownCell.h"
#import "WFCUMarkdownLabel.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"
#import "WFCUConfigManager.h"
#import <MessageUI/MessageUI.h>
#import "Predefine.h"

#define MARKDOWN_TEXT_TOP_PADDING 3
#define MARKDOWN_TEXT_BOTTOM_PADDING 5
#define MARKDOWN_TEXT_LEFT_PADDING 0
#define MARKDOWN_TEXT_RIGHT_PADDING 0

#define REACTION_VIEW_TOP_PADDING 6
#define REACTION_VIEW_HEIGHT 20

@interface WFCUMarkdownCell () <WFCUMarkdownLabelDelegate, MFMailComposeViewControllerDelegate>
@end

@implementation WFCUMarkdownCell

+ (UIFont *)defaultFont {
    return [UIFont systemFontOfSize:18];
}

+ (NSString *)cacheKeyForText:(NSString *)text viewWidth:(CGFloat)width {
    // 使用文本内容+宽度作为缓存键（因为消息可能被编辑）
    return [NSString stringWithFormat:@"%@_%.0f", @(text.hash), width];
}

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCTextMessageContent *txtContent = (WFCCTextMessageContent *)msgModel.message.content;
    NSString *text = txtContent.text ?: @"";
    
    // 使用内容+宽度作为缓存键
    NSString *cacheKey = [self cacheKeyForText:text viewWidth:width];
    NSDictionary *dict = [[WFCUConfigManager globalManager].cellSizeCache objectForKey:cacheKey];
    if (dict) {
        float cellWidth = [dict[@"width"] floatValue];
        float cellHeight = [dict[@"height"] floatValue];
        // 如果有表情反应，增加高度
        if (txtContent.reactions.count > 0) {
            cellHeight += REACTION_VIEW_TOP_PADDING + REACTION_VIEW_HEIGHT;
        }
        return CGSizeMake(cellWidth, cellHeight);
    }
    
    // 计算 Markdown 文本实际尺寸
    CGFloat maxContentWidth = width - MARKDOWN_TEXT_LEFT_PADDING - MARKDOWN_TEXT_RIGHT_PADDING;
    CGSize contentSize = [WFCUMarkdownLabel sizeForText:text maxWidth:maxContentWidth font:[self defaultFont]];
    
    // 最终尺寸 = 内容尺寸 + padding
    CGFloat finalWidth = contentSize.width;
    CGFloat finalHeight = contentSize.height + MARKDOWN_TEXT_TOP_PADDING + MARKDOWN_TEXT_BOTTOM_PADDING;
    
    if (finalHeight < 20) {
        finalHeight = 20;
    }
    
    // 如果有表情反应，增加高度
    if (txtContent.reactions.count > 0) {
        finalHeight += REACTION_VIEW_TOP_PADDING + REACTION_VIEW_HEIGHT;
    }
    
    [[WFCUConfigManager globalManager].cellSizeCache setObject:@{
        @"width": @(finalWidth),
        @"height": @(finalHeight)
    } forKey:cacheKey];
    
    return CGSizeMake(finalWidth, finalHeight);
}

- (NSString *)reactionDisplayText:(NSArray<NSDictionary *> *)reactions {
    NSMutableString *displayText = [NSMutableString string];
    for (NSDictionary *reaction in reactions) {
        NSString *emoji = reaction[@"emoji"];
        NSArray *users = reaction[@"users"];
        if (emoji.length && users.count > 0) {
            if (displayText.length > 0) {
                [displayText appendString:@"  "];
            }
            [displayText appendString:emoji];
            [displayText appendString:@" "];
            // 获取用户 displayName
            NSMutableArray *names = [NSMutableArray array];
            for (NSString *userId in users) {
                WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
                NSString *name = userInfo.displayName.length > 0 ? userInfo.displayName : userId;
                [names addObject:name];
            }
            [displayText appendString:[names componentsJoinedByString:@", "]];
        }
    }
    return displayText;
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    WFCCTextMessageContent *txtContent = (WFCCTextMessageContent *)model.message.content;
    CGRect frame = self.contentArea.bounds;
    
    // 计算文本区域高度
    CGFloat textHeight = frame.size.height - MARKDOWN_TEXT_TOP_PADDING - MARKDOWN_TEXT_BOTTOM_PADDING;
    if (txtContent.reactions.count > 0) {
        textHeight -= (REACTION_VIEW_TOP_PADDING + REACTION_VIEW_HEIGHT);
    }
    
    self.markdownLabel.frame = CGRectMake(0, 
                                           MARKDOWN_TEXT_TOP_PADDING, 
                                           frame.size.width, 
                                           textHeight);
    
    [self.markdownLabel setMarkdownText:txtContent.text font:[WFCUMarkdownCell defaultFont]];
    
    // 设置表情显示
    if (txtContent.reactions.count > 0) {
        self.reactionLabel.hidden = NO;
        CGFloat reactionY = textHeight + MARKDOWN_TEXT_BOTTOM_PADDING + REACTION_VIEW_TOP_PADDING;
        self.reactionLabel.frame = CGRectMake(0, reactionY, frame.size.width, REACTION_VIEW_HEIGHT);
        self.reactionLabel.text = [self reactionDisplayText:txtContent.reactions];
    } else {
        self.reactionLabel.hidden = YES;
    }
}

- (UILabel *)reactionLabel {
    if (!_reactionLabel) {
        _reactionLabel = [[UILabel alloc] init];
        _reactionLabel.font = [UIFont systemFontOfSize:12];
        _reactionLabel.textColor = [UIColor grayColor];
        _reactionLabel.backgroundColor = [UIColor clearColor];
        [self.contentArea addSubview:_reactionLabel];
    }
    return _reactionLabel;
}

- (WFCUMarkdownLabel *)markdownLabel {
    if (!_markdownLabel) {
        _markdownLabel = [[WFCUMarkdownLabel alloc] init];
        _markdownLabel.markdownDelegate = self;
        _markdownLabel.backgroundColor = [UIColor clearColor];
        [self.contentArea addSubview:_markdownLabel];
    }
    return _markdownLabel;
}

#pragma mark - WFCUMarkdownLabelDelegate

- (void)markdownLabel:(WFCUMarkdownLabel *)label didSelectUrl:(NSString *)urlString {
    [self.delegate didSelectUrl:self withModel:self.model withUrl:urlString];
}

- (void)markdownLabel:(WFCUMarkdownLabel *)label didSelectPhoneNumber:(NSString *)phoneNumberString {
    [self.delegate didSelectPhoneNumber:self withModel:self.model withPhoneNumber:phoneNumberString];
}

- (void)markdownLabel:(WFCUMarkdownLabel *)label didSelectEmail:(NSString *)emailString {
    [self sendEmailTo:emailString];
}

- (void)markdownLabelDidLongPress:(WFCUMarkdownLabel *)label {
    [self.delegate didLongPressMessageCell:self withModel:self.model];
}

#pragma mark - 邮件发送

- (void)sendEmailTo:(NSString *)email {
    if (!email || email.length == 0) return;
    
    UIViewController *topVC = [self topViewController];
    if (!topVC) return;
    
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposeVC = [[MFMailComposeViewController alloc] init];
        mailComposeVC.mailComposeDelegate = self;
        [mailComposeVC setToRecipients:@[email]];
        [topVC presentViewController:mailComposeVC animated:YES completion:nil];
    } else {
        NSString *emailString = [NSString stringWithFormat:@"mailto:%@", email];
        NSURL *emailURL = [NSURL URLWithString:emailString];
        if ([[UIApplication sharedApplication] canOpenURL:emailURL]) {
            [[UIApplication sharedApplication] openURL:emailURL options:@{} completionHandler:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"Tip")
                                                                           message:WFCString(@"DeviceNotSupportEmail")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:WFCString(@"Ok") style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:okAction];
            [topVC presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (UIViewController *)topViewController {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootVC = keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    if ([rootVC isKindOfClass:[UINavigationController class]]) {
        return [(UINavigationController *)rootVC visibleViewController];
    }
    return rootVC;
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    UIViewController *topVC = [self topViewController];
    [topVC dismissViewControllerAnimated:YES completion:nil];
}

@end
