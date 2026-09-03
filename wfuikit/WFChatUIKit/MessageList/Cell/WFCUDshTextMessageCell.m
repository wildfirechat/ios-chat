//
//  WFCUDshTextMessageCell.m
//  WFChatUIKit
//
//  DSH 回答/审批结果消息 Cell（201/203），按普通文本气泡渲染 digest。
//

#import "WFCUDshTextMessageCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"
#import "WFCUConfigManager.h"
#import "UIFont+YH.h"

#define TEXT_LABEL_TOP_PADDING 3
#define TEXT_LABEL_BUTTOM_PADDING 5

@interface WFCUAgentTextMessageCell ()
@property (nonatomic, strong)UILabel *digestLabel;
@end

@implementation WFCUAgentTextMessageCell

+ (UIFont *)defaultFont {
    return [UIFont scaledSystemFontOfSize:18];
}

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    NSString *text = [msgModel.message digest] ?: @"";
    CGSize size = [WFCUUtilities getTextDrawingSize:text font:[self defaultFont] constrainedSize:CGSizeMake(width, 8000)];
    size.height += TEXT_LABEL_TOP_PADDING + TEXT_LABEL_BUTTOM_PADDING;
    if (size.width < 40) {
        size.width += 4;
        if (size.width > 40) {
            size.width = 40;
        } else if (size.width < 24) {
            size.width = 24;
        }
    }
    return size;
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    CGRect frame = self.contentArea.bounds;
    self.digestLabel.frame = CGRectMake(0, TEXT_LABEL_TOP_PADDING, frame.size.width, frame.size.height - TEXT_LABEL_TOP_PADDING - TEXT_LABEL_BUTTOM_PADDING);
    self.digestLabel.font = [[self class] defaultFont];
    self.digestLabel.text = [model.message digest];
}

- (UILabel *)digestLabel {
    if (!_digestLabel) {
        _digestLabel = [[UILabel alloc] init];
        _digestLabel.numberOfLines = 0;
        _digestLabel.textColor = [WFCUConfigManager globalManager].textColor;
        [self.contentArea addSubview:_digestLabel];
    }
    return _digestLabel;
}

@end
