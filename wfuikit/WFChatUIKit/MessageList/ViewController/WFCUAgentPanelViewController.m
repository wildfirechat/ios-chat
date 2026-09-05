//
//  WFCUAgentPanelViewController.m
//  WFChatUIKit
//
//  Agent/AI 会话设置面板实现（静默通道）。
//  打开：发 Agent_Command(207) query（组合查询）→ 插件聚合面板数据写 scope=31 type=3
//  → 本端读 type=3 渲染（model/effort 下拉选项+当前值、sandbox 水平单选、plan switch、
//  cwd 当前值+「切换」弹窗选目录）。
//  操作：发 207 set（cmd=命令文本，如 "/model deepseek-official/xxx"），插件执行后写
//  type=1 lastChange（标题状态行可见）+ 刷新 type=3；本端监听 kSettingUpdated 重读 type=3。
//  207 为透明消息（不存储、不显示、不计未读），全部交互不落消息流；不解析机器人回复文本。
//
//  交互对齐统一风格：
//  - 模型/推理等级：下拉选择（iOS 14+ UIMenu；iOS 12/13 用 UIPickerView 弹层兜底；
//    候选列表 + 当前值，当前值不在候选时补入并标注"（当前）"；选中发 207 set /model|/effort）
//  - 工作目录：显示当前值 + 「切换」按钮，点切换弹出独立目录选择界面（候选来自 type=3 dirs，
//    选中发 207 set /cwd），不再是内联平铺列表
//  - 沙箱模式：三个水平单选按钮（只读/仅写工作区/完全放开），选中发 207 set /sandbox
//  - 计划模式：UISwitch 开关，发 /plan on|off
//  - 底部：压缩上下文 / 重置会话 / 销毁会话（红色实底，强警告确认后发 /destroy）
//

#import "WFCUAgentPanelViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatClient/WFCCAgentMessageContents.h>
#import "WFCUAgentState.h"
#import "WFCUUtilities.h"
#import "WFCUConfigManager.h"
#import "UIColor+YH.h"

//选项行按钮：携带 optionValue 以便点击回调识别（目录选择界面行复用）
@interface WFCUAgentOptionButton : UIButton
@property (nonatomic, strong)NSString *optionValue;
- (void)setOptionSelected:(BOOL)selected;
@end

@implementation WFCUAgentOptionButton
- (void)setOptionSelected:(BOOL)selected {
    if (selected) {
        self.backgroundColor = [WFCUAgentState accentColor];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        self.backgroundColor = [UIColor colorWithHexString:@"0xf2f3f5"];
        [self setTitleColor:[UIColor colorWithHexString:@"0x333333"] forState:UIControlStateNormal];
    }
}
@end

//沙箱模式兜底选项（type=3 sandbox.options 缺失时使用）
static NSArray<NSDictionary<NSString *, NSString *> *> *defaultSandboxOptions(void) {
    return @[
        @{@"value": @"read-only", @"label": @"read-only（只读）"},
        @{@"value": @"workspace-write", @"label": @"workspace-write（仅写工作区）"},
        @{@"value": @"danger-full-access", @"label": @"danger-full-access（完全放开）"},
    ];
}

//沙箱模式短文案（水平单选按钮用，与 PC/Android 端一致）
static NSString *agentSandboxShortLabel(NSString *value) {
    if ([value isEqualToString:@"read-only"]) {
        return @"只读";
    }
    if ([value isEqualToString:@"workspace-write"]) {
        return @"仅写工作区";
    }
    if ([value isEqualToString:@"danger-full-access"]) {
        return @"完全放开";
    }
    return value;
}

#pragma mark - 下拉选择控件

//下拉选择：iOS 14+ 用 UIMenu（原生下拉）；iOS 12/13 用 UIPickerView 弹层兜底。
//选项为 @{@"value":.., @"label":..}；selectedValue 不在 options 时由 updateContent
//补入并标注"（当前）"，保证下拉框始终展示真实当前值。
@interface WFCUAgentDropdownButton : UIButton
@property (nonatomic, strong)NSArray<NSDictionary<NSString *, NSString *> *> *options;
@property (nonatomic, copy)NSString *selectedValue;
@property (nonatomic, copy)NSString *placeholder;
@property (nonatomic, weak)UIViewController *dropPresenter; //iOS<14 弹 UIPickerView 用
@property (nonatomic, copy)void (^onSelect)(NSString *value);
- (void)updateContent;
@end

//UIPickerView 弹层（iOS 12/13 下拉兜底）：底部卡片 + 取消/完成
@interface WFCUAgentPickerViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, copy)void (^onSelect)(NSString *value);
- (instancetype)initWithOptions:(NSArray<NSDictionary<NSString *, NSString *> *> *)options selectedValue:(NSString *)selectedValue;
@end

#pragma mark - 单选按钮

//水平单选按钮：圆圈指示 + 文字（沙箱模式三选一）
@interface WFCUAgentRadioButton : UIControl
@property (nonatomic, copy)NSString *optionValue;
@property (nonatomic, assign)BOOL radioSelected;
@property (nonatomic, copy)NSString *titleText;
@end

#pragma mark - 工作目录选择弹窗

//独立目录选择界面（底部卡片）：候选来自 type=3 dirs；监听设置更新自动刷新
@interface WFCUAgentCwdPickerViewController : UIViewController
@property (nonatomic, copy)NSDictionary *(^dataProvider)(void); //@{@"dirs": NSArray, @"current": NSString}
@property (nonatomic, copy)void (^onSelect)(NSString *dir);
@end

#pragma mark - 面板

@interface WFCUAgentPanelViewController ()
@property (nonatomic, strong)WFCCConversation *conversation;
//目标机器人 uid（多机器人会话寻址：完整 robot_xxx_yyy，勿截断；空=会话默认机器人）
@property (nonatomic, copy)NSString *robotUid;

