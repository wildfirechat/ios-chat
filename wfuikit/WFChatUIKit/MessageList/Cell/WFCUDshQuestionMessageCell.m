//
//  WFCUDshQuestionMessageCell.m
//  WFChatUIKit
//
//  DSH 提问卡片 Cell（200）。
//  选项垂直排列、整行可点；单选点击即答并立即本地置灰；多选勾选+底部"提交"按钮；
//  "自定义回答"聚焦会话主输入框（卡片内不嵌输入框）；
//  plan-review 显示"查看计划"按钮，intent.approve 命中的选项渲染为主色主按钮。
//

#import "WFCUDshQuestionMessageCell.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatClient/WFCCDshMessageContents.h>
#import "WFCUUtilities.h"
#import "WFCUDshState.h"
#import "WFCUConfigManager.h"
#import "UIFont+YH.h"

#define DSH_CARD_PADDING 12
#define DSH_OPTION_ROW_HEIGHT 40
#define DSH_OPTION_SPACING 6

@interface WFCUDshQuestionMessageCell ()
@property (nonatomic, strong)NSMutableArray<UIView *> *dynamicViews;
//选项按钮元数据，tag 为下标：@{questionId, label, multiSelect}
@property (nonatomic, strong)NSMutableArray<NSDictionary *> *optionMeta;
//questionId -> 已选 label 集合（多选）
@property (nonatomic, strong)NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *localSelected;
@property (nonatomic, assign)BOOL locallyAnswered;
@property (nonatomic, strong)UIButton *submitButton;
@end

@implementation WFCUDshQuestionMessageCell

+ (BOOL)isPlanReview:(NSDictionary *)question {
    NSDictionary *intent = question[@"intent"];
    return [intent isKindOfClass:[NSDictionary class]] && [intent[@"kind"] isEqualToString:@"plan-review"];
}

+ (NSArray<NSDictionary *> *)optionsOf:(NSDictionary *)question {
    NSArray *options = question[@"options"];
    return [options isKindOfClass:[NSArray class]] ? options : @[];
}

