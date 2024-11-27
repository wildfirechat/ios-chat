//
//  TYHWaterMark.m
//
//  Created by yuhua Tang on 2022/8/5.
//

#import "TYHWaterMark.h"
@import ObjectiveC;
@import PhotosUI;

BOOL isPresentAbleSystemVC(UIViewController *vc) {
    static NSArray *list = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *array = @[].mutableCopy;
        [array addObject:[UIImagePickerController class]];
        [array addObject:[UIDocumentPickerViewController class]];
        [array addObject:[UIDocumentMenuViewController class]];
        
        if (@available(iOS 13.0, *)) {
            [array addObject:[UIFontPickerViewController class]];
        }
        
        if (@available(iOS 14.0, *)) {
            [array addObject:[UIColorPickerViewController class]];
            [array addObject:[PHPickerViewController class]];
        }
        
        list = [array copy];
    });
    
    for(Class aClass in list) {
        if([vc isKindOfClass:aClass]) {
            return YES;
        }
    }
    return NO;
}

static NSString *g_characteristicStr = @"";
static NSString *g_formatStr = @"MM-dd HH:mm";
static UIFont   *g_font= nil;
static UIColor  *g_color = nil;
static TYHWaterMarkView *g_waterMarkView = nil;


@interface UIViewController(TYHWaterMarkView)
@end

@implementation UIViewController(TYHWaterMarkView)

+ (void)load {
    [UIViewController tyhwatermark_swizzleInstanceMethod:@selector(presentViewController:animated:completion:) with:@selector(tyhwatermark_presentViewController:animated:completion:)];
    [UIViewController tyhwatermark_swizzleInstanceMethod:@selector(dismissViewControllerAnimated:completion:) with:@selector(tyhwatermark_dismissViewControllerAnimated:completion:)];
}

+ (BOOL)tyhwatermark_swizzleInstanceMethod:(SEL)originalSel with:(SEL)newSel {
    Method originalMethod = class_getInstanceMethod(self, originalSel);
    Method newMethod = class_getInstanceMethod(self, newSel);
    if (!originalMethod || !newMethod) return NO;
    
    class_addMethod(self,
                    originalSel,
                    class_getMethodImplementation(self, originalSel),
                    method_getTypeEncoding(originalMethod));
    class_addMethod(self,
                    newSel,
                    class_getMethodImplementation(self, newSel),
                    method_getTypeEncoding(newMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(self, originalSel),
                                   class_getInstanceMethod(self, newSel));
    return YES;
}

- (void)tyhwatermark_presentViewController:(UIViewController *)viewControllerToPresent animated: (BOOL)flag completion:(void (^ __nullable)(void))completion  {
    NSString *vcClassName = NSStringFromClass([viewControllerToPresent class]);
    if(isPresentAbleSystemVC(viewControllerToPresent) ||
       (([vcClassName hasPrefix:@"UI"]
         && ![viewControllerToPresent isKindOfClass:[UIAlertController class]]
         && ![viewControllerToPresent isMemberOfClass:[UIViewController class]])))
    {
        if (g_waterMarkView)
        {
            g_waterMarkView.hidden = YES;
        }
    }
    [self tyhwatermark_presentViewController:viewControllerToPresent animated:flag completion:completion];
}

- (void)tyhwatermark_dismissViewControllerAnimated: (BOOL)flag completion: (void (^ __nullable)(void))completion {
    if (g_waterMarkView)
    {
        g_waterMarkView.hidden = NO;
    }
    [self tyhwatermark_dismissViewControllerAnimated:flag completion:completion];
}

@end


@interface TYHWaterMarkView ()
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) NSDictionary *textAttributes;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation TYHWaterMarkView

+ (void)setCharacter:(NSString *)str
{
    if (g_waterMarkView)
    {
        [g_waterMarkView setCharacteristic:str];
    }
    else
    {
        g_characteristicStr = str;
    }
}

+ (void)setTimeFormat:(NSString *)format
{
    if (g_waterMarkView)
    {
        [g_waterMarkView setTimeFormat:format];
    }
    else
    {
        g_formatStr = format;
    }
}

+ (void)setFont:(UIFont *)font {
    g_font = font;
    g_waterMarkView.textAttributes = nil;
    [g_waterMarkView updateContent];
}

+ (void)setColor:(UIColor *)color {
    g_color = color;
    g_waterMarkView.textAttributes = nil;
    [g_waterMarkView updateContent];
}

+ (void)updateDate
{
    if (g_waterMarkView)
    {
        [g_waterMarkView updateContent];
    }
    else
    {
    }
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    float width = [UIScreen mainScreen].bounds.size.width;
    float height = [UIScreen mainScreen].bounds.size.height;
    self.backgroundColor = [UIColor clearColor];
    self.frame = CGRectMake(-0.5 * width, -0.5 * height, 2 * width, 2 * height);
    self.layer.zPosition = 999;
    [self addSubview:self.textView];
    self.textView.frame = CGRectMake(0, 0, 2 * width, 2 * height);
    self.textView.attributedText = [[NSAttributedString alloc] initWithString:[self markContent] attributes:self.textAttributes];
    self.transform = CGAffineTransformMakeRotation(-15 * M_PI / 180);
    g_waterMarkView = self;
}

- (NSString *)markContent
{
    NSString *dateString = [self stringWithFormat:g_formatStr];
    NSString *mark = [NSString stringWithFormat:@"%@  %@", g_characteristicStr, dateString];
    NSMutableString *all = @"".mutableCopy;
    for (int i = 0; i < 100; i++)
    {
        [all appendString:mark];
        [all appendString:@"     "];
    }
    return all;
}

- (void)setCharacteristic:(NSString *)str
{
    g_characteristicStr = str;
    [self updateContent];
}

- (void)setTimeFormat:(NSString *)format
{
    g_formatStr = format;
    [self updateContent];
}

- (void)updateContent
{
    self.textView.attributedText = [[NSAttributedString alloc] initWithString:[self markContent] attributes:self.textAttributes];
}

- (NSDictionary *)textAttributes {
    if (!_textAttributes) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 75; // 字体的行间距
        UIFont *font = g_font ?:[UIFont systemFontOfSize:18];
        UIColor *color = g_color ?:[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:0.14];
        _textAttributes = @{
            NSFontAttributeName : font,
            NSParagraphStyleAttributeName : paragraphStyle,
            NSForegroundColorAttributeName : color
        };
    }
    return _textAttributes;
}

- (NSString *)stringWithFormat:(NSString *)format
{
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:[NSLocale currentLocale]];
    });
    [formatter setDateFormat:format];
    return [formatter stringFromDate:[NSDate date]];
}

- (UITextView *)textView
{
    if (!_textView)
    {
        UITextView *textView = [UITextView new];
        textView.backgroundColor = [UIColor clearColor];
        textView.editable = NO;
        textView.selectable = NO;
        textView.userInteractionEnabled = NO;
        _textView = textView;
    }
    return _textView;
}

+ (void)autoUpdateDate:(BOOL)enable {
    if(enable) {
        g_waterMarkView.timer = [NSTimer scheduledTimerWithTimeInterval:10 repeats:true block:^(NSTimer * _Nonnull timer) {
            [TYHWaterMarkView updateDate];
        }];
    } else {
        [g_waterMarkView.timer invalidate];
        g_waterMarkView.timer = nil;
    }
}

@end
