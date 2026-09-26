//
//  WFCUAgentPanelViewController.m
//  WFChatUIKit
//
//  Agent/AI 会话设置面板实现（静默通道）。
//  打开：发 Agent_Command(207) query（组合查询）→ 插件聚合面板数据写 scope=31 type=3
//  → 本端读 type=3 渲染（model/effort/preset/approval 下拉选项+当前值、sandbox 水平单选、
//  plan switch、cwd 当前值+「切换」弹窗选目录）。
//  操作：发 207 set（cmd=命令文本，如 "/model deepseek-official/xxx"），插件执行后写
//  type=1 lastChange（标题状态行可见）+ 刷新 type=3；本端监听 kSettingUpdated 重读 type=3。
//  目录列表：type=3 已移除内联 dirs（单条设置值 4096 上限，超限会整条 JSON 失效），
//  改为按需获取——点「切换」发 207 op=dirs（带 seq/robotId），插件用 209
//  Agent_Command_Result 透明消息回传 {seq 回显, robotId, cwd, root, dirs[], total,
//  truncated}；本端按 seq 关联 pending（同一面板可有多个），校验 robotId，
//  seq 不匹配/已超时/机器人不匹配的应答直接丢弃。TTL 60s 缓存；超时 5s 重试 1 次，
//  仍失败显示「获取目录失败，请重试」并保留手动输入兜底；老插件（不识别 op=dirs，
//  type=3 仍内联 dirs）超时后回退读 type=3 的 dirs。
//  207/209 均为透明消息（不存储、不显示、不计未读），全部交互不落消息流；不解析机器人回复文本。
//
//  交互对齐统一风格：
//  - 模型/推理等级：下拉选择（iOS 14+ UIMenu；iOS 12/13 用 UIPickerView 弹层兜底；
//    候选列表 + 当前值，当前值不在候选时补入并标注"（当前）"；选中发 207 set /model|/effort）
//  - 工作目录：显示当前值 + 「切换」按钮，点切换弹出独立目录选择界面（候选来自
//    209 op=dirs 应答，老插件回退 type=3 dirs），选中发 207 set /cwd
//  - Agent 模式 / 工具审批：下拉选择（与模型/推理等级同款控件；选项为 {value,label}
//    对象数组，字段与 model.options 同构）；Agent 模式选项为空（部署未提供 preset 服务）
//    或两字段整体缺失（旧版插件）时控件禁用、仅显示当前值文本，不隐藏整行；
//    选中分别发 207 set /preset <value> 与 /approval <value>
//  - 沙箱模式：三个水平单选按钮（只读/仅写工作区/完全放开），选中发 207 set /sandbox
//  - 计划模式：UISwitch 开关，发 /plan on|off
//  - 底部：压缩上下文 / 重置会话 / 销毁会话（红色实底，强警告确认后发 /destroy）
//
//  触摸注意（勿回退）：遮罩关闭面板的 UITapGestureRecognizer 挂在 self.view 上，
//  而手势识别器会收到"自身视图及其所有子视图"的触摸并在识别时取消它们——必须用
//  gestureRecognizer:shouldReceiveTouch: 把卡片内的触摸挡在手势之外（并设
//  cancelsTouchesInView=NO），否则卡片里的单选/开关/按钮/下拉都收不到 touchUpInside
//  （iOS 上表现为"点沙箱单选没选中、面板直接关闭"）。三个 VC（面板 + 目录选择 + 下拉兜底）同规则。
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
@interface WFCUAgentPickerViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UIGestureRecognizerDelegate>
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

//独立目录选择界面（底部卡片）：候选来自 209 op=dirs 应答（按需获取，TTL 60s 缓存），
//老插件回退 type=3 内联 dirs；dirs 为空时按 status 文案显示加载/失败态（失败态带「重试」）。
//底部固定「手动输入」行：直接输入目录名/相对路径作为兜底（等同 /cwd <路径>）。
@interface WFCUAgentCwdPickerViewController : UIViewController <UIGestureRecognizerDelegate, UITextFieldDelegate>
//@{@"dirs": NSArray, @"current": NSString, @"status": NSString(可选，dirs 为空时的提示文案),
//  @"retryable": NSNumber(可选，失败态=true：显示「重试」按钮),
//  @"hint": NSString(可选，底部说明，如截断提示)}
@property (nonatomic, copy)NSDictionary *(^dataProvider)(void);
@property (nonatomic, copy)void (^onSelect)(NSString *dir);
//失败态「重试」回调（nil = 不显示重试按钮，如加载中）
@property (nonatomic, copy)void (^onRetry)(void);
//重读 dataProvider 重建候选（209 应答到达 / type=3 刷新 / 重试后调用）
- (void)reload;
@end

#pragma mark - 面板

@interface WFCUAgentPanelViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong)WFCCConversation *conversation;
//目标机器人 uid（多机器人会话寻址：完整 robot_xxx_yyy，勿截断；空=会话默认机器人）
@property (nonatomic, copy)NSString *robotUid;

