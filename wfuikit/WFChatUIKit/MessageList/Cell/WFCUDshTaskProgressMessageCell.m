//
//  WFCUDshTaskProgressMessageCell.m
//  WFChatUIKit
//
//  DSH 任务进度卡片 Cell（208），纯展示。
//  渲染：标题"🧩 任务进度" + 摘要角标（共 N 个 · M 运行中 / 全部完成 / N 失败），
//  任务列表每行 = 状态图标 + 标签（label 或 id 短前缀）+ 状态文字（失败附原因）；
//  空任务显示"暂无任务"。插件以 sendCard 首推、updateMessage 原地更新。
//

#import "WFCUDshTaskProgressMessageCell.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatClient/WFCCDshMessageContents.h>
#import "WFCUUtilities.h"
#import "WFCUDshState.h"
#import "UIFont+YH.h"

#define DSH_CARD_PADDING 12
#define DSH_TASK_ICON_WIDTH 24
#define DSH_TASK_ROW_GAP 8

@interface WFCUAgentTaskProgressMessageCell ()
@property (nonatomic, strong)NSMutableArray<UIView *> *dynamicViews;
@end

@implementation WFCUAgentTaskProgressMessageCell

//状态图标：与 PC 端 statusIcon 一致
+ (NSString *)statusIcon:(NSString *)status {
    static NSDictionary<NSString *, NSString *> *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{@"running": @"⏳",
                @"done": @"✅",
                @"completed": @"✅",
                @"failed": @"❌",
                @"killed": @"⛔"};
    });
    return map[status] ?: @"⚪";
}

//状态文字：与 PC 端 statusText 一致
+ (NSString *)statusText:(NSString *)status {
    static NSDictionary<NSString *, NSString *> *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{@"running": @"运行中",
                @"done": @"已完成",
                @"completed": @"已完成",
                @"failed": @"失败",
                @"killed": @"已终止"};
    });
    return map[status] ?: (status.length ? status : @"");
}

//id 短前缀：长度 > 12 显示"子任务 + 后 8 位"，与 PC 端 shortId 一致
+ (NSString *)shortId:(NSString *)identifier {
    if (identifier.length > 12) {
        return [NSString stringWithFormat:@"子任务 %@", [identifier substringFromIndex:identifier.length - 8]];
    }
    return identifier.length ? identifier : @"子任务";
}

//任务标签：label 优先，否则 id 短前缀
+ (NSString *)labelOfTask:(NSDictionary *)task {
    NSString *label = task[@"label"];
    if ([label isKindOfClass:[NSString class]] && label.length) {
        return label;
    }
    NSString *identifier = task[@"id"];
    return [self shortId:[identifier isKindOfClass:[NSString class]] ? identifier : @""];
}

//任务状态行：状态文字 + （失败原因）
+ (NSString *)metaOfTask:(NSDictionary *)task {
    NSString *status = [task[@"status"] isKindOfClass:[NSString class]] ? task[@"status"] : @"";
    NSMutableString *meta = [NSMutableString stringWithString:[self statusText:status]];
    NSString *reason = task[@"reason"];
    if ([reason isKindOfClass:[NSString class]] && reason.length) {
        [meta appendFormat:@" · %@", reason];
    }
    return meta;
}

