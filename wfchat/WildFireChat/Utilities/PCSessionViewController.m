//
//  PCSessionViewController.m
//  WildFireChat
//
//  Created by heavyrain lee on 2019/3/2.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "PCSessionViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatClient/WFCCNetworkService.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "MBProgressHUD.h"
#import "AppService.h"
#import "UIFont+YH.h"
#import "UIColor+YH.h"

#define CELL_HEIGHT 56
#define LOGOUT_ROW_HEIGHT 52
#define CARD_RADIUS 8.f
#define SECTION_SPACE 12
// 卡片头部高度（小图标 + 设备名/小字 + 右侧箭头）
#define DEVICE_HEADER_HEIGHT 66
// 卡片头部小平台图标尺寸
#define DEVICE_HEADER_ICON_SIZE 24.f
// 展开区顶部大图标区高度
#define DETAIL_HEADER_HEIGHT 150
// 展开区大平台图标尺寸
#define DETAIL_HEADER_ICON_SIZE 56.f
// 行分隔线 tag
#define DIVIDER_TAG 0x4D44

// 卡片头部行：Row[小图标(约24) + 设备名(加粗)/clientName 小字 竖排 + 右侧展开箭头(展开时旋转)]
@interface PCSessionDeviceCell : UITableViewCell
@property(nonatomic, strong)UIImageView *iconView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UILabel *subtitleLabel;
@property(nonatomic, strong)UIImageView *chevronView;
- (void)setExpanded:(BOOL)expanded;
@end

@implementation PCSessionDeviceCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor whiteColor];

        self.iconView = [[UIImageView alloc] init];
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.iconView];

        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = [UIFont scaledBoldSystemFontOfSize:16];
        self.nameLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
        self.nameLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.nameLabel];

        self.subtitleLabel = [[UILabel alloc] init];
        self.subtitleLabel.font = [UIFont scaledSystemFontOfSize:12];
        self.subtitleLabel.textColor = [UIColor colorWithHexString:@"0x999999"];
        self.subtitleLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.subtitleLabel];

        self.chevronView = [[UIImageView alloc] init];
        if (@available(iOS 13.0, *)) {
            self.chevronView.image = [[UIImage systemImageNamed:@"chevron.down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            self.chevronView.tintColor = [UIColor colorWithHexString:@"0x999999"];
        }
        [self.contentView addSubview:self.chevronView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    // 左侧小图标垂直居中
    self.iconView.frame = CGRectMake(16, (DEVICE_HEADER_HEIGHT - DEVICE_HEADER_ICON_SIZE) / 2, DEVICE_HEADER_ICON_SIZE, DEVICE_HEADER_ICON_SIZE);
    CGFloat textX = 16 + DEVICE_HEADER_ICON_SIZE + 12;
    CGFloat textW = w - textX - 16 - 16 - 6;
    // 右侧展开箭头垂直居中
    self.chevronView.frame = CGRectMake(w - 16 - 13, (DEVICE_HEADER_HEIGHT - 13) / 2, 13, 13);
    BOOL hasSubtitle = self.subtitleLabel.text.length > 0;
    if (hasSubtitle) {
        self.nameLabel.frame = CGRectMake(textX, 12, textW, 22);
        self.subtitleLabel.frame = CGRectMake(textX, 12 + 22 + 2, textW, 16);
    } else {
        self.nameLabel.frame = CGRectMake(textX, (DEVICE_HEADER_HEIGHT - 22) / 2, textW, 22);
        self.subtitleLabel.frame = CGRectZero;
    }
}

- (void)setExpanded:(BOOL)expanded {
    CGFloat angle = expanded ? M_PI : 0;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.chevronView.transform = CGAffineTransformMakeRotation(angle);
    } completion:nil];
}
@end

// 展开区顶部：大平台图标(约56)居中 + 设备名(大号加粗)居中 + clientName 小字居中
@interface PCSessionDetailHeaderCell : UITableViewCell
@property(nonatomic, strong)UIImageView *iconView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UILabel *subtitleLabel;
@end

@implementation PCSessionDetailHeaderCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor whiteColor];

        self.iconView = [[UIImageView alloc] init];
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.iconView];

        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = [UIFont scaledBoldSystemFontOfSize:18];
        self.nameLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.nameLabel];

        self.subtitleLabel = [[UILabel alloc] init];
        self.subtitleLabel.font = [UIFont scaledSystemFontOfSize:12];
        self.subtitleLabel.textColor = [UIColor colorWithHexString:@"0x999999"];
        self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.subtitleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat iconY = 20;
    self.iconView.frame = CGRectMake((w - DETAIL_HEADER_ICON_SIZE) / 2, iconY, DETAIL_HEADER_ICON_SIZE, DETAIL_HEADER_ICON_SIZE);
    CGFloat nameY = iconY + DETAIL_HEADER_ICON_SIZE + 12;
    self.nameLabel.frame = CGRectMake(16, nameY, w - 32, 24);
    if (self.subtitleLabel.text.length > 0) {
        self.subtitleLabel.frame = CGRectMake(16, nameY + 24 + 6, w - 32, 16);
    } else {
        self.subtitleLabel.frame = CGRectZero;
    }
}
@end

// 功能行 cell：contentView 内 左侧标题 + 右侧开关/箭头（不放 accessoryView，保证分割线/背景与 cell 一致）
@interface PCSessionActionCell : UITableViewCell
@property(nonatomic, strong)UILabel *titleLabel;
@property(nonatomic, strong)UISwitch *switchView;
@property(nonatomic, strong)UIImageView *chevronView;
@end

@implementation PCSessionActionCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor whiteColor];

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = [UIFont scaledSystemFontOfSize:16];
        self.titleLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.titleLabel];

        self.switchView = [[UISwitch alloc] init];
        self.switchView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.switchView];

        self.chevronView = [[UIImageView alloc] init];
        [self.contentView addSubview:self.chevronView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;
    self.titleLabel.frame = CGRectMake(16, 0, w - 16 - 16, h);
    self.switchView.frame = CGRectMake(w - 16 - self.switchView.bounds.size.width, (h - self.switchView.bounds.size.height) / 2, self.switchView.bounds.size.width, self.switchView.bounds.size.height);
    self.chevronView.frame = CGRectMake(w - 16 - 13, (h - 13) / 2, 13, 13);
}
@end

@interface PCSessionViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong)UITableView *tableView;
// 当前展开的卡片下标（对应 pcOnlineInfos），-1 表示全部收起
@property(nonatomic, assign)NSInteger expandedIndex;
// 当前展开设备的 clientId（锁定/退出操作目标）
@property(nonatomic, strong)NSString *expandedClientId;
@end

@implementation PCSessionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LocalizedString(@"LoggedInDevices");
    [self.view setBackgroundColor:[UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.f]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSettingUpdated:) name:kSettingUpdated object:nil];
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkPCOnlineStatus];
}

- (void)onSettingUpdated:(NSNotification *)notification {
    [self checkPCOnlineStatus];
}

// 设备列表变化：全部掉线则退出页面；展开索引越界则重置为第一张
- (void)checkPCOnlineStatus {
    NSArray<WFCCPCOnlineInfo *> *infos = [self otherOnlineInfos];
    if (!infos.count) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    self.pcOnlineInfos = infos;
    if (self.expandedIndex < 0 || self.expandedIndex >= (NSInteger)infos.count) {
        self.expandedIndex = 0;
    }
    if (self.tableView) {
        [self.tableView reloadData];
    }
}

