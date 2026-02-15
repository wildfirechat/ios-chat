//
//  WFCUPollMessageCell.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCUPollMessageCell.h"
#import <WFChatClient/WFCCPollMessageContent.h>
#import "WFCUUtilities.h"

@interface WFCUPollMessageCell ()
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UILabel *actionLabel;
@end

@implementation WFCUPollMessageCell

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCPollMessageContent *content = (WFCCPollMessageContent *)msgModel.message.content;
    
    CGFloat height = 0;
    CGFloat contentWidth = width - 24; // 左右各12padding
    
    // 标题高度
    NSString *title = [NSString stringWithFormat:@"🗳️ %@", content.title];
    CGSize titleSize = [WFCUUtilities getTextDrawingSize:title
                                                    font:[UIFont boldSystemFontOfSize:14]
                                           constrainedSize:CGSizeMake(contentWidth, 40)];
    height += MAX(titleSize.height, 20) + 8;
    
    // 描述高度
    if (content.desc.length > 0) {
        CGSize descSize = [WFCUUtilities getTextDrawingSize:content.desc
                                                       font:[UIFont systemFontOfSize:12]
                                              constrainedSize:CGSizeMake(contentWidth, 60)];
        height += descSize.height + 4;
    }
    
    // 信息行
    height += 16 + 4;
    
    // 操作按钮
    height += 16 + 12;
    
    return CGSizeMake(width, MAX(height, 100));
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 容器
    self.containerView = [[UIView alloc] init];
    self.containerView.layer.cornerRadius = 8;
    self.containerView.clipsToBounds = YES;
    [self.contentArea addSubview:self.containerView];
    
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    self.titleLabel.numberOfLines = 2;
    [self.containerView addSubview:self.titleLabel];
    
    // 描述
    self.descLabel = [[UILabel alloc] init];
    self.descLabel.font = [UIFont systemFontOfSize:12];
    self.descLabel.textColor = [UIColor blackColor];
    self.descLabel.numberOfLines = 2;
    [self.containerView addSubview:self.descLabel];
    
    // 信息
    self.infoLabel = [[UILabel alloc] init];
    self.infoLabel.font = [UIFont systemFontOfSize:11];
    self.infoLabel.textColor = [UIColor blackColor];
    [self.containerView addSubview:self.infoLabel];
    
    // 操作按钮
    self.actionLabel = [[UILabel alloc] init];
    self.actionLabel.font = [UIFont systemFontOfSize:12];
    self.actionLabel.textColor = [UIColor systemBlueColor];
    [self.containerView addSubview:self.actionLabel];
    
    // 添加点击手势（只需添加一次）
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.contentArea addGestureRecognizer:tapGesture];
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    WFCCPollMessageContent *content = (WFCCPollMessageContent *)model.message.content;
    CGFloat width = self.contentArea.bounds.size.width;
    CGFloat contentWidth = width - 24;
    CGFloat currentY = 12;
    
    // 容器
    self.containerView.frame = CGRectMake(0, 0, width, self.contentArea.bounds.size.height);
    
    // 标题
    self.titleLabel.text = [NSString stringWithFormat:@"🗳️ %@", content.title];
    CGSize titleSize = [WFCUUtilities getTextDrawingSize:self.titleLabel.text
                                                    font:self.titleLabel.font
                                           constrainedSize:CGSizeMake(contentWidth, 40)];
    self.titleLabel.frame = CGRectMake(12, currentY, contentWidth, MAX(titleSize.height, 20));
    currentY += MAX(titleSize.height, 20) + 8;
    
    // 描述
    if (content.desc.length > 0) {
        self.descLabel.text = content.desc;
        CGSize descSize = [WFCUUtilities getTextDrawingSize:content.desc
                                                       font:self.descLabel.font
                                              constrainedSize:CGSizeMake(contentWidth, 60)];
        self.descLabel.frame = CGRectMake(12, currentY, contentWidth, descSize.height);
        self.descLabel.hidden = NO;
        currentY += descSize.height + 4;
    } else {
        self.descLabel.hidden = YES;
    }
    
    // 信息行（根据消息时间和endTime判断状态，不显示参与人数）
    NSString *statusText;
    if (content.endTime > 0 && content.endTime < model.message.serverTime) {
        statusText = WFCString(@"PollStatusEnded");
    } else if (content.status == 1) {
        statusText = WFCString(@"PollStatusEnded");
    } else {
        statusText = WFCString(@"PollInProgress");
    }
    NSString *typeText = content.anonymous == 1 ? WFCString(@"AnonymousPoll") : WFCString(@"NamedPoll");
    self.infoLabel.text = [NSString stringWithFormat:@"%@ · %@", statusText, typeText];
    self.infoLabel.frame = CGRectMake(12, currentY, contentWidth, 16);
    currentY += 16 + 4;
    
    // 操作按钮
    self.actionLabel.text = WFCString(@"ClickToVote");
    self.actionLabel.frame = CGRectMake(12, currentY, contentWidth, 16);
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:withModel:)]) {
        [self.delegate didTapMessageCell:self withModel:self.model];
    }
}

@end
