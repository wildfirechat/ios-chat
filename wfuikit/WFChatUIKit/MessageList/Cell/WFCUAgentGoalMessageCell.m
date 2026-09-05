//
//  WFCUAgentGoalMessageCell.m
//  WFChatUIKit
//
//  Agent 目标进度卡片 Cell（206），纯展示。
//

#import "WFCUAgentGoalMessageCell.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatClient/WFCCAgentMessageContents.h>
#import "WFCUUtilities.h"
#import "WFCUAgentState.h"
#import "UIFont+YH.h"

#define AGENT_CARD_PADDING 12

@interface WFCUAgentGoalMessageCell ()
@property (nonatomic, strong)UILabel *titleLabel;
@property (nonatomic, strong)UILabel *phaseLabel;
@property (nonatomic, strong)UILabel *objectiveLabel;
@property (nonatomic, strong)UILabel *metaLabel;
@end

@implementation WFCUAgentGoalMessageCell

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCAgentGoalMessageContent *content = (WFCCAgentGoalMessageContent *)msgModel.message.content;
    CGFloat contentWidth = width - AGENT_CARD_PADDING * 2;
    CGFloat height = AGENT_CARD_PADDING;

    //标题行（含 phase 徽标）
    height += 20 + 8;

    CGSize objectiveSize = [WFCUUtilities getTextDrawingSize:content.objective ?: @""
                                                        font:[UIFont scaledSystemFontOfSize:14]
                                               constrainedSize:CGSizeMake(contentWidth, 200)];
    height += MAX(objectiveSize.height, 18) + 4;

    //已执行 N 轮
    height += 16 + AGENT_CARD_PADDING;
    return CGSizeMake(width, height);
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont scaledBoldSystemFontOfSize:14];
    self.titleLabel.textColor = [UIColor blackColor];
    [self.contentArea addSubview:self.titleLabel];

    self.phaseLabel = [[UILabel alloc] init];
    self.phaseLabel.font = [UIFont scaledSystemFontOfSize:10];
    self.phaseLabel.textColor = [UIColor whiteColor];
    self.phaseLabel.textAlignment = NSTextAlignmentCenter;
    self.phaseLabel.layer.cornerRadius = 8;
    self.phaseLabel.layer.masksToBounds = YES;
    [self.contentArea addSubview:self.phaseLabel];

    self.objectiveLabel = [[UILabel alloc] init];
    self.objectiveLabel.font = [UIFont scaledSystemFontOfSize:14];
    self.objectiveLabel.textColor = [UIColor blackColor];
    self.objectiveLabel.numberOfLines = 0;
    [self.contentArea addSubview:self.objectiveLabel];

    self.metaLabel = [[UILabel alloc] init];
    self.metaLabel.font = [UIFont scaledSystemFontOfSize:12];
    self.metaLabel.textColor = [UIColor grayColor];
    [self.contentArea addSubview:self.metaLabel];
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];

    WFCCAgentGoalMessageContent *content = (WFCCAgentGoalMessageContent *)model.message.content;
    CGFloat width = self.contentArea.bounds.size.width;
    CGFloat contentWidth = width - AGENT_CARD_PADDING * 2;
    CGFloat currentY = AGENT_CARD_PADDING;

    self.titleLabel.text = @"🎯 目标进度";
    CGSize titleSize = [WFCUUtilities getTextDrawingSize:self.titleLabel.text
                                                    font:self.titleLabel.font
                                           constrainedSize:CGSizeMake(contentWidth, 20)];
    self.titleLabel.frame = CGRectMake(AGENT_CARD_PADDING, currentY, titleSize.width, 20);

    self.phaseLabel.text = [WFCUAgentState goalPhaseText:content.phase];
    self.phaseLabel.backgroundColor = [WFCUAgentState goalPhaseColor:content.phase];
    CGSize phaseSize = [WFCUUtilities getTextDrawingSize:self.phaseLabel.text
                                                    font:self.phaseLabel.font
                                           constrainedSize:CGSizeMake(contentWidth, 16)];
    self.phaseLabel.frame = CGRectMake(AGENT_CARD_PADDING + titleSize.width + 6, currentY + 2, phaseSize.width + 12, 16);
    currentY += 20 + 8;

    self.objectiveLabel.text = content.objective;
    CGSize objectiveSize = [WFCUUtilities getTextDrawingSize:content.objective ?: @""
                                                        font:self.objectiveLabel.font
                                               constrainedSize:CGSizeMake(contentWidth, 200)];
    self.objectiveLabel.frame = CGRectMake(AGENT_CARD_PADDING, currentY, contentWidth, MAX(objectiveSize.height, 18));
    currentY += MAX(objectiveSize.height, 18) + 4;

    //ver:2 目标带 stage 文本时追加展示（如 "已执行 2 轮 · 1/3"）
    NSString *meta = [NSString stringWithFormat:@"已执行 %d 轮", (int)content.roundsStarted];
    if (content.stage.length) {
        meta = [meta stringByAppendingFormat:@" · %@", content.stage];
    }
    self.metaLabel.text = meta;
    self.metaLabel.frame = CGRectMake(AGENT_CARD_PADDING, currentY, contentWidth, 16);
}

@end
