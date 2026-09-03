//
//  WFCUDshApprovalMessageCell.m
//  WFChatUIKit
//
//  DSH 工具审批卡片 Cell（202）。点击同意/拒绝发送 DSH_ApprovalResult 并立即本地置灰。
//

#import "WFCUDshApprovalMessageCell.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatClient/WFCCDshMessageContents.h>
#import "WFCUUtilities.h"
#import "WFCUDshState.h"
#import "WFCUConfigManager.h"
#import "UIFont+YH.h"

#define DSH_CARD_PADDING 12

@interface WFCUAgentApprovalMessageCell ()
@property (nonatomic, strong)UILabel *titleLabel;
@property (nonatomic, strong)UILabel *toolLabel;
@property (nonatomic, strong)UILabel *reasonLabel;
@property (nonatomic, strong)UIButton *approveButton;
@property (nonatomic, strong)UIButton *rejectButton;
@property (nonatomic, strong)UILabel *stateLabel;
@property (nonatomic, assign)BOOL locallyDecided;
@property (nonatomic, strong)NSString *localAction;
@end

@implementation WFCUAgentApprovalMessageCell

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCAgentApprovalMessageContent *content = (WFCCAgentApprovalMessageContent *)msgModel.message.content;
    CGFloat contentWidth = width - DSH_CARD_PADDING * 2;
    CGFloat height = DSH_CARD_PADDING;

    //标题
    height += 20 + 6;
    //工具名（等宽）
    height += 18 + 4;
    //原因
    if (content.reason.length) {
        CGSize reasonSize = [WFCUUtilities getTextDrawingSize:[NSString stringWithFormat:@"原因：%@", content.reason]
                                                         font:[UIFont scaledSystemFontOfSize:12]
                                                constrainedSize:CGSizeMake(contentWidth, 200)];
        height += reasonSize.height + 4;
    }
    //按钮区/状态行
    height += 40 + DSH_CARD_PADDING;
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

    self.toolLabel = [[UILabel alloc] init];
    self.toolLabel.font = [UIFont monospacedSystemFontOfSize:[WFCUConfigManager scaledSize:14] weight:UIFontWeightRegular];
    self.toolLabel.textColor = [UIColor blackColor];
    [self.contentArea addSubview:self.toolLabel];

    self.reasonLabel = [[UILabel alloc] init];
    self.reasonLabel.font = [UIFont scaledSystemFontOfSize:12];
    self.reasonLabel.textColor = [UIColor grayColor];
    self.reasonLabel.numberOfLines = 0;
    [self.contentArea addSubview:self.reasonLabel];

    self.approveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.approveButton setTitle:@"同意" forState:UIControlStateNormal];
    [self.approveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.approveButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15];
    self.approveButton.backgroundColor = [WFCUAgentState accentColor];
    self.approveButton.layer.cornerRadius = 6;
    [self.approveButton addTarget:self action:@selector(onApprove) forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:self.approveButton];

    self.rejectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rejectButton setTitle:@"拒绝" forState:UIControlStateNormal];
    [self.rejectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.rejectButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15];
    self.rejectButton.backgroundColor = [UIColor redColor];
    self.rejectButton.layer.cornerRadius = 6;
    [self.rejectButton addTarget:self action:@selector(onReject) forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:self.rejectButton];

    self.stateLabel = [[UILabel alloc] init];
    self.stateLabel.font = [UIFont scaledSystemFontOfSize:12];
    self.stateLabel.textColor = [UIColor grayColor];
    [self.contentArea addSubview:self.stateLabel];
}

- (BOOL)isLocked {
    WFCCAgentApprovalMessageContent *content = (WFCCAgentApprovalMessageContent *)self.model.message.content;
    return self.locallyDecided || [content.state isEqualToString:@"approved"] || [content.state isEqualToString:@"rejected"] || [content.state isEqualToString:@"expired"];
}

