//
//  WFCFontSizeViewController.m
//  WildFireChat
//
//  Created by Kimi Code CLI on 2026/6/28.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "WFCFontSizeViewController.h"
#import <WFChatUIKit/WFChatUIKit.h>
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "AppDelegate.h"
#import "WFCBaseTabBarController.h"

#define kMinFontScale 0.8
#define kMaxFontScale 1.5
#define kFontScaleStep 0.1

@interface WFCFontSizeViewController ()
@property(nonatomic, strong)UILabel *sampleLabel;
@property(nonatomic, strong)UISlider *fontSlider;
@property(nonatomic, strong)UILabel *valueLabel;
@property(nonatomic, strong)UILabel *smallTipLabel;
@property(nonatomic, strong)UILabel *largeTipLabel;
@property(nonatomic, strong)UIView *scaleContainer;
@property(nonatomic, strong)UIBarButtonItem *saveButton;
@property(nonatomic, assign)CGFloat initialFontScale;
@end

@implementation WFCFontSizeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LocalizedString(@"FontSize");
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.initialFontScale = [WFCUConfigManager globalManager].fontScale;
    
    [self setupNavBar];
    [self setupViews];
    [self updateSampleFont];
}

- (void)setupNavBar {
    self.saveButton = [[UIBarButtonItem alloc] initWithTitle:LocalizedString(@"Save")
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(onSaveButton:)];
    self.navigationItem.rightBarButtonItem = self.saveButton;
    [self updateSaveButtonState];
}

- (void)setupViews {
    CGFloat margin = 24;
    CGFloat top = 80 + [self safeAreaTop];
    CGFloat width = self.view.frame.size.width - margin * 2;
    
    // 示例文字
    self.sampleLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, top, width, 120)];
    self.sampleLabel.numberOfLines = 0;
    self.sampleLabel.textAlignment = NSTextAlignmentCenter;
    self.sampleLabel.textColor = [WFCUConfigManager globalManager].textColor;
    self.sampleLabel.text = LocalizedString(@"FontSizeSampleText");
    [self.view addSubview:self.sampleLabel];
    
    // 滑块
    CGFloat sliderY = CGRectGetMaxY(self.sampleLabel.frame) + 60;
    self.fontSlider = [[UISlider alloc] initWithFrame:CGRectMake(margin + 40, sliderY, width - 80, 30)];
    self.fontSlider.minimumValue = kMinFontScale;
    self.fontSlider.maximumValue = kMaxFontScale;
    self.fontSlider.value = self.initialFontScale;
    [self.fontSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.fontSlider];
    
    // 标尺刻度
    CGFloat scaleY = CGRectGetMaxY(self.fontSlider.frame) + 10;
    CGFloat scaleHeight = 20;
    self.scaleContainer = [[UIView alloc] initWithFrame:CGRectMake(margin + 40, scaleY, width - 80, scaleHeight)];
    [self.view addSubview:self.scaleContainer];
    [self setupScaleMarks];
    
    // 左右提示文字
    self.smallTipLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, sliderY + 5, 36, 20)];
    self.smallTipLabel.font = [UIFont systemFontOfSize:12];
    self.smallTipLabel.textColor = [UIColor grayColor];
    self.smallTipLabel.textAlignment = NSTextAlignmentCenter;
    self.smallTipLabel.text = LocalizedString(@"FontSizeSmall");
    [self.view addSubview:self.smallTipLabel];
    
    self.largeTipLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - margin - 36, sliderY + 5, 36, 20)];
    self.largeTipLabel.font = [UIFont systemFontOfSize:12];
    self.largeTipLabel.textColor = [UIColor grayColor];
    self.largeTipLabel.textAlignment = NSTextAlignmentCenter;
    self.largeTipLabel.text = LocalizedString(@"FontSizeLarge");
    [self.view addSubview:self.largeTipLabel];
    
    // 当前值
    self.valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, scaleY + scaleHeight + 16, width, 24)];
    self.valueLabel.textAlignment = NSTextAlignmentCenter;
    self.valueLabel.textColor = [UIColor grayColor];
    self.valueLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.valueLabel];
    
    [self updateValueLabel];
}

- (void)setupScaleMarks {
    int minPercent = (int)round(kMinFontScale * 100);
    int maxPercent = (int)round(kMaxFontScale * 100);
    int stepPercent = (int)round(kFontScaleStep * 100);
    int count = (maxPercent - minPercent) / stepPercent + 1;
    CGFloat containerWidth = self.scaleContainer.frame.size.width;
    
    for (int i = 0; i < count; i++) {
        CGFloat x = (containerWidth / (count - 1)) * i;
        UIView *mark = [[UIView alloc] initWithFrame:CGRectMake(x - 0.5, 0, 1, 8)];
        mark.backgroundColor = [UIColor lightGrayColor];
        [self.scaleContainer addSubview:mark];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x - 12, 10, 24, 10)];
        label.font = [UIFont systemFontOfSize:9];
        label.textColor = [UIColor grayColor];
        label.textAlignment = NSTextAlignmentCenter;
        int percent = minPercent + i * stepPercent;
        label.text = [NSString stringWithFormat:@"%d%%", percent];
        [self.scaleContainer addSubview:label];
    }
}

- (CGFloat)safeAreaTop {
    if (@available(iOS 11.0, *)) {
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        return window.safeAreaInsets.top;
    }
    return 0;
}

- (void)sliderValueChanged:(UISlider *)slider {
    // 按 0.1 刻度对齐
    CGFloat rawValue = slider.value;
    CGFloat steppedValue = round((rawValue - kMinFontScale) / kFontScaleStep) * kFontScaleStep + kMinFontScale;
    steppedValue = MAX(kMinFontScale, MIN(kMaxFontScale, steppedValue));
    slider.value = steppedValue;
    
    // 拖动过程中只更新示例文字和数值显示，不写配置
    [self updateSampleFont];
    [self updateValueLabel];
    [self updateSaveButtonState];
}

- (void)onSaveButton:(id)sender {
    CGFloat newValue = self.fontSlider.value;
    if (fabs(newValue - self.initialFontScale) < 0.001) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                   message:LocalizedString(@"FontSizeChangeRestartTip")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:LocalizedString(@"Confirm")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
        [WFCUConfigManager globalManager].fontScale = newValue;
        
        // 重建主窗口根控制器，使整个应用 UI 按新字体重新渲染
        UIWindow *window = ((AppDelegate *)[UIApplication sharedApplication].delegate).window;
        window.rootViewController = [WFCBaseTabBarController new];
        [window makeKeyAndVisible];
    }];
    [alert addAction:confirm];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:LocalizedString(@"Cancel")
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateSaveButtonState {
    CGFloat currentValue = self.fontSlider.value;
    BOOL changed = fabs(currentValue - self.initialFontScale) > 0.001;
    self.saveButton.enabled = changed;
    self.saveButton.tintColor = changed ? [UIColor colorWithHexString:@"0x1d1d1d"] : [UIColor lightGrayColor];
}

- (void)updateSampleFont {
    // 拖动过程中按当前滑块值实时预览，不写入全局配置
    CGFloat previewSize = 16 * self.fontSlider.value;
    self.sampleLabel.font = [UIFont systemFontOfSize:previewSize];
}

- (void)updateValueLabel {
    int percent = (int)round(self.fontSlider.value * 100);
    self.valueLabel.text = [NSString stringWithFormat:@"%d%%", percent];
}

@end