//数据（全部来自 scope=31 type=3 面板数据；207 set 后由 kSettingUpdated 重读刷新）
@property (nonatomic, assign)BOOL applying;
@property (nonatomic, strong)NSString *currentModel;
@property (nonatomic, strong)NSString *currentEffort;
@property (nonatomic, strong)NSString *currentCwd;
@property (nonatomic, strong)NSString *currentSandbox;
@property (nonatomic, strong)NSString *currentPreset;    //Agent 模式当前值（type=3 preset.current）
@property (nonatomic, strong)NSString *currentApproval;  //工具审批策略当前值（type=3 approval.current）
@property (nonatomic, assign)BOOL planOn;
@property (nonatomic, strong)NSArray<NSDictionary<NSString *, NSString *> *> *modelOptions;   //@{@"value": @"provider/id", @"label": ...}
@property (nonatomic, strong)NSArray<NSDictionary<NSString *, NSString *> *> *effortOptions;  //@{@"value": id, @"label": id}
@property (nonatomic, strong)NSArray<NSDictionary<NSString *, NSString *> *> *sandboxOptions; //@{@"value": mode, @"label": ...}
@property (nonatomic, strong)NSArray<NSDictionary<NSString *, NSString *> *> *presetOptions;  //@{@"value": preset, @"label": ...}（空 = 未提供 preset 服务/旧版插件）
@property (nonatomic, strong)NSArray<NSDictionary<NSString *, NSString *> *> *approvalOptions; //@{@"value": policy, @"label": ...}（空 = 字段缺失/旧版插件）
@property (nonatomic, strong)NSArray<NSString *> *cwdCandidates;
//目录列表按需获取（207 op=dirs → 209 Agent_Command_Result 应答）：
//pending 表 key = seq，value = @{@"robotId": 目标机器人(空=会话默认), @"sentAt": NSDate, @"retried": @(BOOL)}
@property (nonatomic, strong)NSMutableDictionary<NSNumber *, NSDictionary *> *pendingDirsRequests;
@property (nonatomic, strong)NSTimer *dirsTimeoutTimer;
@property (nonatomic, assign)NSInteger dirsSeqSeed;
//目录列表缓存（同一面板会话内 TTL 60s；空数组也算有效缓存——机器人根目录真的没有子目录）
@property (nonatomic, strong)NSArray<NSString *> *dirsCache;
@property (nonatomic, strong)NSDate *dirsCacheTime;
//目录选择界面状态：加载/失败文案（dirs 为空时展示）、失败态是否显示「重试」、截断提示
@property (nonatomic, copy)NSString *dirsStatusText;
@property (nonatomic, assign)BOOL dirsRequestFailed;
@property (nonatomic, copy)NSString *dirsHintText;
@property (nonatomic, weak)WFCUAgentCwdPickerViewController *cwdPicker;
//上次渲染用的 type=3 面板数据（type=1/type=2 推送也会触发 kSettingUpdated，
//数据未变化时直接跳过重排，避免把用户正在按下的控件重建掉）
@property (nonatomic, strong)NSDictionary *lastPanelData;

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
@property (nonatomic, strong)UILabel *presetTitleLabel;
@property (nonatomic, strong)WFCUAgentDropdownButton *presetDropdown;
@property (nonatomic, strong)UILabel *approvalTitleLabel;
@property (nonatomic, strong)WFCUAgentDropdownButton *approvalDropdown;
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

    //点背景关闭（仅遮罩空白区域；卡片内的滚轮/按钮必须能收到触摸）
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePanel)];
    tap.delegate = self;
    tap.cancelsTouchesInView = NO;
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

#pragma mark - UIGestureRecognizerDelegate

//遮罩手势只接收卡片外的触摸，卡片内（滚轮/取消/完成）的点击交给控件自己
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *touchView = touch.view;
    if (!touchView) {
        return YES;
    }
    return ![touchView isDescendantOfView:_cardView];
}

@end

#pragma mark - 单选按钮实现

//沙箱单选控件：整块（宽度约 1/3 卡片宽 × 46pt 高）都是点击热区，
//并画出圆角底色+描边，让"可点区域"在视觉上可辨（iOS 上 HIG 建议热区 ≥44pt）
@implementation WFCUAgentRadioButton {
    UIView *_ringView;
    UIView *_dotView;
    UILabel *_titleLabel;
}

//固定几何：圈 20pt，文字 13pt
static const CGFloat kAgentRadioRingSize = 20;
static const CGFloat kAgentRadioHeight = 46;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _ringView = [[UIView alloc] initWithFrame:CGRectZero];
        _ringView.layer.cornerRadius = kAgentRadioRingSize / 2.0;
        _ringView.layer.borderWidth = 1.5;
        _ringView.userInteractionEnabled = NO;
        [self addSubview:_ringView];

        _dotView = [[UIView alloc] initWithFrame:CGRectZero];
        _dotView.layer.cornerRadius = 4.5;
        _dotView.userInteractionEnabled = NO;
        [self addSubview:_dotView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:13]];
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

//操作冷却期（applying）整块变淡，给"暂时不可点"的反馈
- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.alpha = enabled ? 1.0 : 0.5;
}

- (void)applyStyle {
    UIColor *accent = [WFCUAgentState accentColor];
    UIColor *idleBorder = [UIColor colorWithHexString:@"0xe5e6eb"];
    _ringView.layer.borderColor = (self.radioSelected ? accent : [UIColor colorWithHexString:@"0xc8c8c8"]).CGColor;
    _dotView.backgroundColor = self.radioSelected ? accent : [UIColor clearColor];
    _titleLabel.textColor = self.radioSelected ? accent : [UIColor colorWithHexString:@"0x666666"];
    _titleLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:13] weight:(self.radioSelected ? UIFontWeightMedium : UIFontWeightRegular)];

    //整块热区的可视边界（选中：淡强调底色 + 强调描边；未选中：浅灰底 + 浅灰描边）
    self.layer.cornerRadius = 8;
    self.layer.borderWidth = 1;
    self.layer.borderColor = (self.radioSelected ? accent : idleBorder).CGColor;
    self.backgroundColor = self.radioSelected ? [accent colorWithAlphaComponent:0.08] : [UIColor colorWithHexString:@"0xf7f8fa"];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat h = self.bounds.size.height;
    _ringView.frame = CGRectMake(8, (h - kAgentRadioRingSize) / 2.0, kAgentRadioRingSize, kAgentRadioRingSize);
    _dotView.frame = CGRectMake(CGRectGetMidX(_ringView.frame) - 4.5, CGRectGetMidY(_ringView.frame) - 4.5, 9, 9);
    CGFloat titleX = CGRectGetMaxX(_ringView.frame) + 5;
    _titleLabel.frame = CGRectMake(titleX, 0, MAX(self.bounds.size.width - titleX - 6, 0), h);
}