//「已登录设备」管理页同样不列出本机：getPCOnlineInfos 会把本机（iPad 上就是自己）也算进去，
//与会话列表横幅同一套过滤规则，按 clientId 剔除。
- (NSArray<WFCCPCOnlineInfo *> *)otherOnlineInfos {
    NSString *selfClientId = [[WFCCNetworkService sharedInstance] getClientId];
    NSArray<WFCCPCOnlineInfo *> *onlines = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos];
    if (!selfClientId.length || !onlines.count) {
        return onlines;
    }
    NSMutableArray<WFCCPCOnlineInfo *> *others = [[NSMutableArray alloc] init];
    for (WFCCPCOnlineInfo *info in onlines) {
        if (![info.clientId isEqualToString:selfClientId]) {
            [others addObject:info];
        }
    }
    return others;
}

- (void)setupUI {
    self.expandedIndex = 0;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.f];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
}

#pragma mark - 平台信息

// 平台名称（微信风格），platform 未上报(UNSET)时按在线类型兜底
- (NSString *)deviceName:(WFCCPCOnlineInfo *)info {
    switch (info.platform) {
        case PlatformType_Windows:
            return @"Windows";
        case PlatformType_OSX:
            return @"Mac";
        case PlatformType_Linux:
            return @"Linux";
        case PlatformType_HarmonyPC:
            return LocalizedString(@"PlatformHarmonyPC");
        case PlatformType_WEB:
            return @"Web";
        case PlatformType_WX:
            return LocalizedString(@"PlatformMicroApp");
        case PlatformType_iPad:
            return @"iPad";
        case PlatformType_APad:
        case PlatformType_Android:
            return LocalizedString(@"PlatformAndroidPad");
        case PlatformType_HarmonyPad:
            return LocalizedString(@"PlatformHarmonyPad");
        default:
            break;
    }
    if (info.type == Web_Online) {
        return @"Web";
    }
    if (info.type == WX_Online) {
        return LocalizedString(@"PlatformMicroApp");
    }
    if (info.type == Pad_Online) {
        return LocalizedString(@"PlatformPad");
    }
    return LocalizedString(@"PlatformComputer");
}

// 展示用设备名小字：clientName 为空或为 "unknown" 时不显示
- (NSString *)displayDeviceName:(WFCCPCOnlineInfo *)info {
    NSString *name = info.clientName;
    if (name.length > 0 && ![name.lowercaseString isEqualToString:@"unknown"]) {
        return name;
    }
    return @"";
}

// 是否为桌面电脑类设备（支持「锁定」）
- (BOOL)isPcDesktopDevice:(WFCCPCOnlineInfo *)info {
    switch (info.platform) {
        case PlatformType_Windows:
        case PlatformType_OSX:
        case PlatformType_Linux:
        case PlatformType_HarmonyPC:
            return YES;
        default:
            return info.type == PC_Online;
    }
}

// 平台灰色图标：电脑/浏览器/手机/平板
- (UIImage *)platformIcon:(WFCCPCOnlineInfo *)info {
    NSString *symbol = @"desktopcomputer";
    if (info.type == WX_Online) {
        symbol = @"iphone";
    } else if (info.type == Web_Online) {
        symbol = @"globe";
    } else if (info.type == Pad_Online) {
        symbol = @"ipad";
    } else {
        switch (info.platform) {
            case PlatformType_Windows:
            case PlatformType_OSX:
            case PlatformType_Linux:
            case PlatformType_HarmonyPC:
                symbol = @"desktopcomputer";
                break;
            case PlatformType_WEB:
                symbol = @"globe";
                break;
            case PlatformType_WX:
                symbol = @"iphone";
                break;
            case PlatformType_iPad:
            case PlatformType_APad:
            case PlatformType_HarmonyPad:
                symbol = @"ipad";
                break;
            default:
                break;
        }
    }
    UIImage *image = nil;
    if (@available(iOS 13.0, *)) {
        image = [UIImage systemImageNamed:symbol];
    }
    if (!image) {
        image = [WFCUImage imageNamed:@"pc_session"];
    }
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // 每台设备一个 section（卡片）
    return self.pcOnlineInfos.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < 0 || section >= (NSInteger)self.pcOnlineInfos.count) {
        return 0;
    }
    NSInteger rows = 1; // 卡片头部
    if (self.expandedIndex == section) {
        rows += 1; // 展开区顶部大图标区
        rows += 1; // 手机通知
        WFCCPCOnlineInfo *info = self.pcOnlineInfos[section];
        if ([self isPcDesktopDevice:info]) {
            rows += 1; // 锁定
        }
        rows += 1; // 传文件
        rows += 1; // 退出登录
    }
    return rows;
}

