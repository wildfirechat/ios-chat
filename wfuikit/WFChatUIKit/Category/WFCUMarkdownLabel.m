//
//  WFCUMarkdownLabel.m
//  WFChat UIKit
//
//  Created by Kimi on 2025/3/8.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCUMarkdownLabel.h"
#import "WFCUConfigManager.h"
#import <WFChatClient/WFCCUtilities.h>

// 缓存键生成
static NSString *CacheKey(NSString *text, UIFont *font) {
    return [NSString stringWithFormat:@"%@_%@_%.0f", @([text hash]), font.fontName, font.pointSize];
}

static NSString *SizeCacheKey(NSString *text, UIFont *font, CGFloat width) {
    return [NSString stringWithFormat:@"%@_%.0f", CacheKey(text, font), width];
}

@interface WFCUMarkdownLabel () <UIGestureRecognizerDelegate>
@property(nonatomic, strong) UIFont *baseFont;
@property(nonatomic, strong) NSArray<NSDictionary *> *linkRanges;

// 类级别的缓存
+ (NSCache *)attributedStringCache;
+ (NSCache *)sizeCache;

@end

@implementation WFCUMarkdownLabel

#pragma mark - 类级别缓存

+ (NSCache *)attributedStringCache {
    static NSCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.countLimit = 100; // 最多缓存 100 个 attributedString
    });
    return cache;
}

+ (NSCache *)sizeCache {
    static NSCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.countLimit = 200; // 最多缓存 200 个尺寸
    });
    return cache;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.baseFont = [UIFont systemFontOfSize:18];
    self.font = self.baseFont;
    
    // 配置为类似 UILabel 的行为
    self.editable = NO;
    self.scrollEnabled = NO;
    self.textContainerInset = UIEdgeInsetsZero;
    self.textContainer.lineFragmentPadding = 0;
    self.backgroundColor = [UIColor clearColor];
    self.selectable = YES;
    
    // 数据检测
    self.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;
    self.delegate = self;
    
    // 长按手势
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.delegate = self;
    [self addGestureRecognizer:longPress];
}

- (void)setMarkdownText:(NSString *)markdownText {
    [self setMarkdownText:markdownText font:self.baseFont];
}

- (void)setMarkdownText:(NSString *)markdownText font:(UIFont *)font {
    self.baseFont = font;
    
    if (!markdownText || markdownText.length == 0) {
        self.attributedText = nil;
        return;
    }
    
    // 先从缓存查找
    NSString *cacheKey = CacheKey(markdownText, font);
    NSAttributedString *cachedAttributedString = [[WFCUMarkdownLabel attributedStringCache] objectForKey:cacheKey];
    
    if (cachedAttributedString) {
        self.attributedText = cachedAttributedString;
        return;
    }
    
    // 解析 Markdown 为 NSAttributedString
    NSAttributedString *attributedString = [self parseMarkdown:markdownText font:font];
    self.attributedText = attributedString;
    
    // 存入缓存
    if (attributedString) {
        [[WFCUMarkdownLabel attributedStringCache] setObject:attributedString forKey:cacheKey];
    }
}

#pragma mark - Markdown 解析