@end

#pragma mark - 工作目录选择弹窗实现

@implementation WFCUAgentCwdPickerViewController {
    UIView *_cardView;
    UIView *_manualRow;
    UITextField *_manualField;
    UIButton *_manualButton;
    UIScrollView *_scrollView;
    UIView *_contentView;
    NSMutableArray<WFCUAgentOptionButton *> *_rowButtons;
    CGFloat _keyboardOffset; //键盘弹起时卡片上移量（保证「手动输入」行不被遮挡）
}

//卡片高度（标题 48 + 手动输入 52 + 候选列表）
static const CGFloat kAgentCwdHeaderH = 48;
static const CGFloat kAgentCwdManualH = 52;

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

    //点背景关闭（仅遮罩空白区域；目录行按钮必须能收到触摸，否则"点了直接关闭、没选中"）
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePanel)];
    tap.delegate = self;
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];

    //面板数据刷新（207 query/set 后写 type=3）时重读目录候选
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSettingUpdated:) name:kSettingUpdated object:nil];
    //手动输入兜底：键盘弹起时卡片上移，避免「手动输入」行被键盘遮挡（小屏）
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillChange:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillChange:) name:UIKeyboardWillHideNotification object:nil];

    CGFloat cardH = MIN(self.view.bounds.size.height * 0.65, 520);
    _cardView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - cardH, self.view.bounds.size.width, cardH)];
    _cardView.backgroundColor = [UIColor whiteColor];
    _cardView.layer.cornerRadius = 16;
    if (@available(iOS 11.0, *)) {
        _cardView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    }
    _cardView.clipsToBounds = YES;
    [self.view addSubview:_cardView];

    //标题行
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _cardView.bounds.size.width, kAgentCwdHeaderH)];
    header.backgroundColor = [UIColor whiteColor];
    [_cardView addSubview:header];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, header.bounds.size.width - 80, kAgentCwdHeaderH)];
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

    UIView *headerLine = [[UIView alloc] initWithFrame:CGRectMake(0, kAgentCwdHeaderH - 0.5, header.bounds.size.width, 0.5)];
    headerLine.backgroundColor = [UIColor colorWithHexString:@"0xededed"];
    [header addSubview:headerLine];

    //手动输入兜底行（固定不随候选重建，输入目录名/相对路径，等同 /cwd <路径>）
    _manualRow = [[UIView alloc] initWithFrame:CGRectMake(0, kAgentCwdHeaderH, _cardView.bounds.size.width, kAgentCwdManualH)];
    _manualRow.backgroundColor = [UIColor whiteColor];
    [_cardView addSubview:_manualRow];

    _manualField = [[UITextField alloc] initWithFrame:CGRectMake(16, 10, _manualRow.bounds.size.width - 16 - 72 - 10, 32)];
    _manualField.placeholder = @"手动输入目录名或路径";
    _manualField.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:13]];
    _manualField.textColor = [UIColor colorWithHexString:@"0x333333"];
    _manualField.backgroundColor = [UIColor colorWithHexString:@"0xf2f3f5"];
    _manualField.layer.cornerRadius = 6;
    _manualField.clipsToBounds = YES;
    _manualField.autocorrectionType = UITextAutocorrectionTypeNo;
    _manualField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _manualField.returnKeyType = UIReturnKeyDone;
    _manualField.delegate = self;
    _manualField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 32)];
    _manualField.leftViewMode = UITextFieldViewModeAlways;
    [_manualRow addSubview:_manualField];

    UIButton *manualBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _manualButton = manualBtn;
    manualBtn.frame = CGRectMake(_manualRow.bounds.size.width - 16 - 72, 10, 72, 32);
    [manualBtn setTitle:@"确定" forState:UIControlStateNormal];
    [manualBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    manualBtn.titleLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:13]];
    manualBtn.backgroundColor = [WFCUAgentState accentColor];
    manualBtn.layer.cornerRadius = 6;
    [manualBtn addTarget:self action:@selector(onManualInput) forControlEvents:UIControlEventTouchUpInside];
    [_manualRow addSubview:manualBtn];

    UIView *manualLine = [[UIView alloc] initWithFrame:CGRectMake(0, kAgentCwdManualH - 0.5, _manualRow.bounds.size.width, 0.5)];
    manualLine.backgroundColor = [UIColor colorWithHexString:@"0xededed"];
    [_manualRow addSubview:manualLine];

    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, kAgentCwdHeaderH + kAgentCwdManualH, _cardView.bounds.size.width, cardH - kAgentCwdHeaderH - kAgentCwdManualH)];
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.showsVerticalScrollIndicator = YES;
    _scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
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
    [self layoutCard];
    if (_contentView && _contentView.bounds.size.width != _scrollView.bounds.size.width) {
        _contentView.frame = CGRectMake(0, 0, _scrollView.bounds.size.width, _contentView.bounds.size.height);
        [self rebuildRows];
    }
}

//卡片贴底 + 键盘弹起时整体上移（手动输入行始终可见）
- (void)layoutCard {
    CGFloat cardH = MIN(self.view.bounds.size.height * 0.65, 520);
    CGFloat cardTop = self.view.bounds.size.height - cardH - _keyboardOffset;
    _cardView.frame = CGRectMake(0, cardTop, self.view.bounds.size.width, cardH);
    _manualRow.frame = CGRectMake(0, kAgentCwdHeaderH, _cardView.bounds.size.width, kAgentCwdManualH);
    _manualField.frame = CGRectMake(16, 10, _manualRow.bounds.size.width - 16 - 72 - 10, 32);
    _manualButton.frame = CGRectMake(_manualRow.bounds.size.width - 16 - 72, 10, 72, 32);
    _scrollView.frame = CGRectMake(0, kAgentCwdHeaderH + kAgentCwdManualH, _cardView.bounds.size.width, cardH - kAgentCwdHeaderH - kAgentCwdManualH);
}