//数据（全部来自 scope=31 type=3 面板数据；207 set 后由 kSettingUpdated 重读刷新）
@property (nonatomic, assign)BOOL applying;
@property (nonatomic, strong)NSString *currentModel;
@property (nonatomic, strong)NSString *currentEffort;
@property (nonatomic, strong)NSString *currentCwd;
@property (nonatomic, strong)NSString *currentSandbox;
@property (nonatomic, assign)BOOL planOn;
@property (nonatomic, strong)NSArray<NSDictionary<NSString *, NSString *> *> *modelOptions;   //@{@"value": @"provider/id", @"label": ...}
@property (nonatomic, strong)NSArray<NSDictionary<NSString *, NSString *> *> *effortOptions;  //@{@"value": id, @"label": id}
@property (nonatomic, strong)NSArray<NSDictionary<NSString *, NSString *> *> *sandboxOptions; //@{@"value": mode, @"label": ...}
@property (nonatomic, strong)NSArray<NSString *> *cwdCandidates;

//UI 骨架
@property (nonatomic, strong)UIView *cardView;
@property (nonatomic, strong)UIScrollView *scrollView;
@property (nonatomic, strong)UIView *contentView;
@property (nonatomic, strong)UIView *footerView;
@property (nonatomic, strong)UILabel *modelTitleLabel;
@property (nonatomic, strong)WFCUAgentDropdownButton *modelDropdown;
@property (nonatomic, strong)UILabel *effortTitleLabel;
@property (nonatomic, strong)WFCUAgentDropdownButton *effortDropdown;
@property (nonatomic, strong)UILabel *cwdTitleLabel;
@property (nonatomic, strong)UILabel *cwdValueLabel;
@property (nonatomic, strong)UIView *cwdRowView;
@property (nonatomic, strong)UIButton *cwdSwitchBtn;
@property (nonatomic, strong)UILabel *cwdHintLabel;
@property (nonatomic, strong)UILabel *sandboxTitleLabel;
@property (nonatomic, strong)UIView *sandboxContainer;
@property (nonatomic, strong)NSMutableArray<WFCUAgentRadioButton *> *sandboxRadios;
@property (nonatomic, strong)UILabel *planTitleLabel;
@property (nonatomic, strong)UISwitch *planSwitch;
@property (nonatomic, strong)UILabel *planDescLabel;
@property (nonatomic, strong)UIButton *compactBtn;
@property (nonatomic, strong)UIButton *resetBtn;
@property (nonatomic, strong)UIButton *destroyBtn;

@property (nonatomic, strong)NSTimer *applyingTimer;
@end

#pragma mark - 下拉选择控件实现

@implementation WFCUAgentDropdownButton {
    UILabel *_chevronLabel;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithHexString:@"0xf2f3f5"];
        self.layer.cornerRadius = 6;
        self.clipsToBounds = YES;
        self.titleLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:13]];
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        [self setTitleColor:[UIColor colorWithHexString:@"0x333333"] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor colorWithHexString:@"0x999999"] forState:UIControlStateDisabled];
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.titleEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 28);
        [self addTarget:self action:@selector(onTapped) forControlEvents:UIControlEventTouchUpInside];

        _chevronLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _chevronLabel.text = @"▾";
        _chevronLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:12]];
        _chevronLabel.textColor = [UIColor colorWithHexString:@"0x999999"];
        _chevronLabel.textAlignment = NSTextAlignmentRight;
        _chevronLabel.userInteractionEnabled = NO;
        [self addSubview:_chevronLabel];
    }
    return self;
}

//展示选项 = 候选 + 当前值（不在候选时补入并标注"（当前）"）
- (NSArray<NSDictionary<NSString *, NSString *> *> *)displayOptions {
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *arr = [NSMutableArray arrayWithArray:self.options ?: @[]];
    BOOL found = NO;
    for (NSDictionary *o in arr) {
        if ([o[@"value"] isEqualToString:self.selectedValue]) {
            found = YES;
            break;
        }
    }
    if (self.selectedValue.length && !found) {
        [arr addObject:@{@"value": self.selectedValue, @"label": [NSString stringWithFormat:@"%@（当前）", self.selectedValue]}];
    }
    return arr;
}