//摘要角标：running>0 → "共 N 个 · M 运行中"；否则 failed>0 → "共 N 个 · N 失败"；否则 "共 N 个 · 全部完成"
+ (NSString *)summaryText:(NSArray<NSDictionary *> *)tasks {
    NSInteger running = 0;
    NSInteger failed = 0;
    for (NSDictionary *task in tasks) {
        if (![task isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *status = task[@"status"];
        if ([status isEqualToString:@"running"]) {
            running++;
        } else if ([status isEqualToString:@"failed"]) {
            failed++;
        }
    }
    if (running > 0) {
        return [NSString stringWithFormat:@"共 %lu 个 · %ld 运行中", (unsigned long)tasks.count, (long)running];
    }
    if (failed > 0) {
        return [NSString stringWithFormat:@"共 %lu 个 · %ld 失败", (unsigned long)tasks.count, (long)failed];
    }
    return [NSString stringWithFormat:@"共 %lu 个 · 全部完成", (unsigned long)tasks.count];
}

//摘要角标是否放不下而需要换行到标题下一行（sizing 与 layout 共用同一判定，保证高度一致）
+ (BOOL)summaryBadgeWraps:(NSArray<NSDictionary *> *)tasks
                titleFont:(UIFont *)titleFont
                badgeFont:(UIFont *)badgeFont
              contentWidth:(CGFloat)contentWidth {
    if (![tasks isKindOfClass:[NSArray class]] || tasks.count == 0) {
        return NO;
    }
    NSString *title = @"🧩 任务进度";
    CGSize titleSize = [WFCUUtilities getTextDrawingSize:title
                                                    font:titleFont
                                           constrainedSize:CGSizeMake(contentWidth, 20)];
    NSString *summary = [self summaryText:tasks];
    CGSize badgeSize = [WFCUUtilities getTextDrawingSize:summary
                                                    font:badgeFont
                                           constrainedSize:CGSizeMake(contentWidth, 16)];
    CGFloat badgeX = DSH_CARD_PADDING + titleSize.width + 6;
    return badgeX + badgeSize.width + 12 > DSH_CARD_PADDING + contentWidth;
}

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCAgentTaskProgressMessageContent *content = (WFCCAgentTaskProgressMessageContent *)msgModel.message.content;
    CGFloat contentWidth = width - DSH_CARD_PADDING * 2;
    CGFloat height = DSH_CARD_PADDING;

    //标题行（含摘要角标）
    height += 20 + 8;
    if ([self summaryBadgeWraps:content.tasks
                      titleFont:[UIFont scaledBoldSystemFontOfSize:14]
                      badgeFont:[UIFont scaledSystemFontOfSize:10]
                   contentWidth:contentWidth]) {
        //角标换行：标题行 + 角标行
        height += 20 + 4;
    }

    NSArray *tasks = content.tasks;
    if (![tasks isKindOfClass:[NSArray class]] || tasks.count == 0) {
        //"暂无任务"
        height += 16 + DSH_CARD_PADDING;
        return CGSizeMake(width, height);
    }

    UIFont *labelFont = [UIFont scaledSystemFontOfSize:13];
    UIFont *metaFont = [UIFont scaledSystemFontOfSize:11];
    CGFloat rowTextWidth = contentWidth - DSH_TASK_ICON_WIDTH;
    for (NSDictionary *task in tasks) {
        if (![task isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *label = [self labelOfTask:task];
        CGSize labelSize = [WFCUUtilities getTextDrawingSize:label
                                                        font:labelFont
                                               constrainedSize:CGSizeMake(rowTextWidth, 200)];
        NSString *meta = [self metaOfTask:task];
        CGSize metaSize = [WFCUUtilities getTextDrawingSize:meta
                                                        font:metaFont
                                               constrainedSize:CGSizeMake(rowTextWidth, 40)];
        CGFloat rowHeight = MAX(labelSize.height, 18) + MAX(metaSize.height, 14) + 4;
        height += rowHeight + DSH_TASK_ROW_GAP;
    }
    height -= DSH_TASK_ROW_GAP; //最后一行无底部间距
    height += DSH_CARD_PADDING;
    return CGSizeMake(width, height);
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.dynamicViews = [NSMutableArray array];
    }
    return self;
}

- (UILabel *)makeLabel:(UIFont *)font color:(UIColor *)color lines:(NSInteger)lines {
    UILabel *label = [[UILabel alloc] init];
    label.font = font;
    label.textColor = color;
    label.numberOfLines = lines;
    return label;
}

- (void)addView:(UIView *)view {
    [self.contentArea addSubview:view];
    [self.dynamicViews addObject:view];
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];

    for (UIView *view in self.dynamicViews) {
        [view removeFromSuperview];
    }
    [self.dynamicViews removeAllObjects];

    WFCCAgentTaskProgressMessageContent *content = (WFCCAgentTaskProgressMessageContent *)model.message.content;
    if (![content isKindOfClass:[WFCCAgentTaskProgressMessageContent class]]) {
        return;
    }

    CGFloat width = self.contentArea.bounds.size.width;
    CGFloat contentWidth = width - DSH_CARD_PADDING * 2;
    CGFloat currentY = DSH_CARD_PADDING;

    //标题 + 摘要角标
    UILabel *titleLabel = [self makeLabel:[UIFont scaledBoldSystemFontOfSize:14] color:[UIColor blackColor] lines:1];
    titleLabel.text = @"🧩 任务进度";
    CGSize titleSize = [WFCUUtilities getTextDrawingSize:titleLabel.text
                                                    font:titleLabel.font
                                           constrainedSize:CGSizeMake(contentWidth, 20)];
    titleLabel.frame = CGRectMake(DSH_CARD_PADDING, currentY, titleSize.width, 20);
    [self addView:titleLabel];

    NSArray *tasks = content.tasks;
    BOOL badgeWraps = [[self class] summaryBadgeWraps:tasks
                                            titleFont:titleLabel.font
                                            badgeFont:[UIFont scaledSystemFontOfSize:10]
                                         contentWidth:contentWidth];
    if ([tasks isKindOfClass:[NSArray class]] && tasks.count && badgeWraps) {
        //角标独占下一行
        currentY += 20 + 4;
    }
    if ([tasks isKindOfClass:[NSArray class]] && tasks.count) {
        NSString *summary = [[self class] summaryText:tasks];
        UILabel *badgeLabel = [self makeLabel:[UIFont scaledSystemFontOfSize:10] color:[UIColor whiteColor] lines:1];
        badgeLabel.text = summary;
        badgeLabel.textAlignment = NSTextAlignmentCenter;
        badgeLabel.backgroundColor = [UIColor colorWithRed:0.31 green:0.56 blue:0.97 alpha:1.0]; // #4f8ff7
        badgeLabel.layer.cornerRadius = 8;
        badgeLabel.layer.masksToBounds = YES;
        CGSize badgeSize = [WFCUUtilities getTextDrawingSize:summary
                                                        font:badgeLabel.font
                                               constrainedSize:CGSizeMake(contentWidth, 16)];
        CGFloat badgeX = badgeWraps ? DSH_CARD_PADDING : DSH_CARD_PADDING + titleSize.width + 6;
        badgeLabel.frame = CGRectMake(badgeX, currentY + 2, badgeSize.width + 12, 16);
        [self addView:badgeLabel];
    }
    currentY += 20 + 8;

    if (![tasks isKindOfClass:[NSArray class]] || tasks.count == 0) {
        UILabel *emptyLabel = [self makeLabel:[UIFont scaledSystemFontOfSize:12] color:[UIColor grayColor] lines:1];
        emptyLabel.text = @"暂无任务";
        emptyLabel.frame = CGRectMake(DSH_CARD_PADDING, currentY, contentWidth, 16);
        [self addView:emptyLabel];
        return;
    }

    //任务列表
    UIFont *labelFont = [UIFont scaledSystemFontOfSize:13];
    UIFont *metaFont = [UIFont scaledSystemFontOfSize:11];
    CGFloat rowTextWidth = contentWidth - DSH_TASK_ICON_WIDTH;
    for (NSDictionary *task in tasks) {
        if (![task isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *status = [task[@"status"] isKindOfClass:[NSString class]] ? task[@"status"] : @"";

        //状态图标
        UILabel *iconLabel = [self makeLabel:[UIFont scaledSystemFontOfSize:14] color:[UIColor blackColor] lines:1];
        iconLabel.text = [[self class] statusIcon:status];
        iconLabel.frame = CGRectMake(DSH_CARD_PADDING, currentY, DSH_TASK_ICON_WIDTH, 18);

        //标签（label 或 id 短前缀）
        NSString *label = [[self class] labelOfTask:task];
        UILabel *labelLabel = [self makeLabel:labelFont color:[UIColor blackColor] lines:0];
        labelLabel.text = label;
        CGSize labelSize = [WFCUUtilities getTextDrawingSize:label
                                                        font:labelFont
                                               constrainedSize:CGSizeMake(rowTextWidth, 200)];
        labelLabel.frame = CGRectMake(DSH_CARD_PADDING + DSH_TASK_ICON_WIDTH, currentY, rowTextWidth, MAX(labelSize.height, 18));

        //状态文字（失败附原因）
        NSString *meta = [[self class] metaOfTask:task];
        UILabel *metaLabel = [self makeLabel:metaFont color:[UIColor grayColor] lines:1];
        metaLabel.text = meta;
        CGSize metaSize = [WFCUUtilities getTextDrawingSize:meta
                                                        font:metaFont
                                               constrainedSize:CGSizeMake(rowTextWidth, 40)];
        metaLabel.frame = CGRectMake(DSH_CARD_PADDING + DSH_TASK_ICON_WIDTH, currentY + MAX(labelSize.height, 18) + 2, rowTextWidth, MAX(metaSize.height, 14));

        [self addView:iconLabel];
        [self addView:labelLabel];
        [self addView:metaLabel];

        currentY += MAX(labelSize.height, 18) + MAX(metaSize.height, 14) + 4 + DSH_TASK_ROW_GAP;
    }
}

@end