//键盘显隐：按键盘顶边与「手动输入」行底边的重叠量上移卡片
- (void)onKeyboardWillChange:(NSNotification *)notification {
    CGFloat offset = 0;
    if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
        CGRect kbRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat kbTop = [self.view convertRect:kbRect fromView:nil].origin.y;
        CGFloat cardH = MIN(self.view.bounds.size.height * 0.65, 520);
        CGFloat manualBottom = self.view.bounds.size.height - cardH + kAgentCwdHeaderH + kAgentCwdManualH;
        if (manualBottom > kbTop) {
            offset = manualBottom - kbTop + 8;
        }
    }
    if (fabs(offset - _keyboardOffset) < 0.5) {
        return;
    }
    _keyboardOffset = offset;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration > 0 ? duration : 0.25 animations:^{
        [self layoutCard];
    }];
}

//type=3 刷新（207 query/set 后）重读目录候选
- (void)onSettingUpdated:(NSNotification *)notification {
    [self rebuildRows];
}

//209 应答到达 / 重试 / 面板状态变化后重读 dataProvider
- (void)reload {
    if (self.isViewLoaded) {
        [self rebuildRows];
    }
}

//手动输入兜底：直接把输入串作为 /cwd 参数（目录名或路径），不再等待 209 应答
- (void)onManualInput {
    NSString *text = [_manualField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!text.length) {
        return;
    }
    [_manualField resignFirstResponder];
    if (self.onSelect) {
        self.onSelect(text);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self onManualInput];
    return YES;
}

#pragma mark - 候选重建

//重建目录候选行（数据来自面板 dataProvider：dirs + current + status + hint）。
//dirs 为空时按 status 显示加载/失败态；失败态（onRetry 非空）显示「重试」按钮。
- (void)rebuildRows {
    for (UIView *sub in _contentView.subviews) {
        [sub removeFromSuperview];
    }
    [_rowButtons removeAllObjects];

    NSDictionary *data = self.dataProvider ? self.dataProvider() : nil;
    NSArray *dirs = [data[@"dirs"] isKindOfClass:[NSArray class]] ? data[@"dirs"] : @[];
    NSString *current = [data[@"current"] isKindOfClass:[NSString class]] ? data[@"current"] : @"";
    NSString *status = [data[@"status"] isKindOfClass:[NSString class]] ? data[@"status"] : nil;
    NSString *hint = [data[@"hint"] isKindOfClass:[NSString class]] ? data[@"hint"] : nil;
    //失败态才显示「重试」（加载中不显示，避免误点）
    BOOL retryable = [data[@"retryable"] boolValue] && self.onRetry != nil;

    CGFloat w = MAX(_contentView.bounds.size.width, 200);
    CGFloat y = 12;
    if (!dirs.count) {
        //加载/失败态：状态文案 +（失败时）重试按钮
        NSString *text = status.length ? status : @"未获取到目录列表，可手动输入路径";
        UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, y, w - 32, 44)];
        statusLabel.text = text;
        statusLabel.numberOfLines = 2;
        statusLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:12]];
        statusLabel.textColor = [UIColor colorWithHexString:@"0x999999"];
        [_contentView addSubview:statusLabel];
        y += 46;

        if (retryable) {
            UIButton *retryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            retryBtn.frame = CGRectMake(16, y, w - 32, 40);
            [retryBtn setTitle:@"重试" forState:UIControlStateNormal];
            [retryBtn setTitleColor:[WFCUAgentState accentColor] forState:UIControlStateNormal];
            retryBtn.titleLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:13] weight:UIFontWeightMedium];
            retryBtn.backgroundColor = [UIColor whiteColor];
            retryBtn.layer.borderColor = [WFCUAgentState accentColor].CGColor;
            retryBtn.layer.borderWidth = 1;
            retryBtn.layer.cornerRadius = 6;
            [retryBtn addTarget:self action:@selector(onRetryTapped) forControlEvents:UIControlEventTouchUpInside];
            [_contentView addSubview:retryBtn];
            y += 40 + 6;
        }
        y += 6;
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

    //底部说明（如截断提示：插件侧目录上限 3000 条）
    if (hint.length) {
        UILabel *hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, y, w - 32, 32)];
        hintLabel.text = hint;
        hintLabel.numberOfLines = 2;
        hintLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:11]];
        hintLabel.textColor = [UIColor colorWithHexString:@"0x999999"];
        [_contentView addSubview:hintLabel];
        y += 34;
    }
    _contentView.frame = CGRectMake(0, 0, w, y);
    _scrollView.contentSize = CGSizeMake(w, y);
}

- (void)onRetryTapped {
    if (self.onRetry) {
        self.onRetry();
    }
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

#pragma mark - UIGestureRecognizerDelegate

//遮罩手势只接收卡片外的触摸，卡片内的目录行按钮点击交给按钮自己
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *touchView = touch.view;
    if (!touchView) {
        return YES;
    }
    return ![touchView isDescendantOfView:_cardView];
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
        //Agent 模式/工具审批：默认空（= 未提供/旧版插件，控件禁用），由 type=3 面板数据填充
        self.presetOptions = @[];
        self.approvalOptions = @[];
        self.cwdCandidates = @[];
        self.sandboxRadios = [NSMutableArray array];
        //目录列表 pending 表 + seq 种子（毫秒取模，与 207 其他指令风格一致；同一面板内自增避免 seq 冲突）
        self.pendingDirsRequests = [NSMutableDictionary dictionary];
        self.dirsSeqSeed = (NSInteger)([[NSDate date] timeIntervalSince1970] * 1000) % 100000;
        //底部弹窗：透明背景 + 底部卡片，present 时原会话页可见
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];

    //点背景关闭：只认遮罩空白区域的点击（卡片内控件必须收到自己的触摸，见 shouldReceiveTouch）
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundTapped)];
    tap.delegate = self;
    tap.cancelsTouchesInView = NO; //遮罩手势不得取消卡片内控件（单选/开关/按钮/下拉）的触摸
    [self.view addGestureRecognizer:tap];

    //scope=31 设置变化（插件执行 207 query/set 后写 type=3 / type=1，kSettingUpdated 不带 scope/key，重读当前会话 key）
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSettingUpdated:) name:kSettingUpdated object:nil];

    //209 Agent_Command_Result（透明消息）：207 op=dirs 的应答通道，按 seq 关联 pending
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];

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
    [self.dirsTimeoutTimer invalidate];
}