- (NSAttributedString *)parseMarkdown:(NSString *)markdown font:(UIFont *)font {
    NSMutableString *text = [markdown mutableCopy];
    
    // 获取颜色
    UIColor *textColor = [WFCUConfigManager globalManager].textColor ?: [UIColor blackColor];
    UIColor *linkColor = [UIColor blueColor];
    UIColor *codeColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.0];
    UIColor *codeBgColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    
    // 段落样式
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 4;
    paragraphStyle.paragraphSpacing = 8;
    
    // 基础属性
    NSDictionary *baseAttrs = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: textColor,
        NSParagraphStyleAttributeName: paragraphStyle
    };
    
    // 1. 先提取代码块（避免被其他规则处理）
    NSMutableArray *codeBlocks = [NSMutableArray array];
    NSRegularExpression *codeBlockRegex = [NSRegularExpression regularExpressionWithPattern:@"```\\n?([\\s\\S]*?)\\n?```" options:0 error:nil];
    NSArray *codeBlockMatches = [codeBlockRegex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSInteger i = 0; i < codeBlockMatches.count; i++) {
        NSTextCheckingResult *match = codeBlockMatches[codeBlockMatches.count - 1 - i]; // reverse
        NSString *code = [text substringWithRange:[match rangeAtIndex:1]];
        // 使用唯一占位符，避免多个代码块冲突
        NSString *placeholder = [NSString stringWithFormat:@"\n\uFFFC_BLOCK_%ld\n", (long)i];
        [codeBlocks insertObject:@{@"code": code, @"placeholder": placeholder} atIndex:0];
        [text replaceCharactersInRange:match.range withString:placeholder];
    }
    
    // 2. 提取行内代码
    NSMutableArray *inlineCodes = [NSMutableArray array];
    NSRegularExpression *inlineCodeRegex = [NSRegularExpression regularExpressionWithPattern:@"`([^`]+)`" options:0 error:nil];
    NSArray *inlineCodeMatches = [inlineCodeRegex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSInteger i = 0; i < inlineCodeMatches.count; i++) {
        NSTextCheckingResult *match = inlineCodeMatches[inlineCodeMatches.count - 1 - i]; // reverse
        NSString *code = [text substringWithRange:[match rangeAtIndex:1]];
        // 使用唯一占位符
        NSString *placeholder = [NSString stringWithFormat:@"\uFFFC_INLINE_%ld", (long)i];
        [inlineCodes insertObject:@{@"code": code, @"placeholder": placeholder} atIndex:0];
        [text replaceCharactersInRange:match.range withString:placeholder];
    }
    
    // 3. 处理标题（从大到小，避免冲突）- 使用占位符标记
    NSMutableArray *headerPlaceholders = [NSMutableArray array];
    NSArray *headerPatterns = @[
        @[@"^######\\s+(.+)$", @(font.pointSize * 1.1), @(UIFontWeightSemibold)],
        @[@"^#####\\s+(.+)$", @(font.pointSize * 1.15), @(UIFontWeightSemibold)],
        @[@"^####\\s+(.+)$", @(font.pointSize * 1.2), @(UIFontWeightSemibold)],
        @[@"^###\\s+(.+)$", @(font.pointSize * 1.25), @(UIFontWeightSemibold)],
        @[@"^##\\s+(.+)$", @(font.pointSize * 1.35), @(UIFontWeightBold)],
        @[@"^#\\s+(.+)$", @(font.pointSize * 1.5), @(UIFontWeightBold)]
    ];
    
    for (NSInteger patternIndex = 0; patternIndex < headerPatterns.count; patternIndex++) {
        NSArray *pattern = headerPatterns[patternIndex];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern[0] options:NSRegularExpressionAnchorsMatchLines error:nil];
        NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
        for (NSInteger i = 0; i < matches.count; i++) {
            NSTextCheckingResult *match = matches[matches.count - 1 - i];
            NSRange contentRange = [match rangeAtIndex:1];
            NSString *content = [text substringWithRange:contentRange];
            NSString *placeholder = [NSString stringWithFormat:@"\uFFFC_HDR_%ld_%ld", (long)patternIndex, (long)i];
            UIFont *headerFont = [UIFont systemFontOfSize:[pattern[1] floatValue] weight:[pattern[2] floatValue]];
            
            [headerPlaceholders insertObject:@{
                @"placeholder": placeholder,
                @"content": content,
                @"font": headerFont
            } atIndex:0];
            [text replaceCharactersInRange:match.range withString:placeholder];
        }
    }
    
    // 处理粗体 - 使用占位符
    NSMutableArray *boldPlaceholders = [NSMutableArray array];
    NSRegularExpression *boldRegex = [NSRegularExpression regularExpressionWithPattern:@"\\*\\*([^\\*]+)\\*\\*|__([^_]+)__" options:0 error:nil];
    NSArray *boldMatches = [boldRegex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSInteger i = 0; i < boldMatches.count; i++) {
        NSTextCheckingResult *match = boldMatches[boldMatches.count - 1 - i];
        NSRange range1 = [match rangeAtIndex:1];
        NSRange range2 = [match rangeAtIndex:2];
        NSRange contentRange = range1.location != NSNotFound ? range1 : range2;
        if (contentRange.location != NSNotFound) {
            NSString *content = [text substringWithRange:contentRange];
            NSString *placeholder = [NSString stringWithFormat:@"\uFFFC_BOLD_%ld", (long)i];
            UIFont *boldFont = [UIFont boldSystemFontOfSize:font.pointSize];
            
            [boldPlaceholders insertObject:@{
                @"placeholder": placeholder,
                @"content": content,
                @"font": boldFont
            } atIndex:0];
            [text replaceCharactersInRange:match.range withString:placeholder];
        }
    }
    
    // 处理斜体 - 使用占位符
    NSMutableArray *italicPlaceholders = [NSMutableArray array];
    NSRegularExpression *italicRegex = [NSRegularExpression regularExpressionWithPattern:@"(?<!\\*)\\*([^\\*]+)\\*(?!\\*)" options:0 error:nil];
    NSArray *italicMatches = [italicRegex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSInteger i = 0; i < italicMatches.count; i++) {
        NSTextCheckingResult *match = italicMatches[italicMatches.count - 1 - i];
        NSRange contentRange = [match rangeAtIndex:1];
        NSString *content = [text substringWithRange:contentRange];
        NSString *placeholder = [NSString stringWithFormat:@"\uFFFC_ITA_%ld", (long)i];
        UIFont *italicFont = [UIFont italicSystemFontOfSize:font.pointSize];
        
        [italicPlaceholders insertObject:@{
            @"placeholder": placeholder,
            @"content": content,
            @"font": italicFont
        } atIndex:0];
        [text replaceCharactersInRange:match.range withString:placeholder];
    }
    
    // 处理删除线 - 使用占位符
    NSMutableArray *strikePlaceholders = [NSMutableArray array];
    NSRegularExpression *strikeRegex = [NSRegularExpression regularExpressionWithPattern:@"~~([^~]+)~~" options:0 error:nil];
    NSArray *strikeMatches = [strikeRegex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSInteger i = 0; i < strikeMatches.count; i++) {
        NSTextCheckingResult *match = strikeMatches[strikeMatches.count - 1 - i];
        NSRange contentRange = [match rangeAtIndex:1];
        NSString *content = [text substringWithRange:contentRange];
        NSString *placeholder = [NSString stringWithFormat:@"\uFFFC_STK_%ld", (long)i];
        
        [strikePlaceholders insertObject:@{
            @"placeholder": placeholder,
            @"content": content
        } atIndex:0];
        [text replaceCharactersInRange:match.range withString:placeholder];
    }
    
    // 处理链接 - 使用占位符
    NSMutableArray *linkPlaceholders = [NSMutableArray array];
    NSRegularExpression *linkRegex = [NSRegularExpression regularExpressionWithPattern:@"\\[([^\\]]+)\\]\\(([^\\)]+)\\)" options:0 error:nil];
    NSArray *linkMatches = [linkRegex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSInteger i = 0; i < linkMatches.count; i++) {
        NSTextCheckingResult *match = linkMatches[linkMatches.count - 1 - i];
        NSRange textRange = [match rangeAtIndex:1];
        NSRange urlRange = [match rangeAtIndex:2];
        NSString *linkText = [text substringWithRange:textRange];
        NSString *url = [text substringWithRange:urlRange];
        NSString *placeholder = [NSString stringWithFormat:@"\uFFFC_LNK_%ld", (long)i];
        
        [linkPlaceholders insertObject:@{
            @"placeholder": placeholder,
            @"content": linkText,
            @"url": url
        } atIndex:0];
        [text replaceCharactersInRange:match.range withString:placeholder];
    }
    
    // 处理引用 - 使用占位符
    NSMutableArray *quotePlaceholders = [NSMutableArray array];
    NSRegularExpression *quoteRegex = [NSRegularExpression regularExpressionWithPattern:@"^>\\s?(.+)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    NSArray *quoteMatches = [quoteRegex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSInteger i = 0; i < quoteMatches.count; i++) {
        NSTextCheckingResult *match = quoteMatches[quoteMatches.count - 1 - i];
        NSRange contentRange = [match rangeAtIndex:1];
        NSString *content = [text substringWithRange:contentRange];
        NSString *placeholder = [NSString stringWithFormat:@"\uFFFC_QUO_%ld", (long)i];
        
        [quotePlaceholders insertObject:@{
            @"placeholder": placeholder,
            @"content": content
        } atIndex:0];
        [text replaceCharactersInRange:match.range withString:placeholder];
    }
    
    // 处理列表
    NSRegularExpression *ulRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*[-\\*\\+]\\s+(.+)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    NSArray *ulMatches = [ulRegex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSTextCheckingResult *match in [ulMatches reverseObjectEnumerator]) {
        NSRange contentRange = [match rangeAtIndex:1];
        NSString *content = [text substringWithRange:contentRange];
        [text replaceCharactersInRange:match.range withString:[NSString stringWithFormat:@"• %@", content]];
    }
    
    NSRegularExpression *olRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*(\\d+)\\.\\s+(.+)$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    NSArray *olMatches = [olRegex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSTextCheckingResult *match in [olMatches reverseObjectEnumerator]) {
        NSString *number = [text substringWithRange:[match rangeAtIndex:1]];
        NSRange contentRange = [match rangeAtIndex:2];
        NSString *content = [text substringWithRange:contentRange];
        [text replaceCharactersInRange:match.range withString:[NSString stringWithFormat:@"%@. %@", number, content]];
    }
    
    // 创建基础属性字符串
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:text attributes:baseAttrs];
    
    // 恢复行内代码（替换占位符）
    for (NSDictionary *codeInfo in inlineCodes) {
        NSRange placeholderRange = [result.string rangeOfString:codeInfo[@"placeholder"]];
        if (placeholderRange.location != NSNotFound) {
            NSString *code = codeInfo[@"code"];
            UIFont *codeFont = [UIFont fontWithName:@"Menlo" size:font.pointSize * 0.9] ?: [UIFont systemFontOfSize:font.pointSize * 0.9];
            
            NSMutableAttributedString *codeAttr = [[NSMutableAttributedString alloc] initWithString:code];
            [codeAttr addAttributes:@{
                NSFontAttributeName: codeFont,
                NSForegroundColorAttributeName: codeColor,
                NSBackgroundColorAttributeName: codeBgColor
            } range:NSMakeRange(0, code.length)];
            
            [result replaceCharactersInRange:placeholderRange withAttributedString:codeAttr];
        }
    }
    
    // 恢复代码块
    for (NSDictionary *codeInfo in codeBlocks) {
        NSRange placeholderRange = [result.string rangeOfString:codeInfo[@"placeholder"]];
        if (placeholderRange.location != NSNotFound) {
            NSString *code = codeInfo[@"code"];
            UIFont *codeFont = [UIFont fontWithName:@"Menlo" size:font.pointSize * 0.85] ?: [UIFont systemFontOfSize:font.pointSize * 0.85];
            
            NSMutableAttributedString *codeAttr = [[NSMutableAttributedString alloc] initWithString:code];
            NSMutableParagraphStyle *codeParagraph = [[NSMutableParagraphStyle alloc] init];
            codeParagraph.lineSpacing = 2;
            
            [codeAttr addAttributes:@{
                NSFontAttributeName: codeFont,
                NSForegroundColorAttributeName: codeColor,
                NSBackgroundColorAttributeName: codeBgColor,
                NSParagraphStyleAttributeName: codeParagraph
            } range:NSMakeRange(0, code.length)];
            
            [result replaceCharactersInRange:placeholderRange withAttributedString:codeAttr];
        }
    }
    
    // 恢复标题
    for (NSDictionary *info in headerPlaceholders) {
        NSString *placeholder = info[@"placeholder"];
        NSString *content = info[@"content"];
        NSRange range = [result.string rangeOfString:placeholder];
        if (range.location != NSNotFound) {
            UIFont *headerFont = info[@"font"];
            NSMutableAttributedString *contentAttr = [[NSMutableAttributedString alloc] initWithString:content];
            [contentAttr addAttribute:NSFontAttributeName value:headerFont range:NSMakeRange(0, content.length)];
            [result replaceCharactersInRange:range withAttributedString:contentAttr];
        }
    }
    
    // 恢复粗体
    for (NSDictionary *info in boldPlaceholders) {
        NSString *placeholder = info[@"placeholder"];
        NSString *content = info[@"content"];
        NSRange range = [result.string rangeOfString:placeholder];
        if (range.location != NSNotFound) {
            UIFont *boldFont = info[@"font"];
            NSMutableAttributedString *contentAttr = [[NSMutableAttributedString alloc] initWithString:content];
            [contentAttr addAttribute:NSFontAttributeName value:boldFont range:NSMakeRange(0, content.length)];
            [result replaceCharactersInRange:range withAttributedString:contentAttr];
        }
    }
    
    // 恢复斜体
    for (NSDictionary *info in italicPlaceholders) {
        NSString *placeholder = info[@"placeholder"];
        NSString *content = info[@"content"];
        NSRange range = [result.string rangeOfString:placeholder];
        if (range.location != NSNotFound) {
            UIFont *italicFont = info[@"font"];
            NSMutableAttributedString *contentAttr = [[NSMutableAttributedString alloc] initWithString:content];
            [contentAttr addAttribute:NSFontAttributeName value:italicFont range:NSMakeRange(0, content.length)];
            [result replaceCharactersInRange:range withAttributedString:contentAttr];
        }
    }
    
    // 恢复删除线
    for (NSDictionary *info in strikePlaceholders) {
        NSString *placeholder = info[@"placeholder"];
        NSString *content = info[@"content"];
        NSRange range = [result.string rangeOfString:placeholder];
        if (range.location != NSNotFound) {
            NSMutableAttributedString *contentAttr = [[NSMutableAttributedString alloc] initWithString:content];
            [contentAttr addAttribute:NSStrikethroughStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, content.length)];
            [contentAttr addAttribute:NSStrikethroughColorAttributeName value:textColor range:NSMakeRange(0, content.length)];
            [result replaceCharactersInRange:range withAttributedString:contentAttr];
        }
    }
    
    // 恢复链接
    for (NSDictionary *info in linkPlaceholders) {
        NSString *placeholder = info[@"placeholder"];
        NSString *content = info[@"content"];
        NSString *url = info[@"url"];
        NSRange range = [result.string rangeOfString:placeholder];
        if (range.location != NSNotFound) {
            NSMutableAttributedString *contentAttr = [[NSMutableAttributedString alloc] initWithString:content];
            [contentAttr addAttribute:NSForegroundColorAttributeName value:linkColor range:NSMakeRange(0, content.length)];
            [contentAttr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, content.length)];
            [contentAttr addAttribute:NSLinkAttributeName value:url range:NSMakeRange(0, content.length)];
            [result replaceCharactersInRange:range withAttributedString:contentAttr];
        }
    }
    
    // 恢复引用
    for (NSDictionary *info in quotePlaceholders) {
        NSString *placeholder = info[@"placeholder"];
        NSString *content = info[@"content"];
        NSRange range = [result.string rangeOfString:placeholder];
        if (range.location != NSNotFound) {
            UIColor *quoteColor = [textColor colorWithAlphaComponent:0.7];
            NSMutableAttributedString *contentAttr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"│ %@", content]];
            [contentAttr addAttribute:NSForegroundColorAttributeName value:quoteColor range:NSMakeRange(0, contentAttr.length)];
            [result replaceCharactersInRange:range withAttributedString:contentAttr];
        }
    }
    
    return result;
}