- (void)updateContent {
    NSArray<NSDictionary<NSString *, NSString *> *> *opts = [self displayOptions];
    //标题：当前值对应 label；否则占位
    NSString *title = nil;
    for (NSDictionary *o in opts) {
        if ([o[@"value"] isEqualToString:self.selectedValue]) {
            title = o[@"label"];
            break;
        }
    }
    [self setTitle:(title.length ? title : (self.placeholder.length ? self.placeholder : @"请选择")) forState:UIControlStateNormal];

    if (@available(iOS 14.0, *)) {
        self.showsMenuAsPrimaryAction = YES;
        NSMutableArray<UIAction *> *actions = [NSMutableArray array];
        if (!opts.count) {
            UIAction *emptyAction = [UIAction actionWithTitle:@"暂无可用选项" image:nil identifier:nil handler:^(__kindof UIAction *a) {}];
            emptyAction.attributes = UIMenuElementAttributesDisabled;
            [actions addObject:emptyAction];
        }
        for (NSDictionary *o in opts) {
            NSString *value = o[@"value"];
            NSString *label = o[@"label"] ?: value;
            BOOL isCurrent = [value isEqualToString:self.selectedValue];
            __weak typeof(self) ws = self;
            UIAction *action = [UIAction actionWithTitle:label
                                                   image:(isCurrent ? [UIImage systemImageNamed:@"checkmark"] : nil)
                                              identifier:nil
                                                 handler:^(__kindof UIAction *a) {
                __strong typeof(ws) ss = ws;
                if (!ss || [ss.selectedValue isEqualToString:value]) {
                    return;
                }
                ss.selectedValue = value;
                [ss updateContent];
                if (ss.onSelect) {
                    ss.onSelect(value);
                }
            }];
            [actions addObject:action];
        }
        self.menu = [UIMenu menuWithChildren:actions];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _chevronLabel.frame = CGRectMake(self.bounds.size.width - 26, 0, 18, self.bounds.size.height);
}

- (void)onTapped {
    if (!self.enabled) {
        return;
    }
    if (@available(iOS 14.0, *)) {
        return; //UIMenu 由系统弹出
    }
    //iOS 12/13 兜底：弹 UIPickerView 选择层
    UIViewController *presenter = self.dropPresenter;
    if (!presenter) {
        UIResponder *r = self.nextResponder;
        while (r) {
            if ([r isKindOfClass:[UIViewController class]]) {
                presenter = (UIViewController *)r;
                break;
            }
            r = r.nextResponder;
        }
    }
    if (!presenter) {
        return;
    }
    WFCUAgentPickerViewController *picker = [[WFCUAgentPickerViewController alloc] initWithOptions:[self displayOptions] selectedValue:self.selectedValue];
    __weak typeof(self) ws = self;
    picker.onSelect = ^(NSString *value) {
        __strong typeof(ws) ss = ws;
        if (!ss || [ss.selectedValue isEqualToString:value]) {
            return;
        }
        ss.selectedValue = value;
        [ss updateContent];
        if (ss.onSelect) {
            ss.onSelect(value);
        }
    };
    [presenter presentViewController:picker animated:YES completion:nil];
}

@end

#pragma mark - UIPickerView 弹层实现（iOS 12/13 兜底）

@implementation WFCUAgentPickerViewController {
    NSArray<NSDictionary<NSString *, NSString *> *> *_options;
    NSString *_selectedValue;
    UIView *_cardView;
    UIPickerView *_pickerView;
}

- (instancetype)initWithOptions:(NSArray<NSDictionary<NSString *, NSString *> *> *)options selectedValue:(NSString *)selectedValue {
    self = [super init];
    if (self) {
        _options = options ?: @[];
        _selectedValue = selectedValue;
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];

    //点背景关闭
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePanel)];
    [self.view addGestureRecognizer:tap];

    CGFloat cardH = 260;
    _cardView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - cardH, self.view.bounds.size.width, cardH)];
    _cardView.backgroundColor = [UIColor whiteColor];
    _cardView.layer.cornerRadius = 12;
    if (@available(iOS 11.0, *)) {
        _cardView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    }
    _cardView.clipsToBounds = YES;
    [self.view addSubview:_cardView];

    //工具栏：取消 / 完成
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(8, 0, 64, 44);
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor colorWithHexString:@"0x666666"] forState:UIControlStateNormal];
    cancelBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [cancelBtn addTarget:self action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
    [_cardView addSubview:cancelBtn];

    UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    doneBtn.frame = CGRectMake(_cardView.bounds.size.width - 72, 0, 64, 44);
    [doneBtn setTitle:@"完成" forState:UIControlStateNormal];
    [doneBtn setTitleColor:[WFCUAgentState accentColor] forState:UIControlStateNormal];
    doneBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [doneBtn addTarget:self action:@selector(onDone) forControlEvents:UIControlEventTouchUpInside];
    [_cardView addSubview:doneBtn];

    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 43.5, _cardView.bounds.size.width, 0.5)];
    line.backgroundColor = [UIColor colorWithHexString:@"0xededed"];
    [_cardView addSubview:line];

    _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 44, _cardView.bounds.size.width, cardH - 44)];
    _pickerView.dataSource = self;
    _pickerView.delegate = self;
    [_cardView addSubview:_pickerView];

    //预选当前值
    for (NSInteger i = 0; i < (NSInteger)_options.count; i++) {
        if ([_options[i][@"value"] isEqualToString:_selectedValue]) {
            [_pickerView selectRow:i inComponent:0 animated:NO];
            break;
        }
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _options.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSDictionary *o = _options[row];
    return o[@"label"] ?: o[@"value"];
}

- (void)onDone {
    NSInteger row = [_pickerView selectedRowInComponent:0];
    if (row >= 0 && row < _options.count) {
        NSString *value = _options[row][@"value"];
        if (value.length && self.onSelect) {
            self.onSelect(value);
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)closePanel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

#pragma mark - 单选按钮实现

@implementation WFCUAgentRadioButton {
    UIView *_ringView;
    UIView *_dotView;
    UILabel *_titleLabel;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _ringView = [[UIView alloc] initWithFrame:CGRectZero];
        _ringView.layer.cornerRadius = 9;
        _ringView.layer.borderWidth = 1.5;
        _ringView.userInteractionEnabled = NO;
        [self addSubview:_ringView];

        _dotView = [[UIView alloc] initWithFrame:CGRectZero];
        _dotView.layer.cornerRadius = 4;
        _dotView.userInteractionEnabled = NO;
        [self addSubview:_dotView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:12]];
        _titleLabel.numberOfLines = 2;
        _titleLabel.userInteractionEnabled = NO;
        [self addSubview:_titleLabel];

        [self applyStyle];
    }
    return self;
}

- (void)setTitleText:(NSString *)titleText {
    _titleText = titleText;
    _titleLabel.text = titleText;
}

- (void)setRadioSelected:(BOOL)radioSelected {
    _radioSelected = radioSelected;
    [self applyStyle];
}

- (void)applyStyle {
    UIColor *accent = [WFCUAgentState accentColor];
    _ringView.layer.borderColor = (self.radioSelected ? accent : [UIColor colorWithHexString:@"0xc8c8c8"]).CGColor;
    _dotView.backgroundColor = self.radioSelected ? accent : [UIColor clearColor];
    _titleLabel.textColor = self.radioSelected ? [UIColor colorWithHexString:@"0x333333"] : [UIColor colorWithHexString:@"0x888888"];
    _titleLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:12] weight:(self.radioSelected ? UIFontWeightMedium : UIFontWeightRegular)];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat h = self.bounds.size.height;
    _ringView.frame = CGRectMake(4, (h - 18) / 2.0, 18, 18);
    _dotView.frame = CGRectMake(4 + (18 - 8) / 2.0, (h - 8) / 2.0, 8, 8);
    _titleLabel.frame = CGRectMake(28, 0, MAX(self.bounds.size.width - 32, 0), h);
}

@end

#pragma mark - 工作目录选择弹窗实现