- (NSString *)stateText {
    WFCCAgentApprovalMessageContent *content = (WFCCAgentApprovalMessageContent *)self.model.message.content;
    if ([content.state isEqualToString:@"rejected"]) {
        return @"已拒绝";
    }
    if ([content.state isEqualToString:@"expired"]) {
        return @"已过期";
    }
    //approved 或本地已点同意/拒绝，先按本地动作显示
    return self.localAction.length ? self.localAction : @"已同意";
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    self.locallyDecided = NO;
    self.localAction = nil;

    WFCCAgentApprovalMessageContent *content = (WFCCAgentApprovalMessageContent *)model.message.content;
    CGFloat width = self.contentArea.bounds.size.width;
    CGFloat contentWidth = width - DSH_CARD_PADDING * 2;
    CGFloat currentY = DSH_CARD_PADDING;

    self.titleLabel.text = @"🔐 工具审批";
    self.titleLabel.frame = CGRectMake(DSH_CARD_PADDING, currentY, contentWidth, 20);
    currentY += 20 + 6;

    self.toolLabel.text = content.toolName;
    self.toolLabel.frame = CGRectMake(DSH_CARD_PADDING, currentY, contentWidth, 18);
    currentY += 18 + 4;

    if (content.reason.length) {
        self.reasonLabel.hidden = NO;
        self.reasonLabel.text = [NSString stringWithFormat:@"原因：%@", content.reason];
        CGSize reasonSize = [WFCUUtilities getTextDrawingSize:self.reasonLabel.text
                                                         font:self.reasonLabel.font
                                                constrainedSize:CGSizeMake(contentWidth, 200)];
        self.reasonLabel.frame = CGRectMake(DSH_CARD_PADDING, currentY, contentWidth, reasonSize.height);
        currentY += reasonSize.height + 4;
    } else {
        self.reasonLabel.hidden = YES;
    }

    BOOL locked = [self isLocked];
    self.approveButton.hidden = locked;
    self.rejectButton.hidden = locked;
    self.stateLabel.hidden = !locked;
    if (locked) {
        self.stateLabel.text = [self stateText];
        self.stateLabel.frame = CGRectMake(DSH_CARD_PADDING, currentY + 12, contentWidth, 16);
    } else {
        CGFloat btnWidth = (contentWidth - 8) / 2.0;
        self.approveButton.frame = CGRectMake(DSH_CARD_PADDING, currentY, btnWidth, 40);
        self.rejectButton.frame = CGRectMake(DSH_CARD_PADDING + btnWidth + 8, currentY, btnWidth, 40);
    }
}

- (void)decide:(NSString *)action stateText:(NSString *)stateText {
    if ([self isLocked]) {
        return;
    }
    WFCCAgentApprovalMessageContent *content = (WFCCAgentApprovalMessageContent *)self.model.message.content;
    WFCCAgentApprovalResultMessageContent *result = [[WFCCAgentApprovalResultMessageContent alloc] init];
    result.aid = content.aid;
    result.action = action;
    [[WFCCIMService sharedWFCIMService] send:self.model.message.conversation content:result success:nil error:nil];

    //立即本地置灰（不依赖服务端推送实时性）
    self.locallyDecided = YES;
    self.localAction = stateText;
    CGFloat width = self.contentArea.bounds.size.width;
    self.approveButton.hidden = YES;
    self.rejectButton.hidden = YES;
    self.stateLabel.hidden = NO;
    self.stateLabel.text = stateText;
    self.stateLabel.frame = CGRectMake(DSH_CARD_PADDING, self.contentArea.bounds.size.height - DSH_CARD_PADDING - 16 - 12, width - DSH_CARD_PADDING * 2, 16);
}

- (void)onApprove {
    [self decide:@"approve" stateText:@"已同意"];
}

- (void)onReject {
    [self decide:@"reject" stateText:@"已拒绝"];
}

@end