#pragma mark - 高度计算

+ (CGFloat)heightForText:(NSString *)text width:(CGFloat)width font:(UIFont *)font {
    CGSize size = [self sizeForText:text maxWidth:width font:font];
    return size.height;
}

+ (CGSize)sizeForText:(NSString *)text maxWidth:(CGFloat)maxWidth font:(UIFont *)font {
    if (!text || text.length == 0) {
        return CGSizeMake(40, 4);
    }
    
    // 先从尺寸缓存查找
    NSString *sizeCacheKey = SizeCacheKey(text, font, maxWidth);
    NSValue *cachedSize = [[WFCUMarkdownLabel sizeCache] objectForKey:sizeCacheKey];
    if (cachedSize) {
        return [cachedSize CGSizeValue];
    }
    
    // 先从 attributedString 缓存查找，避免重复解析
    NSString *attrCacheKey = CacheKey(text, font);
    NSAttributedString *attributedText = [[WFCUMarkdownLabel attributedStringCache] objectForKey:attrCacheKey];
    
    if (!attributedText) {
        // 解析 Markdown
        attributedText = [[[self alloc] init] parseMarkdown:text font:font];
        if (attributedText) {
            [[WFCUMarkdownLabel attributedStringCache] setObject:attributedText forKey:attrCacheKey];
        }
    }
    
    if (!attributedText) {
        return CGSizeMake(40, 4);
    }
    
    // 使用 layoutManager 计算实际高度（最准确）
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedText];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)];
    
    textContainer.lineFragmentPadding = 0;
    textContainer.maximumNumberOfLines = 0;
    
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    
    [layoutManager glyphRangeForTextContainer:textContainer];
    CGRect usedRect = [layoutManager usedRectForTextContainer:textContainer];
    
    CGFloat width = ceil(usedRect.size.width);
    CGFloat height = ceil(usedRect.size.height);
    
    // 确保最小高度
    if (height < font.lineHeight) {
        height = font.lineHeight;
    }
    
    // 应用与 WFCUTextCell 相同的宽度调整逻辑
    if (width < 40) {
        width += 4;
        if (width > 40) {
            width = 40;
        } else if (width < 24) {
            width = 24;
        }
    }
    
    CGSize result = CGSizeMake(width, height);
    
    // 存入缓存
    [[WFCUMarkdownLabel sizeCache] setObject:[NSValue valueWithCGSize:result] forKey:sizeCacheKey];
    
    return result;
}