//面板关闭：停止超时轮询并清空 pending（NSTimer 会持有 self，不清会导致面板无法释放）
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isBeingDismissed || self.navigationController.isBeingDismissed || !self.view.window) {
        [self.pendingDirsRequests removeAllObjects];
        [self stopDirsTimeoutTimer];
        [self.applyingTimer invalidate];
        self.applyingTimer = nil;
    }
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
    NSString *titleText = @"🤖 AI 设置";
    if (self.robotUid.length) {
        titleText = [NSString stringWithFormat:@"🤖 AI 设置 · %@", [WFCUAgentState agentRobotName:self.robotUid]];
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

    //5. Agent 模式（preset，下拉选择；选项来自 type=3 preset.options{value,label}）
    self.presetTitleLabel = [self makeSectionTitle:@"Agent 模式"];
    [self.contentView addSubview:self.presetTitleLabel];

    self.presetDropdown = [[WFCUAgentDropdownButton alloc] initWithFrame:CGRectZero];
    self.presetDropdown.dropPresenter = self;
    self.presetDropdown.placeholder = @"—";
    self.presetDropdown.onSelect = ^(NSString *value) {
        [ws onSelectPresetValue:value];
    };
    [self.contentView addSubview:self.presetDropdown];

    //6. 工具审批（approval，下拉选择；选项来自 type=3 approval.options{value,label}）
    self.approvalTitleLabel = [self makeSectionTitle:@"工具审批"];
    [self.contentView addSubview:self.approvalTitleLabel];

    self.approvalDropdown = [[WFCUAgentDropdownButton alloc] initWithFrame:CGRectZero];
    self.approvalDropdown.dropPresenter = self;
    self.approvalDropdown.placeholder = @"—";
    self.approvalDropdown.onSelect = ^(NSString *value) {
        [ws onSelectApprovalValue:value];
    };
    [self.contentView addSubview:self.approvalDropdown];

    //7. 计划模式
    self.planTitleLabel = [self makeSectionTitle:@"计划模式"];
    [self.contentView addSubview:self.planTitleLabel];

    self.planSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    [self.planSwitch addTarget:self action:@selector(onTogglePlan) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.planSwitch];

    self.planDescLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.planDescLabel.font = [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:12]];
    self.planDescLabel.textColor = [UIColor colorWithHexString:@"0x666666"];
    [self.contentView addSubview:self.planDescLabel];

    //模型/推理等级/沙箱/Agent 模式/工具审批选项（当前数据为空，仅占位）
    [self refreshModelDropdown];
    [self refreshEffortDropdown];
    [self rebuildSandboxOptions];
    [self refreshPresetDropdown];
    [self refreshApprovalDropdown];
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

//刷新 Agent 模式下拉：选项取自 type=3 preset.options（{value,label} 对象数组，与 model 同构）。
//options 为空（部署未提供 preset 服务）或字段缺失（旧版插件）→ 禁用控件，仅显示 current 文本；
//current 不在 options 时由 updateContent 补入并标注"（当前）"，保证展示真实当前值
- (void)refreshPresetDropdown {
    self.presetDropdown.options = self.presetOptions ?: @[];
    self.presetDropdown.selectedValue = self.currentPreset ?: @"";
    [self.presetDropdown updateContent];
    self.presetDropdown.enabled = self.presetOptions.count > 0 && !self.applying;
}

//刷新工具审批下拉：选项取自 type=3 approval.options（{value,label} 对象数组）；空/缺失同样禁用
- (void)refreshApprovalDropdown {
    self.approvalDropdown.options = self.approvalOptions ?: @[];
    self.approvalDropdown.selectedValue = self.currentApproval ?: @"";
    [self.approvalDropdown updateContent];
    self.approvalDropdown.enabled = self.approvalOptions.count > 0 && !self.applying;
}