@implementation WFCUAgentCwdPickerViewController {
    UIView *_cardView;
    UIScrollView *_scrollView;
    UIView *_contentView;
    NSMutableArray<WFCUAgentOptionButton *> *_rowButtons;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        _rowButtons = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];

    //点背景关闭
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePanel)];
    [self.view addGestureRecognizer:tap];

    //面板数据刷新（207 query/set 后写 type=3）时重读目录候选
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSettingUpdated:) name:kSettingUpdated object:nil];

    CGFloat cardH = MIN(self.view.bounds.size.height * 0.6, 480);
    _cardView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - cardH, self.view.bounds.size.width, cardH)];
    _cardView.backgroundColor = [UIColor whiteColor];
    _cardView.layer.cornerRadius = 16;
    if (@available(iOS 11.0, *)) {
        _cardView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    }
    _cardView.clipsToBounds = YES;
    [self.view addSubview:_cardView];

    //标题行
    CGFloat headerH = 48;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _cardView.bounds.size.width, headerH)];
    header.backgroundColor = [UIColor whiteColor];
    [_cardView addSubview:header];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, header.bounds.size.width - 80, headerH)];
    titleLabel.text = @"选择工作目录";
    titleLabel.font = [UIFont boldSystemFontOfSize:[WFCUConfigManager scaledSize:16]];
    titleLabel.textColor = [UIColor colorWithHexString:@"0x222222"];
    [header addSubview:titleLabel];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(header.bounds.size.width - 44, 4, 40, 40);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor colorWithHexString:@"0x666666"] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:18]];
    [closeBtn addTarget:self action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:closeBtn];

    UIView *headerLine = [[UIView alloc] initWithFrame:CGRectMake(0, headerH - 0.5, header.bounds.size.width, 0.5)];
    headerLine.backgroundColor = [UIColor colorWithHexString:@"0xededed"];
    [header addSubview:headerLine];

    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, headerH, _cardView.bounds.size.width, cardH - headerH)];
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.showsVerticalScrollIndicator = YES;
    [_cardView addSubview:_scrollView];

    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _scrollView.bounds.size.width, 0)];
    [_scrollView addSubview:_contentView];

    [self rebuildRows];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat cardH = MIN(self.view.bounds.size.height * 0.6, 480);
    _cardView.frame = CGRectMake(0, self.view.bounds.size.height - cardH, self.view.bounds.size.width, cardH);
    _scrollView.frame = CGRectMake(0, 48, _cardView.bounds.size.width, cardH - 48);
    if (_contentView && _contentView.bounds.size.width != _scrollView.bounds.size.width) {
        _contentView.frame = CGRectMake(0, 0, _scrollView.bounds.size.width, _contentView.bounds.size.height);
        [self rebuildRows];
    }
}

//type=3 刷新（207 query/set 后）重读目录候选
- (void)onSettingUpdated:(NSNotification *)notification {
    [self rebuildRows];
}

//重建目录候选行（数据来自面板 dataProvider：dirs + current）
- (void)rebuildRows {
    for (UIView *sub in _contentView.subviews) {
        [sub removeFromSuperview];
    }
    [_rowButtons removeAllObjects];

    NSDictionary *data = self.dataProvider ? self.dataProvider() : nil;
    NSArray *dirs = [data[@"dirs"] isKindOfClass:[NSArray class]] ? data[@"dirs"] : @[];
    NSString *current = [data[@"current"] isKindOfClass:[NSString class]] ? data[@"current"] : @"";

    CGFloat w = MAX(_contentView.bounds.size.width, 200);
    CGFloat y = 12;
    if (!dirs.count) {
        UILabel *emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, y, w - 32, 40)];
        emptyLabel.text = @"未获取到目录列表，可稍后重试";
        emptyLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:12]];
        emptyLabel.textColor = [UIColor colorWithHexString:@"0x999999"];
        [_contentView addSubview:emptyLabel];
        y += 52;
    } else {
        CGFloat rowH = 42;
        CGFloat gap = 6;
        for (NSString *dir in dirs) {
            NSString *display = dir;
            if (dir.length && [dir isEqualToString:current]) {
                display = [NSString stringWithFormat:@"%@（当前）", dir];
            }
            WFCUAgentOptionButton *btn = [[WFCUAgentOptionButton alloc] initWithFrame:CGRectZero];
            btn.optionValue = dir;
            [btn setTitle:[NSString stringWithFormat:@"📂 %@", display] forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:13]];
            btn.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
            btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            btn.titleEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
            btn.layer.cornerRadius = 6;
            [btn setOptionSelected:[dir isEqualToString:current]];
            [btn addTarget:self action:@selector(onSelectRow:) forControlEvents:UIControlEventTouchUpInside];
            btn.frame = CGRectMake(16, y, w - 32, rowH);
            [_contentView addSubview:btn];
            [_rowButtons addObject:btn];
            y += rowH + gap;
        }
        y += 6;
    }
    _contentView.frame = CGRectMake(0, 0, w, y);
    _scrollView.contentSize = CGSizeMake(w, y);
}

- (void)onSelectRow:(WFCUAgentOptionButton *)sender {
    if (!sender.optionValue.length) {
        return;
    }
    NSString *dir = sender.optionValue;
    if (self.onSelect) {
        self.onSelect(dir);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)closePanel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

#pragma mark - 面板实现

@implementation WFCUAgentPanelViewController

- (instancetype)initWithConversation:(WFCCConversation *)conversation {
    return [self initWithConversation:conversation robotUid:nil];
}

- (instancetype)initWithConversation:(WFCCConversation *)conversation robotUid:(NSString *)robotUid {
    self = [super init];
    if (self) {
        self.conversation = conversation;
        self.robotUid = robotUid;
        self.modelOptions = @[];
        self.effortOptions = @[];
        self.sandboxOptions = defaultSandboxOptions();
        self.cwdCandidates = @[];
        self.sandboxRadios = [NSMutableArray array];
        //底部弹窗：透明背景 + 底部卡片，present 时原会话页可见
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];

    //点背景关闭
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundTapped)];
    [self.view addGestureRecognizer:tap];

    //scope=31 设置变化（插件执行 207 query/set 后写 type=3 / type=1，kSettingUpdated 不带 scope/key，重读当前会话 key）
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSettingUpdated:) name:kSettingUpdated object:nil];

    [self setupCard];
    //先读已有面板数据（若有）渲染，再发 207 query 组合查询刷新
    [self loadPanelDataFromUserSetting];
    [self sendAgentCommand:@"query" cmd:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    //卡片贴底，随旋转/横竖屏自适应
    CGFloat safeBottom = [WFCUUtilities wf_safeDistanceBottom];
    CGFloat headerH = 48;
    CGFloat footerH = 64 + safeBottom;
    CGFloat cardHeight = MIN(self.view.bounds.size.height * 0.8, 660);
    self.cardView.frame = CGRectMake(0, self.view.bounds.size.height - cardHeight, self.view.bounds.size.width, cardHeight);
    self.footerView.frame = CGRectMake(0, cardHeight - footerH, self.cardView.bounds.size.width, footerH);
    self.scrollView.frame = CGRectMake(0, headerH, self.cardView.bounds.size.width, cardHeight - headerH - footerH);
    //宽度变化时重排内容（旋转横竖屏）
    if (self.contentView && self.contentView.bounds.size.width != self.scrollView.bounds.size.width) {
        self.contentView.frame = CGRectMake(0, 0, self.scrollView.bounds.size.width, self.contentView.bounds.size.height);
        [self layoutAll];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.applyingTimer invalidate];
}