#pragma mark - 手势处理

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if ([self.markdownDelegate respondsToSelector:@selector(markdownLabelDidLongPress:)]) {
            [self.markdownDelegate markdownLabelDidLongPress:self];
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    NSString *urlString = URL.absoluteString;
    
    if ([urlString hasPrefix:@"tel:"]) {
        if ([self.markdownDelegate respondsToSelector:@selector(markdownLabel:didSelectPhoneNumber:)]) {
            [self.markdownDelegate markdownLabel:self didSelectPhoneNumber:[urlString substringFromIndex:4]];
        }
        return NO;
    }
    
    if ([self.markdownDelegate respondsToSelector:@selector(markdownLabel:didSelectUrl:)]) {
        [self.markdownDelegate markdownLabel:self didSelectUrl:urlString];
    }
    return NO;
}

#pragma mark - 工具方法

+ (BOOL)containsMarkdown:(NSString *)text {
    return [WFCCUtilities containsMarkdown:text];
}

+ (void)clearCache {
    [[WFCUMarkdownLabel attributedStringCache] removeAllObjects];
    [[WFCUMarkdownLabel sizeCache] removeAllObjects];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(copy:) || action == @selector(select:) || action == @selector(selectAll:)) {
        return [super canPerformAction:action withSender:sender];
    }
    return NO;
}

@end
