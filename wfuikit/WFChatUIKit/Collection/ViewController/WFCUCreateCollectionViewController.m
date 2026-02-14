//
//  WFCUCreateCollectionViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCUCreateCollectionViewController.h"
#import "WFCUUtilities.h"
#import "WFCUImage.h"
#import "WFCUCollection.h"
#import "UIView+Toast.h"
#import "WFCUConfigManager.h"
#import "MBProgressHUD.h"

@interface WFCUCreateCollectionViewController () <UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic, strong) UITextField *titleTextField;
@property (nonatomic, strong) UITextView *descTextView;
@property (nonatomic, strong) UITextField *templateTextField;
@property (nonatomic, strong) UISegmentedControl *expireTypeControl;
@property (nonatomic, strong) UIDatePicker *expireDatePicker;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@end

@implementation WFCUCreateCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = WFCString(@"CreateCollection");
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    // 导航栏按钮
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(onCancel:)];
    self.navigationItem.leftBarButtonItem = cancelItem;

    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Done") style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    self.navigationItem.rightBarButtonItem = doneItem;

    // 初始化UI
    [self setupUI];

    // 添加点击手势收起键盘（在setupUI之后添加，避免干扰）
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tapGesture.cancelsTouchesInView = NO;  // 关键：允许触摸事件传递给其他视图
    [self.view addGestureRecognizer:tapGesture];
}

- (void)setupUI {
    CGFloat margin = 16;
    CGFloat topOffset = 20;
    CGFloat spacing = 16;
    CGFloat fieldHeight = 44;

    // ScrollView
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];

    // 标题输入框
    UILabel *titleLabel = [self createLabel:WFCString(@"CollectionTitle")];
    [self.contentView addSubview:titleLabel];
    titleLabel.frame = CGRectMake(margin, topOffset, self.view.bounds.size.width - margin * 2, 20);

    self.titleTextField = [[UITextField alloc] initWithFrame:CGRectMake(margin, topOffset + 24, self.view.bounds.size.width - margin * 2, fieldHeight)];
    self.titleTextField.placeholder = WFCString(@"CollectionTitlePlaceholder");
    self.titleTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.titleTextField.delegate = self;
    self.titleTextField.returnKeyType = UIReturnKeyNext;
    [self.contentView addSubview:self.titleTextField];

    CGFloat currentY = topOffset + 24 + fieldHeight + spacing;

    // 描述输入框
    UILabel *descLabel = [self createLabel:WFCString(@"CollectionDesc")];
    [self.contentView addSubview:descLabel];
    descLabel.frame = CGRectMake(margin, currentY, self.view.bounds.size.width - margin * 2, 20);

    self.descTextView = [[UITextView alloc] initWithFrame:CGRectMake(margin, currentY + 24, self.view.bounds.size.width - margin * 2, 80)];
    self.descTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.descTextView.layer.borderWidth = 0.5;
    self.descTextView.layer.cornerRadius = 5;
    self.descTextView.font = [UIFont systemFontOfSize:16];
    self.descTextView.delegate = self;
    [self.contentView addSubview:self.descTextView];

    currentY += 24 + 80 + spacing;

    // 模板输入框
    UILabel *templateLabel = [self createLabel:WFCString(@"CollectionTemplate")];
    [self.contentView addSubview:templateLabel];
    templateLabel.frame = CGRectMake(margin, currentY, self.view.bounds.size.width - margin * 2, 20);

    self.templateTextField = [[UITextField alloc] initWithFrame:CGRectMake(margin, currentY + 24, self.view.bounds.size.width - margin * 2, fieldHeight)];
    self.templateTextField.placeholder = WFCString(@"CollectionTemplatePlaceholder");
    self.templateTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.templateTextField.delegate = self;
    [self.contentView addSubview:self.templateTextField];

    currentY += 24 + fieldHeight + spacing;

    // 过期类型选择
    UILabel *expireLabel = [self createLabel:WFCString(@"CollectionExpireType")];
    [self.contentView addSubview:expireLabel];
    expireLabel.frame = CGRectMake(margin, currentY, self.view.bounds.size.width - margin * 2, 20);

    self.expireTypeControl = [[UISegmentedControl alloc] initWithItems:@[WFCString(@"NoExpire"), WFCString(@"SetExpire")]];
    self.expireTypeControl.frame = CGRectMake(margin, currentY + 24, self.view.bounds.size.width - margin * 2, 32);
    self.expireTypeControl.selectedSegmentIndex = 0;
    [self.expireTypeControl addTarget:self action:@selector(expireTypeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.expireTypeControl];

    currentY += 24 + 32 + spacing;

    // 日期选择器（默认隐藏）
    self.expireDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(margin, currentY, self.view.bounds.size.width - margin * 2, 180)];
    self.expireDatePicker.datePickerMode = UIDatePickerModeDateAndTime;
    self.expireDatePicker.hidden = YES;
    if (@available(iOS 14.0, *)) {
        self.expireDatePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    // 设置最小日期为当前时间
    self.expireDatePicker.minimumDate = [NSDate date];
    [self.contentView addSubview:self.expireDatePicker];

    // 设置 contentView 的 frame
    self.contentView.frame = CGRectMake(0, 0, self.view.bounds.size.width, currentY + 180 + spacing);
    self.scrollView.contentSize = self.contentView.bounds.size;
}