#pragma mark - UI 搭建

- (void)setupCard {
    CGFloat safeBottom = [WFCUUtilities wf_safeDistanceBottom];
    CGFloat cardH = MIN(self.view.bounds.size.height * 0.8, 660);
    self.cardView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - cardH, self.view.bounds.size.width, cardH)];
    self.cardView.backgroundColor = [UIColor whiteColor];
    self.cardView.layer.cornerRadius = 16;
    if (@available(iOS 11.0, *)) {
        self.cardView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    }
    self.cardView.clipsToBounds = YES;
    [self.view addSubview:self.cardView];

    //标题行
    CGFloat headerH = 48;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.cardView.bounds.size.width, headerH)];
    header.backgroundColor = [UIColor whiteColor];
    [self.cardView addSubview:header];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, header.bounds.size.width - 80, headerH)];
    //多机器人：标题显示目标机器人名（用户信息缺失时回退完整 uid）
    NSString *titleText = @"🤖 AI 会话设置";
    if (self.robotUid.length) {
        titleText = [NSString stringWithFormat:@"🤖 AI 会话设置 · %@", [WFCUAgentState agentRobotName:self.robotUid]];
    }
    titleLabel.text = titleText;
    titleLabel.font = [UIFont boldSystemFontOfSize:[WFCUConfigManager scaledSize:16]];
    titleLabel.textColor = [UIColor colorWithHexString:@"0x222222"];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [header addSubview:titleLabel];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(header.bounds.size.width - 44, 4, 40, 40);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor colorWithHexString:@"0x666666"] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:18]];
    [closeBtn addTarget:self action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:closeBtn];

    UIView *headerLine = [[UIView alloc] initWithFrame:CGRectMake(0, headerH - 0.5, header.bounds.size.width, 0.5)];
    headerLine.backgroundColor = [UIColor colorWithHexString:@"0xededed"];
    [header addSubview:headerLine];

    //底部操作行
    CGFloat footerH = 64 + safeBottom;
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, headerH, self.cardView.bounds.size.width, cardH - headerH - footerH)];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = YES;
    [self.cardView addSubview:self.scrollView];

    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.bounds.size.width, 0)];
    [self.scrollView addSubview:self.contentView];

    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, cardH - footerH, self.cardView.bounds.size.width, footerH)];
    self.footerView = footer;
    footer.backgroundColor = [UIColor whiteColor];
    UIView *footerLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, footer.bounds.size.width, 0.5)];
    footerLine.backgroundColor = [UIColor colorWithHexString:@"0xededed"];
    [footer addSubview:footerLine];

    CGFloat btnPadding = 16;
    CGFloat btnWidth = (footer.bounds.size.width - btnPadding * 4) / 3.0;
    CGFloat btnHeight = 40;

    self.compactBtn = [self makeActionButtonWithTitle:@"压缩上下文" color:[WFCUAgentState accentColor] selector:@selector(onCompact)];
    self.compactBtn.frame = CGRectMake(btnPadding, 12, btnWidth, btnHeight);
    [footer addSubview:self.compactBtn];

    //重置：描边红（可恢复，次级危险）；销毁：红色实底（不可恢复，最醒目）
    self.resetBtn = [self makeOutlineActionButtonWithTitle:@"重置会话" color:[UIColor colorWithHexString:@"0xE5484D"] selector:@selector(onReset)];
    self.resetBtn.frame = CGRectMake(btnPadding * 2 + btnWidth, 12, btnWidth, btnHeight);
    [footer addSubview:self.resetBtn];

    //销毁会话：危险操作不随操作冷却禁用（始终可点），点击弹强警告确认，确认后才发送
    self.destroyBtn = [self makeActionButtonWithTitle:@"销毁会话" color:[UIColor colorWithHexString:@"0xE5484D"] selector:@selector(onDestroy)];
    self.destroyBtn.frame = CGRectMake(btnPadding * 3 + btnWidth * 2, 12, btnWidth, btnHeight);
    [footer addSubview:self.destroyBtn];

    [self.cardView addSubview:footer];

    [self buildContent];
}

- (UIButton *)makeActionButtonWithTitle:(NSString *)title color:(UIColor *)color selector:(SEL)selector {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:14] weight:UIFontWeightMedium];
    btn.backgroundColor = color;
    btn.layer.cornerRadius = 6;
    [btn addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

//描边按钮（次级危险操作，如重置）：白底 + 色描边 + 色文字
- (UIButton *)makeOutlineActionButtonWithTitle:(NSString *)title color:(UIColor *)color selector:(SEL)selector {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:color forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:14] weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor whiteColor];
    btn.layer.borderColor = color.CGColor;
    btn.layer.borderWidth = 1;
    btn.layer.cornerRadius = 6;
    [btn addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (UILabel *)makeSectionTitle:(NSString *)text {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = text;
    label.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:13] weight:UIFontWeightMedium];
    label.textColor = [UIColor colorWithHexString:@"0x666666"];
    return label;
}