- (UITableViewCell *)standardCellWithIdentifier:(NSString *)identifier tableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont scaledSystemFontOfSize:16];
        cell.textLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
    }
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    return cell;
}

// 行分隔线：加在 cell 底部（leftInset 为左侧缩进，0 表示通栏；visible=NO 时移除）
- (void)setDividerVisible:(BOOL)visible onCell:(UITableViewCell *)cell leftInset:(CGFloat)leftInset {
    UIView *divider = [cell.contentView viewWithTag:DIVIDER_TAG];
    if (visible) {
        if (!divider) {
            divider = [[UIView alloc] init];
            divider.tag = DIVIDER_TAG;
            divider.backgroundColor = [UIColor colorWithHexString:@"0xE5E5E5"];
            divider.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
            [cell.contentView addSubview:divider];
        }
        CGFloat h = cell.contentView.bounds.size.height;
        divider.frame = CGRectMake(leftInset, h - 0.5, MAX(cell.contentView.bounds.size.width - leftInset, 0), 0.5);
    } else {
        [divider removeFromSuperview];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger deviceIndex = indexPath.section;
    if (deviceIndex < 0 || deviceIndex >= (NSInteger)self.pcOnlineInfos.count) {
        return [self standardCellWithIdentifier:@"pc_empty_cell" tableView:tableView];
    }
    WFCCPCOnlineInfo *info = self.pcOnlineInfos[deviceIndex];
    BOOL expanded = (self.expandedIndex == deviceIndex);
    NSInteger rows = [self tableView:tableView numberOfRowsInSection:indexPath.section];

    if (indexPath.row == 0) {
        // 卡片头部：Row[小图标 + 设备名(加粗)/clientName 小字 + 展开箭头]
        PCSessionDeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pc_device_cell"];
        if (!cell) {
            cell = [[PCSessionDeviceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"pc_device_cell"];
        }
        cell.nameLabel.text = [self deviceName:info];
        cell.subtitleLabel.text = [self displayDeviceName:info];
        cell.iconView.image = [self platformIcon:info];
        cell.iconView.tintColor = [UIColor colorWithHexString:@"0x666666"];
        [cell setExpanded:expanded];
        return cell;
    }

    if (!expanded) {
        return [self standardCellWithIdentifier:@"pc_empty_cell" tableView:tableView];
    }

    self.expandedClientId = info.clientId;

    // 展开内容行序号（自底向上）：退出登录=rows-1、传文件=rows-2、锁定=rows-3(仅桌面)、手机通知在其上
    NSInteger logoutRow = rows - 1;
    NSInteger transferRow = rows - 2;
    BOOL hasLock = [self isPcDesktopDevice:info];
    NSInteger lockRow = hasLock ? rows - 3 : -1;
    NSInteger muteRow = hasLock ? rows - 4 : rows - 3;

    if (indexPath.row == 1) {
        // 展开区顶部：大图标居中 + 设备名 + clientName，底部通栏分隔线
        PCSessionDetailHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pc_detail_cell"];
        if (!cell) {
            cell = [[PCSessionDetailHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"pc_detail_cell"];
        }
        cell.nameLabel.text = [self deviceName:info];
        cell.subtitleLabel.text = [self displayDeviceName:info];
        cell.iconView.image = [self platformIcon:info];
        cell.iconView.tintColor = [UIColor colorWithHexString:@"0x666666"];
        [self setDividerVisible:YES onCell:cell leftInset:0];
        return cell;
    }

    if (indexPath.row == muteRow) {
        // 手机通知（全局 isMuteNotificationWhenPcOnline，原「手机静音」开关逻辑复用）
        PCSessionActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pc_mute_cell"];
        if (!cell) {
            cell = [[PCSessionActionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"pc_mute_cell"];
        }
        cell.chevronView.hidden = YES;
        cell.titleLabel.text = LocalizedString(@"MutePhone");
        cell.switchView.hidden = NO;
        cell.switchView.on = [[WFCCIMService sharedWFCIMService] isMuteNotificationWhenPcOnline];
        [cell.switchView addTarget:self action:@selector(onMuteSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        [self setDividerVisible:YES onCell:cell leftInset:16];
        return cell;
    }

    if (indexPath.row == lockRow) {
        // 锁定（仅桌面电脑类设备）
        PCSessionActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pc_lock_cell"];
        if (!cell) {
            cell = [[PCSessionActionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"pc_lock_cell"];
        }
        cell.chevronView.hidden = YES;
        cell.titleLabel.text = LocalizedString(@"LockPC");
        cell.switchView.hidden = NO;
        cell.switchView.on = [[WFCCIMService sharedWFCIMService] isPCClientLocked:info.clientId];
        [cell.switchView addTarget:self action:@selector(onLockSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        [self setDividerVisible:YES onCell:cell leftInset:16];
        return cell;
    }

    if (indexPath.row == transferRow) {
        // 传文件：文字 + 右侧灰色箭头（点击跳文件传输助手）
        PCSessionActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pc_transfer_cell"];
        if (!cell) {
            cell = [[PCSessionActionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"pc_transfer_cell"];
        }
        cell.titleLabel.text = LocalizedString(@"TransferFile");
        cell.switchView.hidden = YES;
        cell.chevronView.hidden = NO;
        if (@available(iOS 13.0, *)) {
            cell.chevronView.image = [[UIImage systemImageNamed:@"chevron.right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.chevronView.tintColor = [UIColor colorWithHexString:@"0x999999"];
        } else {
            cell.chevronView.image = [WFCUImage imageNamed:@"pc_session"];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        [self setDividerVisible:YES onCell:cell leftInset:16];
        return cell;
    }

    if (indexPath.row == logoutRow) {
        // 退出登录（文字居中、红色，点击 kickoff 该设备）
        UITableViewCell *cell = [self standardCellWithIdentifier:@"pc_logout_cell" tableView:tableView];
        cell.textLabel.text = [NSString stringWithFormat:LocalizedString(@"LogoutDeviceLogin"), [self deviceName:info]];
        cell.textLabel.textColor = [UIColor colorWithHexString:@"0xFA5151"];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        [self setDividerVisible:NO onCell:cell leftInset:0];
        return cell;
    }

    return [self standardCellWithIdentifier:@"pc_empty_cell" tableView:tableView];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger deviceIndex = indexPath.section;
    if (deviceIndex >= 0 && deviceIndex < (NSInteger)self.pcOnlineInfos.count) {
        if (indexPath.row == 0) {
            return DEVICE_HEADER_HEIGHT;
        }
        if (indexPath.row == 1) {
            return DETAIL_HEADER_HEIGHT;
        }
        NSInteger rows = [self tableView:tableView numberOfRowsInSection:indexPath.section];
        if (indexPath.row == rows - 1) {
            return LOGOUT_ROW_HEIGHT;
        }
        return CELL_HEIGHT;
    }
    return CELL_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return SECTION_SPACE;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, SECTION_SPACE)];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

// 白色圆角卡片：每个 section 为一个卡片，首行圆上角、末行圆下角
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rows = [self tableView:tableView numberOfRowsInSection:indexPath.section];
    [self applyRoundMask:cell first:(indexPath.row == 0) last:(indexPath.row == rows - 1)];
}

- (void)applyRoundMask:(UITableViewCell *)cell first:(BOOL)first last:(BOOL)last {
    UIRectCorner corners = 0;
    if (first) {
        corners |= UIRectCornerTopLeft | UIRectCornerTopRight;
    }
    if (last) {
        corners |= UIRectCornerBottomLeft | UIRectCornerBottomRight;
    }
    if (corners == 0) {
        cell.contentView.layer.mask = nil;
        return;
    }
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:cell.contentView.bounds
                                               byRoundingCorners:corners
                                                     cornerRadii:CGSizeMake(CARD_RADIUS, CARD_RADIUS)];
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = path.CGPath;
    cell.contentView.layer.mask = mask;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger deviceIndex = indexPath.section;
    if (deviceIndex < 0 || deviceIndex >= (NSInteger)self.pcOnlineInfos.count) {
        return;
    }
    WFCCPCOnlineInfo *info = self.pcOnlineInfos[deviceIndex];
    if (indexPath.row == 0) {
        // 点击卡片头部：展开/收起（手风琴）
        [self toggleExpand:deviceIndex];
        return;
    }
    NSInteger rows = [self tableView:tableView numberOfRowsInSection:indexPath.section];
    if (indexPath.row == rows - 1) {
        // 退出登录
        [self kickoffDevice:info];
        return;
    }
    if (indexPath.row == rows - 2) {
        // 传文件
        [self openFileTransfer];
        return;
    }
}

#pragma mark - 手风琴

- (void)toggleExpand:(NSInteger)index {
    NSInteger oldIndex = self.expandedIndex;
    if (oldIndex == index) {
        // 点击已展开的卡片：收起
        self.expandedIndex = -1;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationFade];
    } else {
        // 展开当前、收起其它
        self.expandedIndex = index;
        NSMutableIndexSet *sections = [[NSMutableIndexSet alloc] init];
        [sections addIndex:index];
        if (oldIndex >= 0) {
            [sections addIndex:oldIndex];
        }
        [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Actions

- (void)onMuteSwitchChanged:(UISwitch *)sender {
    BOOL isMute = sender.on;
    __weak typeof(self)ws = self;
    __weak UISwitch *weakSwitch = sender;
    [[WFCCIMService sharedWFCIMService] muteNotificationWhenPcOnline:isMute success:^{
        // 成功
    } error:^(int error_code) {
        // 失败，恢复开关状态
        [weakSwitch setOn:!isMute animated:YES];
        [ws showError:@"设置失败"];
    }];
}

- (void)onLockSwitchChanged:(UISwitch *)sender {
    BOOL isLock = sender.on;
    NSString *clientId = self.expandedClientId;
    __weak typeof(self)ws = self;
    __weak UISwitch *weakSwitch = sender;
    [[WFCCIMService sharedWFCIMService] lockPCClient:clientId isLock:isLock success:^{
        // 成功
    } error:^(int error_code) {
        // 失败，恢复开关状态
        [weakSwitch setOn:!isLock animated:YES];
        [ws showError:@"设置失败"];
    }];
}

- (void)kickoffDevice:(WFCCPCOnlineInfo *)info {
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] kickoffPCClient:info.clientId success:^{
        [ws showMessage:LocalizedString(@"LogoutSuccess")];
        [ws checkPCOnlineStatus];
    } error:^(int error_code) {
        [ws showError:LocalizedString(@"NetworkError")];
    }];
}

- (void)openFileTransfer {
    if ([WFCUConfigManager globalManager].fileTransferId) {
        WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
        mvc.conversation = [WFCCConversation conversationWithType:Single_Type target:[WFCUConfigManager globalManager].fileTransferId line:0];
        mvc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:mvc animated:YES];
    }
}

- (void)showMessage:(NSString *)message {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = message;
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    [hud hideAnimated:YES afterDelay:1.f];
}

- (void)showError:(NSString *)message {
    [self showMessage:message];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