- (UILabel *)createLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = [UIColor grayColor];
    return label;
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)expireTypeChanged:(UISegmentedControl *)sender {
    self.expireDatePicker.hidden = (sender.selectedSegmentIndex == 0);
}

- (void)onCancel:(id)sender {
    [self dismissKeyboard];
    if ([self.delegate respondsToSelector:@selector(createCollectionViewControllerDidCancel:)]) {
        [self.delegate createCollectionViewControllerDidCancel:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onDone:(id)sender {
    [self dismissKeyboard];

    // 验证标题
    NSString *title = [self.titleTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (title.length == 0) {
        [self.view makeToast:WFCString(@"CollectionTitleRequired") duration:2 position:CSToastPositionCenter];
        return;
    }

    // 获取参数
    NSString *desc = [self.descTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *template = [self.templateTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    int expireType = (int)self.expireTypeControl.selectedSegmentIndex;
    long expireAt = 0;
    if (expireType == 1) {
        expireAt = (long)([self.expireDatePicker.date timeIntervalSince1970] * 1000);
        // 验证过期时间必须大于当前时间
        if (expireAt <= (long)([NSDate date].timeIntervalSince1970 * 1000)) {
            [self.view makeToast:WFCString(@"ExpireTimeInvalid") duration:2 position:CSToastPositionCenter];
            return;
        }
    }


    // 显示加载中
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Creating");

    // 调用服务创建接龙
    id<WFCUCollectionService> service = [WFCUConfigManager globalManager].collectionServiceProvider;
    if (!service) {
        [hud hideAnimated:YES];
        [self.view makeToast:WFCString(@"CollectionServiceNotConfigured") duration:2 position:CSToastPositionCenter];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [service createCollection:self.conversation.target
                        title:title
                         desc:desc.length > 0 ? desc : nil
                     template:template.length > 0 ? template : nil
                   expireType:expireType
                     expireAt:expireAt
              maxParticipants:0
                      success:^(WFCUCollection *collection) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            if (weakSelf) {
                if ([weakSelf.delegate respondsToSelector:@selector(createCollectionViewController:didCreateCollection:)]) {
                    [weakSelf.delegate createCollectionViewController:weakSelf didCreateCollection:collection];
                }
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            NSString *errorMsg = message ?: WFCString(@"CreateFailed");
            [weakSelf.view makeToast:errorMsg duration:2 position:CSToastPositionCenter];
        });
    }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.titleTextField) {
        [self.descTextView becomeFirstResponder];
    } else if (textField == self.templateTextField) {
        [textField resignFirstResponder];
    }
    return YES;
}

@end