//一次性创建全部区块视图；之后只改 frame/内容不重建
- (void)buildContent {
    //1. 模型（下拉选择）
    self.modelTitleLabel = [self makeSectionTitle:@"模型"];
    [self.contentView addSubview:self.modelTitleLabel];

    self.modelDropdown = [[WFCUAgentDropdownButton alloc] initWithFrame:CGRectZero];
    self.modelDropdown.dropPresenter = self;
    self.modelDropdown.placeholder = @"正在获取模型列表…";
    __weak typeof(self) ws = self;
    self.modelDropdown.onSelect = ^(NSString *value) {
        [ws onSelectModelValue:value];
    };
    [self.contentView addSubview:self.modelDropdown];

    //2. 推理等级（下拉选择）
    self.effortTitleLabel = [self makeSectionTitle:@"推理等级"];
    [self.contentView addSubview:self.effortTitleLabel];

    self.effortDropdown = [[WFCUAgentDropdownButton alloc] initWithFrame:CGRectZero];
    self.effortDropdown.dropPresenter = self;
    self.effortDropdown.placeholder = @"正在获取等级列表…";
    self.effortDropdown.onSelect = ^(NSString *value) {
        [ws onSelectEffortValue:value];
    };
    [self.contentView addSubview:self.effortDropdown];

    //3. 工作目录（当前值 + 「切换」按钮；点切换弹独立目录选择界面）
    self.cwdTitleLabel = [self makeSectionTitle:@"工作目录"];
    [self.contentView addSubview:self.cwdTitleLabel];

    self.cwdRowView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:self.cwdRowView];

    self.cwdValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.cwdValueLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:12]];
    self.cwdValueLabel.textColor = [UIColor colorWithHexString:@"0x888888"];
    [self.cwdRowView addSubview:self.cwdValueLabel];

    self.cwdSwitchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cwdSwitchBtn setTitle:@"切换" forState:UIControlStateNormal];
    [self.cwdSwitchBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.cwdSwitchBtn.titleLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:13]];
    self.cwdSwitchBtn.backgroundColor = [WFCUAgentState accentColor];
    self.cwdSwitchBtn.layer.cornerRadius = 6;
    [self.cwdSwitchBtn addTarget:self action:@selector(onOpenCwdPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.cwdRowView addSubview:self.cwdSwitchBtn];

    self.cwdHintLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.cwdHintLabel.text = @"切换目录 = 新会话（上下文清空）；相对路径按项目根目录解析";
    self.cwdHintLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:11]];
    self.cwdHintLabel.textColor = [UIColor colorWithHexString:@"0x999999"];
    [self.contentView addSubview:self.cwdHintLabel];

    //4. 沙箱模式（三个水平单选按钮；选项来自 type=3 sandbox.options，缺省时用内置兜底）
    self.sandboxTitleLabel = [self makeSectionTitle:@"沙箱模式"];
    [self.contentView addSubview:self.sandboxTitleLabel];

    self.sandboxContainer = [[UIView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:self.sandboxContainer];

    //5. 计划模式
    self.planTitleLabel = [self makeSectionTitle:@"计划模式"];
    [self.contentView addSubview:self.planTitleLabel];

    self.planSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    [self.planSwitch addTarget:self action:@selector(onTogglePlan) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.planSwitch];

    self.planDescLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.planDescLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:12]];
    self.planDescLabel.textColor = [UIColor colorWithHexString:@"0x666666"];
    [self.contentView addSubview:self.planDescLabel];

    //模型/推理等级/沙箱选项（当前数据为空，仅占位）
    [self refreshModelDropdown];
    [self refreshEffortDropdown];
    [self rebuildSandboxOptions];
    [self refreshCurrentValues];
    [self layoutAll];
}

//刷新模型下拉：候选 + 当前值（updateContent 内部处理"当前值不在候选时补入并标注（当前）"）
- (void)refreshModelDropdown {
    self.modelDropdown.options = self.modelOptions ?: @[];
    self.modelDropdown.selectedValue = self.currentModel ?: @"";
    [self.modelDropdown updateContent];
}

//刷新推理等级下拉
- (void)refreshEffortDropdown {
    self.effortDropdown.options = self.effortOptions ?: @[];
    self.effortDropdown.selectedValue = self.currentEffort ?: @"";
    [self.effortDropdown updateContent];
}

//重建沙箱模式水平单选按钮（三个，横向均分）
- (void)rebuildSandboxOptions {
    for (UIView *sub in self.sandboxContainer.subviews) {
        [sub removeFromSuperview];
    }
    [self.sandboxRadios removeAllObjects];

    NSArray *opts = self.sandboxOptions.count ? self.sandboxOptions : defaultSandboxOptions();
    NSInteger i = 0;
    for (NSDictionary *o in opts) {
        NSString *value = [o[@"value"] isKindOfClass:[NSString class]] ? o[@"value"] : nil;
        if (!value.length) {
            continue;
        }
        WFCUAgentRadioButton *radio = [[WFCUAgentRadioButton alloc] initWithFrame:CGRectZero];
        radio.optionValue = value;
        radio.titleText = agentSandboxShortLabel(value);
        [radio addTarget:self action:@selector(onSelectSandboxRadio:) forControlEvents:UIControlEventTouchUpInside];
        [self.sandboxContainer addSubview:radio];
        [self.sandboxRadios addObject:radio];
        i++;
    }
    [self refreshCurrentValues];
}

//按当前数据自上而下重排 contentView 全部区块
- (void)layoutAll {
    CGFloat contentW = self.contentView.bounds.size.width;
    CGFloat x = 16;
    CGFloat sectionGap = 18;
    CGFloat y = 12;

    //1. 模型
    self.modelTitleLabel.frame = CGRectMake(x, y, contentW - 32, 20);
    y += 20 + 6;

    self.modelDropdown.frame = CGRectMake(x, y, contentW - 32, 38);
    y += 38;

    //2. 推理等级
    y += sectionGap;
    self.effortTitleLabel.frame = CGRectMake(x, y, contentW - 32, 20);
    y += 20 + 6;

    self.effortDropdown.frame = CGRectMake(x, y, contentW - 32, 38);
    y += 38;

    //3. 工作目录
    y += sectionGap;
    self.cwdTitleLabel.frame = CGRectMake(x, y, contentW - 32, 20);
    y += 20 + 6;

    //当前值 + 切换按钮一行
    CGFloat cwdRowH = 34;
    self.cwdRowView.frame = CGRectMake(x, y, contentW - 32, cwdRowH);
    self.cwdValueLabel.frame = CGRectMake(0, 0, contentW - 32 - 64 - 8, cwdRowH);
    self.cwdSwitchBtn.frame = CGRectMake(contentW - 32 - 64, 0, 64, cwdRowH);
    y += cwdRowH + 6;

    self.cwdHintLabel.frame = CGRectMake(x, y, contentW - 32, 18);
    y += 24;

    //4. 沙箱模式（三个水平单选）
    y += sectionGap - 10;
    self.sandboxTitleLabel.frame = CGRectMake(x, y, contentW - 32, 20);
    y += 20 + 6;

    self.sandboxContainer.frame = CGRectMake(x, y, contentW - 32, 40);
    CGFloat radioGap = 8;
    CGFloat radioW = (contentW - 32 - radioGap * 2) / 3.0;
    NSInteger idx = 0;
    for (WFCUAgentRadioButton *radio in self.sandboxRadios) {
        radio.frame = CGRectMake(idx * (radioW + radioGap), 0, radioW, 40);
        idx++;
    }
    y += 40;

    //5. 计划模式
    y += sectionGap;
    self.planTitleLabel.frame = CGRectMake(x, y, contentW - 32, 20);
    y += 20 + 6;

    self.planSwitch.frame = CGRectMake(x, y, self.planSwitch.bounds.size.width, self.planSwitch.bounds.size.height);
    self.planDescLabel.frame = CGRectMake(x + self.planSwitch.bounds.size.width + 10, y + 4, contentW - 32 - self.planSwitch.bounds.size.width - 10, 24);
    y += 40;

    self.contentView.frame = CGRectMake(0, 0, contentW, y + 12);
    self.scrollView.contentSize = CGSizeMake(contentW, y + 12);
}