//重建沙箱模式水平单选按钮（三个，横向均分）。
//选项未变化时直接返回：kSettingUpdated 对 type=1/type=2 推送也会触发（高频），
//若每次都 removeFromSuperview 重建，用户正在按下的按钮会被从视图树上摘掉 → 点击丢失。
- (void)rebuildSandboxOptions {
    NSArray *opts = self.sandboxOptions.count ? self.sandboxOptions : defaultSandboxOptions();
    NSMutableArray<NSString *> *values = [NSMutableArray array];
    for (NSDictionary *o in opts) {
        NSString *value = [o[@"value"] isKindOfClass:[NSString class]] ? o[@"value"] : nil;
        if (value.length) {
            [values addObject:value];
        }
    }
    if (values.count == self.sandboxRadios.count) {
        BOOL same = YES;
        for (NSInteger i = 0; i < (NSInteger)values.count; i++) {
            if (![self.sandboxRadios[i].optionValue isEqualToString:values[i]]) {
                same = NO;
                break;
            }
        }
        if (same) {
            return; //选项一致，保留现有控件（选中态由 refreshCurrentValues 刷新）
        }
    }

    for (UIView *sub in self.sandboxContainer.subviews) {
        [sub removeFromSuperview];
    }
    [self.sandboxRadios removeAllObjects];

    for (NSString *value in values) {
        WFCUAgentRadioButton *radio = [[WFCUAgentRadioButton alloc] initWithFrame:CGRectZero];
        radio.optionValue = value;
        radio.titleText = agentSandboxShortLabel(value);
        [radio addTarget:self action:@selector(onSelectSandboxRadio:) forControlEvents:UIControlEventTouchUpInside];
        [self.sandboxContainer addSubview:radio];
        [self.sandboxRadios addObject:radio];
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

    self.sandboxContainer.frame = CGRectMake(x, y, contentW - 32, kAgentRadioHeight);
    CGFloat radioGap = 8;
    CGFloat radioW = (contentW - 32 - radioGap * 2) / 3.0;
    NSInteger idx = 0;
    for (WFCUAgentRadioButton *radio in self.sandboxRadios) {
        radio.frame = CGRectMake(idx * (radioW + radioGap), 0, radioW, kAgentRadioHeight);
        idx++;
    }
    y += kAgentRadioHeight;

    //5. Agent 模式（下拉选择，与模型/推理等级同款行）
    y += sectionGap;
    self.presetTitleLabel.frame = CGRectMake(x, y, contentW - 32, 20);
    y += 20 + 6;

    self.presetDropdown.frame = CGRectMake(x, y, contentW - 32, 38);
    y += 38;

    //6. 工具审批（下拉选择，与模型/推理等级同款行）
    y += sectionGap;
    self.approvalTitleLabel.frame = CGRectMake(x, y, contentW - 32, 20);
    y += 20 + 6;

    self.approvalDropdown.frame = CGRectMake(x, y, contentW - 32, 38);
    y += 38;

    //7. 计划模式
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
    [self.presetDropdown updateContent];
    [self.approvalDropdown updateContent];
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
    //面板数据（type=3）未变化 → 不重排 UI。kSettingUpdated 对 type=1 状态 / type=2 统计
    //推送同样会触发（Agent 运行中每 ~300ms 一次），无脑重排会让点击"点了没反应"。
    if (self.lastPanelData && [self.lastPanelData isEqualToDictionary:data]) {
        return;
    }
    self.lastPanelData = [data copy];

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

    //Agent 模式（preset）：current + options[{value,label}]（与 model 同构，直接复用下拉控件）。
    //options 可能为空数组（部署未提供 preset 服务）→ 同样置空数组，控件由 refreshPresetDropdown 禁用
    NSDictionary *preset = data[@"preset"];
    if ([preset isKindOfClass:[NSDictionary class]]) {
        if ([preset[@"current"] isKindOfClass:[NSString class]] && [preset[@"current"] length]) {
            self.currentPreset = preset[@"current"];
        }
        NSArray *opts = [preset[@"options"] isKindOfClass:[NSArray class]] ? preset[@"options"] : @[];
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
        //空数组同样写入：部署未提供 preset 服务时控件禁用（仅显示 current 值），不隐藏整行
        self.presetOptions = [arr copy];
    }

    //工具审批（approval）：current + options[{value,label}]；字段整体缺失（旧版插件）时保持空数组 → 控件禁用
    NSDictionary *approval = data[@"approval"];
    if ([approval isKindOfClass:[NSDictionary class]]) {
        if ([approval[@"current"] isKindOfClass:[NSString class]] && [approval[@"current"] length]) {
            self.currentApproval = approval[@"current"];
        }
        NSArray *opts = [approval[@"options"] isKindOfClass:[NSArray class]] ? approval[@"options"] : @[];
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
        self.approvalOptions = [arr copy];
    }

    //计划模式
    NSDictionary *plan = data[@"plan"];
    if ([plan isKindOfClass:[NSDictionary class]]) {
        self.planOn = [plan[@"on"] boolValue];
    }

    //工作目录 + 根目录子目录列表。
    //dirs 已从 type=3 移除（改 209 按需应答）：新插件下这里通常为空，目录候选由
    //207 op=dirs → 209 获取；老插件仍内联 dirs 时直接采用（兼容），并写入 60s 缓存。
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
            [self cacheDirs:arr];
        }
    }

    [self refreshModelDropdown];
    [self refreshEffortDropdown];
    [self rebuildSandboxOptions];
    [self refreshPresetDropdown];
    [self refreshApprovalDropdown];
    [self refreshCurrentValues];
    [self layoutAll];
}