+ (NSString *)stringOf:(NSDictionary *)dict key:(NSString *)key {
    NSString *value = dict[key];
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCDshQuestionMessageContent *content = (WFCCDshQuestionMessageContent *)msgModel.message.content;
    CGFloat contentWidth = width - DSH_CARD_PADDING * 2;
    CGFloat height = DSH_CARD_PADDING;
    BOOL locked = [content.state isEqualToString:@"answered"] || [content.state isEqualToString:@"expired"];

    NSDictionary *first = content.questions.firstObject;
    NSString *header = [self stringOf:first key:@"header"];
    if (header.length) {
        height += 20 + 8;
    }

    BOOL hasMulti = NO;
    int qi = 0;
    for (NSDictionary *question in content.questions) {
        if (![question isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *title = [NSString stringWithFormat:@"%d. %@", qi + 1, [self stringOf:question key:@"question"] ?: @""];
        CGSize titleSize = [WFCUUtilities getTextDrawingSize:title
                                                        font:[UIFont scaledSystemFontOfSize:14]
                                               constrainedSize:CGSizeMake(contentWidth, 400)];
        height += MAX(titleSize.height, 18) + 4;

        NSString *detail = [self stringOf:question key:@"detail"];
        BOOL planReview = [self isPlanReview:question];
        if (detail.length && !planReview) {
            CGSize detailSize = [WFCUUtilities getTextDrawingSize:detail
                                                             font:[UIFont scaledSystemFontOfSize:12]
                                                    constrainedSize:CGSizeMake(contentWidth, 200)];
            height += detailSize.height + 4;
        }
        if (planReview && detail.length && !locked) {
            //"查看计划"按钮
            height += 36 + DSH_OPTION_SPACING;
        }

        NSArray *options = [self optionsOf:question];
        if ([question[@"multiSelect"] boolValue]) {
            hasMulti = YES;
        }
        if (!locked && options.count) {
            if (planReview) {
                //主/次按钮一行
                height += DSH_OPTION_ROW_HEIGHT + DSH_OPTION_SPACING;
            } else {
                height += options.count * (DSH_OPTION_ROW_HEIGHT + DSH_OPTION_SPACING);
            }
        }
        height += 4;
        qi++;
    }

    if (locked) {
        //状态行
        height += 16;
    } else {
        if (hasMulti) {
            height += DSH_OPTION_ROW_HEIGHT + DSH_OPTION_SPACING;
        }
        //"自定义回答"按钮
        height += DSH_OPTION_ROW_HEIGHT;
    }
    height += DSH_CARD_PADDING;
    return CGSizeMake(width, height);
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.dynamicViews = [NSMutableArray array];
        self.optionMeta = [NSMutableArray array];
        self.localSelected = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDshAnswered:) name:WFCUDshAnsweredNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onDshAnswered:(NSNotification *)notification {
    WFCCDshQuestionMessageContent *content = (WFCCDshQuestionMessageContent *)self.model.message.content;
    if (![content isKindOfClass:[WFCCDshQuestionMessageContent class]]) {
        return;
    }
    NSString *qid = notification.userInfo[@"qid"];
    if (qid.length && [qid isEqualToString:content.qid] && ![self isLocked]) {
        self.locallyAnswered = YES;
        [self rebuild];
    }
}

- (BOOL)isLocked {
    WFCCDshQuestionMessageContent *content = (WFCCDshQuestionMessageContent *)self.model.message.content;
    return self.locallyAnswered || [content.state isEqualToString:@"answered"] || [content.state isEqualToString:@"expired"];
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    self.locallyAnswered = NO;
    [self.localSelected removeAllObjects];
    [self rebuild];
}

- (UIView *)addView:(UIView *)view {
    [self.contentArea addSubview:view];
    [self.dynamicViews addObject:view];
    return view;
}

- (UILabel *)makeLabel:(UIFont *)font color:(UIColor *)color lines:(NSInteger)lines {
    UILabel *label = [[UILabel alloc] init];
    label.font = font;
    label.textColor = color;
    label.numberOfLines = lines;
    return label;
}

- (UIButton *)makeButton:(NSString *)title primary:(BOOL)primary {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont scaledSystemFontOfSize:14];
    button.layer.cornerRadius = 6;
    button.clipsToBounds = YES;
    if (primary) {
        button.backgroundColor = [WFCUDshState accentColor];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        button.backgroundColor = [UIColor clearColor];
        button.layer.borderWidth = 1;
        button.layer.borderColor = [WFCUDshState accentColor].CGColor;
        [button setTitleColor:[WFCUDshState accentColor] forState:UIControlStateNormal];
    }
    return button;
}

- (void)rebuild {
    for (UIView *view in self.dynamicViews) {
        [view removeFromSuperview];
    }
    [self.dynamicViews removeAllObjects];
    [self.optionMeta removeAllObjects];
    self.submitButton = nil;

    WFCCDshQuestionMessageContent *content = (WFCCDshQuestionMessageContent *)self.model.message.content;
    if (![content isKindOfClass:[WFCCDshQuestionMessageContent class]]) {
        return;
    }
    CGFloat width = self.contentArea.bounds.size.width;
    CGFloat contentWidth = width - DSH_CARD_PADDING * 2;
    CGFloat currentY = DSH_CARD_PADDING;
    BOOL locked = [self isLocked];

    NSDictionary *first = content.questions.firstObject;
    NSString *header = [[self class] stringOf:first key:@"header"];
    if (header.length) {
        UILabel *headerLabel = [self makeLabel:[UIFont scaledBoldSystemFontOfSize:14] color:[UIColor blackColor] lines:1];
        headerLabel.text = [NSString stringWithFormat:@"【%@】", header];
        headerLabel.frame = CGRectMake(DSH_CARD_PADDING, currentY, contentWidth, 20);
        [self addView:headerLabel];
        currentY += 20 + 8;
    }

    BOOL hasMulti = NO;
    int qi = 0;
    for (NSDictionary *question in content.questions) {
        if (![question isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *questionId = [[self class] stringOf:question key:@"id"] ?: @"";
        NSString *title = [NSString stringWithFormat:@"%d. %@", qi + 1, [[self class] stringOf:question key:@"question"] ?: @""];
        UILabel *titleLabel = [self makeLabel:[UIFont scaledSystemFontOfSize:14] color:[UIColor blackColor] lines:0];
        titleLabel.text = title;
        CGSize titleSize = [WFCUUtilities getTextDrawingSize:title
                                                        font:titleLabel.font
                                               constrainedSize:CGSizeMake(contentWidth, 400)];
        titleLabel.frame = CGRectMake(DSH_CARD_PADDING, currentY, contentWidth, MAX(titleSize.height, 18));
        [self addView:titleLabel];
        currentY += MAX(titleSize.height, 18) + 4;

        NSString *detail = [[self class] stringOf:question key:@"detail"];
        BOOL planReview = [[self class] isPlanReview:question];
        if (detail.length && !planReview) {
            UILabel *detailLabel = [self makeLabel:[UIFont scaledSystemFontOfSize:12] color:[UIColor grayColor] lines:0];
            detailLabel.text = detail;
            CGSize detailSize = [WFCUUtilities getTextDrawingSize:detail
                                                             font:detailLabel.font
                                                    constrainedSize:CGSizeMake(contentWidth, 200)];
            detailLabel.frame = CGRectMake(DSH_CARD_PADDING, currentY, contentWidth, detailSize.height);
            [self addView:detailLabel];
            currentY += detailSize.height + 4;
        }
        if (planReview && detail.length && !locked) {
            UIButton *planButton = [self makeButton:@"查看计划" primary:NO];
            planButton.frame = CGRectMake(DSH_CARD_PADDING, currentY, contentWidth, 36);
            planButton.tag = qi;
            [planButton addTarget:self action:@selector(onShowPlan:) forControlEvents:UIControlEventTouchUpInside];
            [self addView:planButton];
            currentY += 36 + DSH_OPTION_SPACING;
        }

        NSArray *options = [[self class] optionsOf:question];
        BOOL multiSelect = [question[@"multiSelect"] boolValue];
        if (multiSelect) {
            hasMulti = YES;
        }
        if (!locked && options.count) {
            if (planReview) {
                //intent.approve 命中的选项渲染为主色主按钮（点击即答），其余为次按钮
                NSDictionary *intent = question[@"intent"];
                NSString *approveLabel = [[self class] stringOf:intent key:@"approve"];
                CGFloat btnWidth = (contentWidth - (options.count - 1) * 8) / options.count;
                CGFloat btnX = DSH_CARD_PADDING;
                for (NSDictionary *option in options) {
                    NSString *label = [[self class] stringOf:option key:@"label"] ?: @"";
                    BOOL isApprove = approveLabel.length && [label isEqualToString:approveLabel];
                    UIButton *button = [self makeButton:label primary:isApprove];
                    button.frame = CGRectMake(btnX, currentY, btnWidth, DSH_OPTION_ROW_HEIGHT);
                    button.tag = self.optionMeta.count;
                    [button addTarget:self action:@selector(onOptionTapped:) forControlEvents:UIControlEventTouchUpInside];
                    [self addView:button];
                    [self.optionMeta addObject:@{@"questionId": questionId, @"label": label, @"multiSelect": @(NO)}];
                    btnX += btnWidth + 8;
                }
                currentY += DSH_OPTION_ROW_HEIGHT + DSH_OPTION_SPACING;
            } else {
                for (NSDictionary *option in options) {
                    NSString *label = [[self class] stringOf:option key:@"label"] ?: @"";
                    UIButton *button = [self makeButton:label primary:NO];
                    button.frame = CGRectMake(DSH_CARD_PADDING, currentY, contentWidth, DSH_OPTION_ROW_HEIGHT);
                    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                    button.contentEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
                    button.tag = self.optionMeta.count;
                    [button addTarget:self action:@selector(onOptionTapped:) forControlEvents:UIControlEventTouchUpInside];
                    [self addView:button];
                    [self.optionMeta addObject:@{@"questionId": questionId, @"label": label, @"multiSelect": @(multiSelect)}];
                    if (multiSelect && [self.localSelected[questionId] containsObject:label]) {
                        button.backgroundColor = [[WFCUDshState accentColor] colorWithAlphaComponent:0.12];
                    }
                    currentY += DSH_OPTION_ROW_HEIGHT + DSH_OPTION_SPACING;
                }
            }
        }
        currentY += 4;
        qi++;
    }

    if (locked) {
        UILabel *stateLabel = [self makeLabel:[UIFont scaledSystemFontOfSize:12] color:[UIColor grayColor] lines:1];
        stateLabel.text = [content.state isEqualToString:@"expired"] && !self.locallyAnswered ? @"已过期" : @"已作答";
        stateLabel.frame = CGRectMake(DSH_CARD_PADDING, currentY, contentWidth, 16);
        [self addView:stateLabel];
    } else {
        if (hasMulti) {
            NSUInteger selectedCount = 0;
            for (NSSet *set in self.localSelected.allValues) {
                selectedCount += set.count;
            }
            UIButton *submitButton = [self makeButton:@"提交" primary:YES];
            submitButton.frame = CGRectMake(DSH_CARD_PADDING, currentY, contentWidth, DSH_OPTION_ROW_HEIGHT);
            submitButton.enabled = selectedCount > 0;
            submitButton.alpha = selectedCount > 0 ? 1.0 : 0.5;
            [submitButton addTarget:self action:@selector(onSubmit) forControlEvents:UIControlEventTouchUpInside];
            [self addView:submitButton];
            self.submitButton = submitButton;
            currentY += DSH_OPTION_ROW_HEIGHT + DSH_OPTION_SPACING;
        }
        UIButton *customButton = [self makeButton:@"自定义回答" primary:NO];
        customButton.frame = CGRectMake(DSH_CARD_PADDING, currentY, contentWidth, DSH_OPTION_ROW_HEIGHT);
        [customButton addTarget:self action:@selector(onCustomAnswer) forControlEvents:UIControlEventTouchUpInside];
        [self addView:customButton];
    }
}

- (void)onOptionTapped:(UIButton *)button {
    if ([self isLocked] || button.tag >= self.optionMeta.count) {
        return;
    }
    NSDictionary *meta = self.optionMeta[button.tag];
    NSString *questionId = meta[@"questionId"];
    NSString *label = meta[@"label"];
    if ([meta[@"multiSelect"] boolValue]) {
        NSMutableSet *selected = self.localSelected[questionId];
        if (!selected) {
            selected = [NSMutableSet set];
            self.localSelected[questionId] = selected;
        }
        if ([selected containsObject:label]) {
            [selected removeObject:label];
        } else {
            [selected addObject:label];
        }
        [self rebuild];
    } else {
        //单选点击即答
        [self sendAnswers:@[@{@"id": questionId, @"selected": @[label]}]];
    }
}

- (void)onSubmit {
    if ([self isLocked]) {
        return;
    }
    WFCCDshQuestionMessageContent *content = (WFCCDshQuestionMessageContent *)self.model.message.content;
    NSMutableArray *answers = [NSMutableArray array];
    for (NSDictionary *question in content.questions) {
        if (![question isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *questionId = [[self class] stringOf:question key:@"id"] ?: @"";
        NSSet *selected = self.localSelected[questionId];
        if (selected.count) {
            [answers addObject:@{@"id": questionId, @"selected": selected.allObjects}];
        }
    }
    if (answers.count) {
        [self sendAnswers:answers];
    }
}

- (void)onCustomAnswer {
    //卡片内不嵌输入框：聚焦会话主输入框并弹键盘，用户直接发的文本会被服务端当作该卡片的自定义回答
    [[NSNotificationCenter defaultCenter] postNotificationName:WFCUDshFocusInputNotification object:self.model.message.conversation];
}

- (void)onShowPlan:(UIButton *)button {
    WFCCDshQuestionMessageContent *content = (WFCCDshQuestionMessageContent *)self.model.message.content;
    if (button.tag >= content.questions.count) {
        return;
    }
    NSDictionary *question = content.questions[button.tag];
    NSString *detail = [[self class] stringOf:question key:@"detail"];
    if (!detail.length) {
        return;
    }
    NSDictionary *intent = question[@"intent"];
    NSString *approveLabel = [[self class] stringOf:intent key:@"approve"];
    NSString *rejectLabel = nil;
    for (NSDictionary *option in [[self class] optionsOf:question]) {
        NSString *label = [[self class] stringOf:option key:@"label"];
        if (label.length && ![label isEqualToString:approveLabel]) {
            rejectLabel = label;
            break;
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:WFCUDshShowPlanDetailNotification
                                                        object:nil
                                                      userInfo:@{@"conversation": self.model.message.conversation,
                                                                 @"qid": content.qid ?: @"",
                                                                 @"questionId": [[self class] stringOf:question key:@"id"] ?: @"",
                                                                 @"plan": detail,
                                                                 @"approveLabel": approveLabel ?: @"批准",
                                                                 @"rejectLabel": rejectLabel ?: @"拒绝"}];
}

- (void)sendAnswers:(NSArray<NSDictionary *> *)answers {
    if ([self isLocked]) {
        return;
    }
    WFCCDshQuestionMessageContent *content = (WFCCDshQuestionMessageContent *)self.model.message.content;
    WFCCDshAnswerMessageContent *answer = [[WFCCDshAnswerMessageContent alloc] init];
    answer.qid = content.qid;
    answer.answers = answers;
    [[WFCCIMService sharedWFCIMService] send:self.model.message.conversation content:answer success:nil error:nil];

    //立即本地置灰（不依赖服务端推送实时性）
    self.locallyAnswered = YES;
    [self rebuild];
    [[NSNotificationCenter defaultCenter] postNotificationName:WFCUDshAnsweredNotification object:nil userInfo:@{@"qid": content.qid ?: @""}];
}

@end