//刷新当前值：下拉标题/选中态、单选选中、cwd 文案、plan 开关
- (void)refreshCurrentValues {
    [self.modelDropdown updateContent];
    [self.effortDropdown updateContent];
    for (WFCUAgentRadioButton *radio in self.sandboxRadios) {
        radio.radioSelected = [radio.optionValue isEqualToString:self.currentSandbox];
    }
    self.cwdValueLabel.text = self.currentCwd.length ? [NSString stringWithFormat:@"当前：%@", self.currentCwd] : @"当前：—";
    self.planSwitch.on = self.planOn;
    self.planDescLabel.text = self.planOn ? @"已开启（先审后做）" : @"已关闭";
}

#pragma mark - 数据加载（scope=31 type=3 面板数据）

//读 scope=31 type=3 面板数据（零解析）：model/effort/sandbox/plan/cwd/dirs。
//多机器人：按本面板绑定的 robotUid 精确读 "<...>_3_<uid>"（空 = 会话默认）
- (void)loadPanelDataFromUserSetting {
    if (![WFCUAgentState isAgentConversation:self.conversation]) {
        return;
    }
    NSDictionary *data = [WFCUAgentState agentPanelData:self.conversation robotUid:self.robotUid];
    if (![data isKindOfClass:[NSDictionary class]]) {
        return;
    }

    //模型：current + options[{value,label}]
    NSDictionary *model = data[@"model"];
    if ([model isKindOfClass:[NSDictionary class]]) {
        if ([model[@"current"] isKindOfClass:[NSString class]] && [model[@"current"] length]) {
            self.currentModel = model[@"current"];
        }
        NSArray *opts = model[@"options"];
        if ([opts isKindOfClass:[NSArray class]] && opts.count) {
            NSMutableArray<NSDictionary<NSString *, NSString *> *> *arr = [NSMutableArray array];
            for (id o in opts) {
                if (![o isKindOfClass:[NSDictionary class]]) {
                    continue;
                }
                NSString *value = [o[@"value"] isKindOfClass:[NSString class]] ? o[@"value"] : nil;
                NSString *label = [o[@"label"] isKindOfClass:[NSString class]] && [o[@"label"] length] ? o[@"label"] : value;
                if (value.length) {
                    [arr addObject:@{@"value": value, @"label": label.length ? label : value}];
                }
            }
            if (arr.count) {
                self.modelOptions = [arr copy];
            }
        }
    }

    //推理等级：current + options[字符串数组]
    NSDictionary *effort = data[@"effort"];
    if ([effort isKindOfClass:[NSDictionary class]]) {
        if ([effort[@"current"] isKindOfClass:[NSString class]] && [effort[@"current"] length]) {
            self.currentEffort = effort[@"current"];
        }
        NSArray *opts = effort[@"options"];
        if ([opts isKindOfClass:[NSArray class]] && opts.count) {
            NSMutableArray<NSDictionary<NSString *, NSString *> *> *arr = [NSMutableArray array];
            for (id v in opts) {
                if (![v isKindOfClass:[NSString class]] || ![v length]) {
                    continue;
                }
                [arr addObject:@{@"value": v, @"label": v}];
            }
            if (arr.count) {
                self.effortOptions = [arr copy];
            }
        }
    }

    //沙箱：current + options[字符串数组]（缺省用内置兜底）
    NSDictionary *sandbox = data[@"sandbox"];
    if ([sandbox isKindOfClass:[NSDictionary class]]) {
        if ([sandbox[@"current"] isKindOfClass:[NSString class]] && [sandbox[@"current"] length]) {
            self.currentSandbox = sandbox[@"current"];
        }
        NSArray *opts = sandbox[@"options"];
        if ([opts isKindOfClass:[NSArray class]] && opts.count) {
            NSMutableArray<NSDictionary<NSString *, NSString *> *> *arr = [NSMutableArray array];
            for (id v in opts) {
                if (![v isKindOfClass:[NSString class]] || ![v length]) {
                    continue;
                }
                [arr addObject:@{@"value": v, @"label": v}];
            }
            if (arr.count) {
                self.sandboxOptions = [arr copy];
            }
        }
    }

    //计划模式
    NSDictionary *plan = data[@"plan"];
    if ([plan isKindOfClass:[NSDictionary class]]) {
        self.planOn = [plan[@"on"] boolValue];
    }

    //工作目录 + 根目录子目录列表
    if ([data[@"cwd"] isKindOfClass:[NSString class]] && [data[@"cwd"] length]) {
        self.currentCwd = data[@"cwd"];
    }
    NSArray *dirs = data[@"dirs"];
    if ([dirs isKindOfClass:[NSArray class]] && dirs.count) {
        NSMutableArray<NSString *> *arr = [NSMutableArray array];
        for (id d in dirs) {
            if ([d isKindOfClass:[NSString class]] && [d length]) {
                [arr addObject:d];
            }
        }
        if (arr.count) {
            self.cwdCandidates = [arr copy];
        }
    }

    [self refreshModelDropdown];
    [self refreshEffortDropdown];
    [self rebuildSandboxOptions];
    [self refreshCurrentValues];
    [self layoutAll];
}