//scope=31 设置变化（插件执行 207 query/set 后写 type=3 / type=1）：重读面板数据刷新 UI
- (void)onSettingUpdated:(NSNotification *)notification {
    if (!self.isViewLoaded || !self.view.window) {
        return;
    }
    //有下层弹层（目录选择/下拉兜底/确认框）时先不重排，避免把弹层的锚点控件重建掉
    if (self.presentedViewController) {
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

//切换 Agent 模式：207 set /preset <value>（插件执行后写 type=1 lastChange 并刷新 type=3）
- (void)onSelectPresetValue:(NSString *)value {
    if (self.applying || !value.length) {
        return;
    }
    self.currentPreset = value;
    [self refreshCurrentValues];
    [self sendAgentCommand:@"set" cmd:[NSString stringWithFormat:@"/preset %@", value]];
    [self flashApplying];
}

//切换工具审批策略：207 set /approval <value>（同上）
- (void)onSelectApprovalValue:(NSString *)value {
    if (self.applying || !value.length) {
        return;
    }
    self.currentApproval = value;
    [self refreshCurrentValues];
    [self sendAgentCommand:@"set" cmd:[NSString stringWithFormat:@"/approval %@", value]];
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

//点「切换」：弹出独立目录选择界面。
//候选来源优先级：① 本面板 60s 内缓存 → ② 老插件 type=3 内联 dirs（兼容）
//→ ③ 发 207 op=dirs 按需获取（显示加载态，等 209 应答）
- (void)onOpenCwdPicker {
    if (self.applying) {
        return;
    }
    WFCUAgentCwdPickerViewController *picker = [[WFCUAgentCwdPickerViewController alloc] init];
    __weak typeof(self) ws = self;
    picker.dataProvider = ^NSDictionary *{
        __strong typeof(ws) ss = ws;
        if (!ss) {
            return @{@"dirs": @[], @"current": @""};
        }
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[@"dirs"] = ss.cwdCandidates ?: @[];
        dict[@"current"] = ss.currentCwd ?: @"";
        //候选为空时展示加载/失败文案；失败态由 retryable 驱动「重试」按钮
        if (!ss.cwdCandidates.count && ss.dirsStatusText.length) {
            dict[@"status"] = ss.dirsStatusText;
        }
        dict[@"retryable"] = @(ss.dirsRequestFailed);
        if (ss.dirsHintText.length) {
            dict[@"hint"] = ss.dirsHintText;
        }
        return dict;
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
    picker.onRetry = ^{
        __strong typeof(ws) ss = ws;
        [ss startDirsRequest];
    };
    self.cwdPicker = picker;
    [self presentViewController:picker animated:YES completion:nil];

    //① 缓存（TTL 60s）直接用
    if ([self dirsCacheValid]) {
        self.cwdCandidates = self.dirsCache;
        self.dirsStatusText = nil;
        self.dirsRequestFailed = NO;
        [picker reload];
        return;
    }
    //② 老插件（type=3 仍内联 dirs）：直接使用并写入缓存，不再请求
    if (self.cwdCandidates.count) {
        [self cacheDirs:self.cwdCandidates];
        self.dirsStatusText = nil;
        self.dirsRequestFailed = NO;
        [picker reload];
        return;
    }
    //③ 已有在途请求：只刷新加载态，避免重复发指令
    if (self.pendingDirsRequests.count) {
        self.dirsStatusText = @"正在获取目录列表…";
        [picker reload];
        return;
    }
    [self startDirsRequest];
}

#pragma mark - 目录列表按需获取（207 op=dirs → 209 Agent_Command_Result）

//缓存有效期（同一面板会话内）
static const NSTimeInterval kAgentDirsCacheTTL = 60.0;
//单次请求超时（超时重试 1 次，仍失败显示「获取目录失败，请重试」）
static const NSTimeInterval kAgentDirsRequestTimeout = 5.0;

//缓存是否有效（空数组也算有效缓存：机器人根目录真的没有子目录）
- (BOOL)dirsCacheValid {
    return self.dirsCache && self.dirsCacheTime && -[self.dirsCacheTime timeIntervalSinceNow] < kAgentDirsCacheTTL;
}

- (void)cacheDirs:(NSArray<NSString *> *)dirs {
    self.dirsCache = dirs ?: @[];
    self.dirsCacheTime = [NSDate date];
}

//下一个请求 seq（面板内自增，保证同一面板多个 pending 不冲突；应答原样回显用于关联）
- (NSInteger)nextDirsSeq {
    self.dirsSeqSeed = (self.dirsSeqSeed + 1) % 100000;
    return self.dirsSeqSeed;
}

//发起 207 op=dirs（新 seq），登记 pending，显示加载态
- (void)startDirsRequest {
    if (![WFCUAgentState isAgentConversation:self.conversation]) {
        return;
    }
    NSInteger seq = [self nextDirsSeq];
    self.pendingDirsRequests[@(seq)] = @{@"robotId": self.robotUid ?: @"",
                                         @"sentAt": [NSDate date],
                                         @"retried": @(NO)};
    self.dirsStatusText = @"正在获取目录列表…";
    self.dirsRequestFailed = NO;
    self.dirsHintText = nil;
    [self sendDirsCommandWithSeq:seq];
    [self startDirsTimeoutTimerIfNeeded];
    [self.cwdPicker reload];
}

//发送 207 op=dirs（透明消息；robotId 空 = 会话默认机器人）
- (void)sendDirsCommandWithSeq:(NSInteger)seq {
    if (![WFCUAgentState isAgentConversation:self.conversation]) {
        return;
    }
    WFCCAgentCommandMessageContent *content = [[WFCCAgentCommandMessageContent alloc] init];
    content.op = @"dirs";
    content.seq = seq;
    content.robotId = self.robotUid.length ? self.robotUid : nil;
    [[WFCCIMService sharedWFCIMService] send:self.conversation content:content success:nil error:nil];
}

- (void)startDirsTimeoutTimerIfNeeded {
    if (self.dirsTimeoutTimer || !self.pendingDirsRequests.count) {
        return;
    }
    self.dirsTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                             target:self
                                                           selector:@selector(onDirsTimeoutTick)
                                                           userInfo:nil
                                                            repeats:YES];
}

- (void)stopDirsTimeoutTimer {
    [self.dirsTimeoutTimer invalidate];
    self.dirsTimeoutTimer = nil;
}

//超时扫描：单个 pending 超时 5s → 同 seq 重试 1 次；再超时 → 失败（回退 type=3 dirs）
- (void)onDirsTimeoutTick {
    if (!self.pendingDirsRequests.count) {
        [self stopDirsTimeoutTimer];
        return;
    }
    NSDate *now = [NSDate date];
    for (NSNumber *seq in [self.pendingDirsRequests.allKeys copy]) {
        NSMutableDictionary *pending = [self.pendingDirsRequests[seq] mutableCopy];
        NSDate *sentAt = pending[@"sentAt"];
        if ([now timeIntervalSinceDate:sentAt] < kAgentDirsRequestTimeout) {
            continue;
        }
        if (![pending[@"retried"] boolValue]) {
            //重试 1 次（沿用同一 seq：迟到的首次应答仍可关联）
            pending[@"retried"] = @(YES);
            pending[@"sentAt"] = now;
            self.pendingDirsRequests[seq] = pending;
            [self sendDirsCommandWithSeq:[seq integerValue]];
        } else {
            [self.pendingDirsRequests removeObjectForKey:seq];
            [self onDirsRequestFailed];
        }
    }
    if (!self.pendingDirsRequests.count) {
        [self stopDirsTimeoutTimer];
    }
}

//请求失败（超时重试后仍无应答）：老插件回退读 type=3 内联 dirs；仍为空则提示可重试
- (void)onDirsRequestFailed {
    NSArray<NSString *> *fallback = [self legacyDirsFromPanelData];
    if (fallback.count) {
        self.cwdCandidates = fallback;
        [self cacheDirs:fallback];
        self.dirsStatusText = nil;
        self.dirsRequestFailed = NO;
        self.dirsHintText = nil;
    } else {
        self.dirsRequestFailed = YES;
        self.dirsStatusText = @"获取目录失败，请重试";
    }
    [self.cwdPicker reload];
}

//老插件兼容：type=3 面板数据内联 dirs（新插件已移除，通常为空）
- (NSArray<NSString *> *)legacyDirsFromPanelData {
    NSDictionary *data = [WFCUAgentState agentPanelData:self.conversation robotUid:self.robotUid];
    NSArray *dirs = [data isKindOfClass:[NSDictionary class]] && [data[@"dirs"] isKindOfClass:[NSArray class]] ? data[@"dirs"] : nil;
    if (!dirs.count) {
        return @[];
    }
    NSMutableArray<NSString *> *arr = [NSMutableArray array];
    for (id dir in dirs) {
        if ([dir isKindOfClass:[NSString class]] && [dir length]) {
            [arr addObject:dir];
        }
    }
    return arr;
}

#pragma mark - 209 Agent_Command_Result 应答

//209 为透明消息（不落库/不显示/不计未读），经 kReceiveMessages 到达
- (void)onReceiveMessages:(NSNotification *)notification {
    NSArray *messages = notification.object;
    if (![messages isKindOfClass:[NSArray class]]) {
        return;
    }
    for (WFCCMessage *message in messages) {
        if (![message isKindOfClass:[WFCCMessage class]]) {
            continue;
        }
        if (![message.conversation isEqual:self.conversation]) {
            continue;
        }
        if (![message.content isKindOfClass:[WFCCAgentCommandResultMessageContent class]]) {
            continue;
        }
        [self handleAgentCommandResult:(WFCCAgentCommandResultMessageContent *)message.content];
    }
}

//处理 209 应答：op/seq/robotId 三重校验，全部通过才消费
- (void)handleAgentCommandResult:(WFCCAgentCommandResultMessageContent *)result {
    //仅处理 op=dirs（其他 op 的应答交回对应功能，本面板忽略）
    if (![result.op isEqualToString:@"dirs"]) {
        return;
    }
    NSNumber *key = @(result.seq);
    NSDictionary *pending = self.pendingDirsRequests[key];
    if (!pending) {
        //seq 不匹配（非本面板请求）或已超时移除 → 丢弃
        return;
    }
    //robotId 校验：指定了目标机器人时必须精确匹配（空 = 会话默认机器人，由插件决定应答方）
    NSString *expected = pending[@"robotId"];
    NSString *actual = result.robotId ?: @"";
    if (expected.length && ![expected isEqualToString:actual]) {
        return;
    }
    [self.pendingDirsRequests removeObjectForKey:key];
    if (!self.pendingDirsRequests.count) {
        [self stopDirsTimeoutTimer];
    }

    NSArray<NSString *> *dirs = result.dirs ?: @[];
    self.cwdCandidates = dirs;
    [self cacheDirs:dirs];
    //应答带当前工作目录：兜底刷新（操作冷却期不覆盖乐观更新）
    if (result.cwd.length && !self.applying) {
        self.currentCwd = result.cwd;
    }
    self.dirsStatusText = nil;
    self.dirsRequestFailed = NO;
    //截断提示（插件侧上限 3000 条）
    if (result.truncated && result.total > (NSInteger)dirs.count) {
        self.dirsHintText = [NSString stringWithFormat:@"已截断，仅显示 %lu 个（共 %ld 个）", (unsigned long)dirs.count, (long)result.total];
    } else {
        self.dirsHintText = nil;
    }
    [self refreshCurrentValues];
    [self.cwdPicker reload];
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
    //Agent 模式/工具审批：选项为空（部署未提供 / 旧版插件无该字段）时保持禁用，仅显示当前值文本
    self.presetDropdown.enabled = enabled && self.presetOptions.count > 0;
    self.approvalDropdown.enabled = enabled && self.approvalOptions.count > 0;
    self.cwdSwitchBtn.enabled = enabled;
    self.planSwitch.enabled = enabled;
    self.compactBtn.enabled = enabled;
    self.resetBtn.enabled = enabled;
    //销毁按钮不随操作冷却禁用（始终可点）
}

- (void)onBackgroundTapped {
    [self closePanel];
}

#pragma mark - UIGestureRecognizerDelegate

//只有点在遮罩空白处才关闭面板；卡片（含其全部子控件）内的点击一律交给控件自身处理。
//说明：手势识别器会收到"自身视图及其所有子视图"上的触摸，识别成功时默认取消这些触摸
//（cancelsTouchesInView=YES），于是卡片里的 UIControl 收不到 touchUpInside——表现就是
//"点沙箱单选没选中、面板直接关闭"。这里用 shouldReceiveTouch 把卡片内的触摸挡在手势之外。
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *touchView = touch.view;
    if (!touchView) {
        return YES;
    }
    //卡片自身或其子视图（header/footer/scrollView/contentView/各控件）→ 手势不接收
    return ![touchView isDescendantOfView:self.cardView];
}

- (void)closePanel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
