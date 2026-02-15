//
//  WFCUPollResultMessageCell.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCUPollResultMessageCell.h"
#import <WFChatClient/WFCCPollResultMessageContent.h>
#import "WFCUUtilities.h"

@interface WFCUPollResultMessageCell ()
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *winnerLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@end

@implementation WFCUPollResultMessageCell

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    return CGSizeMake(width, 100);
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
    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.layer.cornerRadius = 8;
    self.containerView.clipsToBounds = YES;
    [self.contentArea addSubview:self.containerView];
    
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [self.containerView addSubview:self.titleLabel];
    
    // 获胜选项
    self.winnerLabel = [[UILabel alloc] init];
    self.winnerLabel.font = [UIFont systemFontOfSize:13];
    self.winnerLabel.textColor = [UIColor systemBlueColor];
    [self.containerView addSubview:self.winnerLabel];
    
    // 统计信息
    self.infoLabel = [[UILabel alloc] init];
    self.infoLabel.font = [UIFont systemFontOfSize:11];
    self.infoLabel.textColor = [UIColor blackColor];
    [self.containerView addSubview:self.infoLabel];
    
    // 添加点击手势（只需添加一次）
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.contentArea addGestureRecognizer:tapGesture];
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    WFCCPollResultMessageContent *content = (WFCCPollResultMessageContent *)model.message.content;
    CGFloat width = self.contentArea.bounds.size.width;
    CGFloat contentWidth = width - 24;
    
    // 容器
    self.containerView.frame = CGRectMake(0, 0, width, self.contentArea.bounds.size.height);
    
    // 标题
    self.titleLabel.text = [NSString stringWithFormat:@"📊 %@", content.title];
    self.titleLabel.frame = CGRectMake(12, 12, contentWidth, 20);
    
    // 获胜选项
    NSString *winnerText = [content.winningOptionTexts componentsJoinedByString:@"、"];
    self.winnerLabel.text = [NSString stringWithFormat:@"🏆 %@: %@", WFCString(@"Winner"), winnerText];
    self.winnerLabel.frame = CGRectMake(12, 40, contentWidth, 20);
    
    // 统计信息（使用 voterCount 显示实际参与人数）
    self.infoLabel.text = [NSString stringWithFormat:WFCString(@"PollResultInfo"), content.voterCount];
    self.infoLabel.frame = CGRectMake(12, 68, contentWidth, 16);
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:withModel:)]) {
        [self.delegate didTapMessageCell:self withModel:self.model];
    }
}

@end
