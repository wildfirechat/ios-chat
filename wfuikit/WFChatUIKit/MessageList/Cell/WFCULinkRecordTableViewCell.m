//
//  WFCULinkRecordTableViewCell.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/1/4.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCULinkRecordTableViewCell.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "WFCUImage.h"
#import "WFCUUtilities.h"

@interface WFCULinkRecordTableViewCell ()
@property(nonatomic, strong)UIImageView *portraitView;
@property(nonatomic, strong)UIImageView *thumbnailView;
@property(nonatomic, strong)UILabel *titleLabel;
@property(nonatomic, strong)UILabel *urlLabel;
@property(nonatomic, strong)UILabel *timeLabel;
@end

@implementation WFCULinkRecordTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 头像
    self.portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 12, 40, 40)];
    self.portraitView.layer.cornerRadius = 4;
    self.portraitView.layer.masksToBounds = YES;
    self.portraitView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    [self.contentView addSubview:self.portraitView];

    // 链接缩略图
    self.thumbnailView = [[UIImageView alloc] init];
    self.thumbnailView.layer.cornerRadius = 4;
    self.thumbnailView.layer.masksToBounds = YES;
    self.thumbnailView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
    self.thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:self.thumbnailView];

    // 链接标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.numberOfLines = 2;
    [self.contentView addSubview:self.titleLabel];

    // 链接URL
    self.urlLabel = [[UILabel alloc] init];
    self.urlLabel.font = [UIFont systemFontOfSize:14];
    self.urlLabel.textColor = [UIColor grayColor];
    self.urlLabel.numberOfLines = 1;
    [self.contentView addSubview:self.urlLabel];

    // 时间标签
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont systemFontOfSize:12];
    self.timeLabel.textColor = [UIColor lightGrayColor];
    [self.contentView addSubview:self.timeLabel];
}

- (void)setMessage:(WFCCMessage *)message {
    _message = message;

    WFCCLinkMessageContent *linkContent = (WFCCLinkMessageContent *)message.content;

    // 设置发送者头像
    WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:message.fromUser refresh:NO];
    if (sender.portrait.length) {
        [self.portraitView sd_setImageWithURL:[NSURL URLWithString:sender.portrait] placeholderImage:[WFCUImage imageNamed:@"PersonalChat"]];
    } else {
        self.portraitView.image = [WFCUImage imageNamed:@"PersonalChat"];
    }

    // 设置链接缩略图
    if (linkContent.thumbnailUrl.length) {
        [self.thumbnailView sd_setImageWithURL:[NSURL URLWithString:linkContent.thumbnailUrl] placeholderImage:[WFCUImage imageNamed:@"default_link"]];
    } else {
        self.thumbnailView.image = [WFCUImage imageNamed:@"default_link"];
    }

    // 设置标题
    self.titleLabel.text = linkContent.title;

    // 设置URL
    self.urlLabel.text = linkContent.url;

    // 设置时间
    self.timeLabel.text = [WFCUUtilities formatTimeLabel:message.serverTime];

    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat leftMargin = 16;
    CGFloat portraitSize = 40;
    CGFloat portraitRightMargin = 12;
    CGFloat rightMargin = 16;

    CGFloat portraitX = leftMargin;
    CGFloat portraitY = 12;

    CGFloat contentX = portraitX + portraitSize + portraitRightMargin;
    CGFloat contentWidth = self.bounds.size.width - contentX - rightMargin;

    // 头像位置
    self.portraitView.frame = CGRectMake(portraitX, portraitY, portraitSize, portraitSize);

    // 缩略图位置（左侧，较小）
    CGFloat thumbnailWidth = 60;
    CGFloat thumbnailHeight = 60;
    self.thumbnailView.frame = CGRectMake(contentX, 12, thumbnailWidth, thumbnailHeight);

    // 标题位置
    CGFloat titleX = contentX + thumbnailWidth + 8;
    CGFloat titleY = 12;
    CGFloat titleWidth = contentWidth - thumbnailWidth - 8;
    CGFloat titleHeight = 40;
    self.titleLabel.frame = CGRectMake(titleX, titleY, titleWidth, titleHeight);

    // URL位置
    CGFloat urlX = titleX;
    CGFloat urlY = titleY + titleHeight + 4;
    CGFloat urlWidth = titleWidth;
    CGFloat urlHeight = 20;
    self.urlLabel.frame = CGRectMake(urlX, urlY, urlWidth, urlHeight);

    // 时间位置（在头像下方）
    CGFloat timeX = portraitX;
    CGFloat timeY = portraitY + portraitSize + 4;
    CGFloat timeWidth = portraitSize;
    CGFloat timeHeight = 16;
    self.timeLabel.frame = CGRectMake(timeX, timeY, timeWidth, timeHeight);
}

+ (CGFloat)sizeOfMessage:(WFCCMessage *)msg withCellWidth:(CGFloat)width {
    return 88; // 头像40 + 边距12 + 缩略图高度60 + 底部边距16
}

@end