//scope=31 设置变化（插件执行 207 query/set 后写 type=3 / type=1）：重读面板数据刷新 UI
- (void)onSettingUpdated:(NSNotification *)notification {
    if (!self.isViewLoaded || !self.view.window) {
        return;
    }
    [self loadPanelDataFromUserSetting];
}

#pragma mark - 207 Agent_Command 静默指令

//发送 207 面板指令（透明消息：不存储、不显示、不计未读，全部交互不落消息流）。
//多机器人：带目标机器人 robotId（存在时仅该机器人执行，插件已支持）；空 = 会话默认机器人
- (void)sendAgentCommand:(NSString *)op cmd:(nullable NSString *)cmd {
    if (![WFCUAgentState isAgentConversation:self.conversation]) {
        return;
    }
    WFCCAgentCommandMessageContent *content = [[WFCCAgentCommandMessageContent alloc] init];
    content.op = op;
    content.cmd = cmd;
    //seq 防重/追踪（与 PC 端一致：毫秒时间戳取模）
    content.seq = (NSInteger)([[NSDate date] timeIntervalSince1970] * 1000) % 100000;
    content.robotId = self.robotUid.length ? self.robotUid : nil;
    [[WFCCIMService sharedWFCIMService] send:self.conversation content:content success:nil error:nil];
}

#pragma mark - 操作（207 set，cmd=命令文本）

- (void)onSelectModelValue:(NSString *)value {
    if (self.applying || !value.length) {
        return;
    }
    self.currentModel = value;
    [self refreshCurrentValues];
    [self sendAgentCommand:@"set" cmd:[NSString stringWithFormat:@"/model %@", value]];
    [self flashApplying];
}

- (void)onSelectEffortValue:(NSString *)value {
    if (self.applying || !value.length) {
        return;
    }
    self.currentEffort = value;
    [self refreshCurrentValues];
    [self sendAgentCommand:@"set" cmd:[NSString stringWithFormat:@"/effort %@", value]];
    [self flashApplying];
}

- (void)onSelectSandboxRadio:(WFCUAgentRadioButton *)sender {
    if (self.applying || !sender.optionValue.length) {
        return;
    }
    self.currentSandbox = sender.optionValue;
    [self refreshCurrentValues];
    [self sendAgentCommand:@"set" cmd:[NSString stringWithFormat:@"/sandbox %@", sender.optionValue]];
    [self flashApplying];
}

- (void)onTogglePlan {
    if (self.applying) {
        self.planSwitch.on = !self.planSwitch.on;
        return;
    }
    self.planOn = self.planSwitch.on;
    [self refreshCurrentValues];
    [self sendAgentCommand:@"set" cmd:self.planOn ? @"/plan on" : @"/plan off"];
    [self flashApplying];
}

//点「切换」：弹出独立目录选择界面（候选来自 type=3 dirs，组合查询已含；为空可重发 query 刷新）
- (void)onOpenCwdPicker {
    if (self.applying) {
        return;
    }
    if (!self.cwdCandidates.count) {
        [self sendAgentCommand:@"query" cmd:nil];
    }
    WFCUAgentCwdPickerViewController *picker = [[WFCUAgentCwdPickerViewController alloc] init];
    __weak typeof(self) ws = self;
    picker.dataProvider = ^NSDictionary *{
        __strong typeof(ws) ss = ws;
        return @{@"dirs": ss ? (ss.cwdCandidates ?: @[]) : @[], @"current": ss ? (ss.currentCwd ?: @"") : @""};
    };
    picker.onSelect = ^(NSString *dir) {
        __strong typeof(ws) ss = ws;
        if (!ss || !dir.length) {
            return;
        }
        //当前值先乐观更新，type=3 刷新兜底
        ss.currentCwd = dir;
        [ss refreshCurrentValues];
        [ss sendAgentCommand:@"set" cmd:[NSString stringWithFormat:@"/cwd %@", dir]];
        [ss flashApplying];
    };
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)onCompact {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"压缩上下文"
                                                                  message:@"压缩会话上下文（折叠历史，减少 token 占用），继续？"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"压缩" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self sendAgentCommand:@"set" cmd:@"/compact"];
        [self flashApplying];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onReset {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重置会话"
                                                                  message:@"重置会话将清空全部上下文（工作目录保留），继续？"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"重置" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self sendAgentCommand:@"set" cmd:@"/reset"];
        [self flashApplying];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

//销毁会话：解散本群 + 销毁会话 + 删除工作区目录 + 清注册（插件 /destroy，207 set 同款发送）。
//毁灭性操作：按钮不随操作冷却禁用（始终可点），点击弹单次强警告确认，确认后才发送；
//发送后与其他操作一样 flashApplying 防连点。
- (void)onDestroy {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"销毁会话"
                                                                  message:@"销毁会话将解散本群、删除工作区目录及全部会话数据，不可恢复！\n\n请确认是否销毁？"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确认销毁" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self sendAgentCommand:@"set" cmd:@"/destroy"];
        [self flashApplying];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

//发送后短暂禁用按钮，防连点
- (void)flashApplying {
    self.applying = YES;
    [self setControlsEnabled:NO];
    [self.applyingTimer invalidate];
    self.applyingTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(onApplyingDone) userInfo:nil repeats:NO];
}

- (void)onApplyingDone {
    self.applying = NO;
    [self setControlsEnabled:YES];
}

- (void)setControlsEnabled:(BOOL)enabled {
    self.modelDropdown.enabled = enabled;
    self.effortDropdown.enabled = enabled;
    for (WFCUAgentRadioButton *radio in self.sandboxRadios) {
        radio.enabled = enabled;
    }
    self.cwdSwitchBtn.enabled = enabled;
    self.planSwitch.enabled = enabled;
    self.compactBtn.enabled = enabled;
    self.resetBtn.enabled = enabled;
    //销毁按钮不随操作冷却禁用（始终可点）
}

- (void)onBackgroundTapped {
    [self closePanel];
}

- (void)closePanel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
