//
//  ViewController.m
//  WFZoom
//
//  Created by WF Chat on 2021/9/3.
//  Copyright © 2021年 WildFireChat. All rights reserved.
//

#import "WFZHomeViewController.h"
#import "WFZStartConferenceViewController.h"
#import "WFZOrderConferenceViewController.h"
#import <SDWebImage/SDWebImage.h>
#import <WFChatClient/WFCChatClient.h>
#import "WFZConferenceInfoViewController.h"
#import "WFCUConfigManager.h"
#import "WFZConferenceInfo.h"
#import "WFCUImage.h"
#import "WFZConferenceHistoryListViewController.h"
#import "WFCUUtilities.h"
#import "WFCUConfigManager.h"

@interface WFZHomeViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong)UIView *topPanel;
@property(nonatomic, strong)UITableView *tableView;

@property(nonatomic, strong)UIButton *joinButton;
@property(nonatomic, strong)UIButton *startButton;
@property(nonatomic, strong)UIButton *orderButton;
@property(nonatomic, strong)UIView *topLine;

@property(nonatomic, strong)NSString *privateConferenceId;


@property(nonatomic, strong)NSArray<WFZConferenceInfo *> *favConferences;

@property(nonatomic, strong)UIImageView *emptyImageView;
@property(nonatomic, strong)UILabel *emptyLabel;

@property(nonatomic, strong)UIButton *historyButton;
@end

@implementation WFZHomeViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = WFCString(@"Conference");
    
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kCONFERENCE_DESTROYED object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {
        [ws reloadData];
    }];
    
    
    [self initTopPannel];
    [self initTableView];
    [self showHistoryButton];
    NSArray *arrays = [[NSUserDefaults standardUserDefaults] objectForKey:@"SAVED_CONFERENCE_LIST"];
    NSMutableArray *fcs = [[NSMutableArray alloc] init];
    
    NSDate *now = [[NSDate alloc] init];
    for (NSDictionary *dict in arrays) {
        WFZConferenceInfo *info = [WFZConferenceInfo fromDictionary:dict];
        if([now timeIntervalSince1970] < info.endTime) {
            [fcs addObject:info];
        }
    }
    self.favConferences = fcs;
    if(self.isPresent) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(onLeftBarBtn:)];
    }
    [self layoutViews];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    //iPad 右栏里 viewDidLoad 那一刻的 bounds 可能是整屏宽（转场首帧按整屏排），
    //布局要在每次布局时按当前宽度重排；iPhone 上 bounds 恒等于屏幕宽，取值不变。
    [self layoutViews];
}

//所有子视图按当前 bounds 重新排一遍（创建与定位分离：控件只建一次，位置每次重算）
- (void)layoutViews {
    CGRect bounds = self.view.bounds;
    if (bounds.size.width <= 0 || bounds.size.height <= 0) {
        return;
    }
    
    CGFloat offset = [WFCUUtilities wf_navigationFullHeight] + 32;
    CGFloat btnSize = 80;
    CGFloat labelHeight = 30;
    if (@available(iOS 13, *)) {
        labelHeight = 0;
    }
    CGFloat padding = (bounds.size.width - 3*btnSize)/3;
    self.topPanel.frame = CGRectMake(0, 0, bounds.size.width, 0);
    self.joinButton.frame = CGRectMake(padding/2, offset, btnSize, btnSize+labelHeight);
    self.startButton.frame = CGRectMake(padding/2 + padding + btnSize, offset, btnSize, btnSize+labelHeight);
    self.orderButton.frame = CGRectMake(bounds.size.width-btnSize-padding/2, offset, btnSize, btnSize+labelHeight);
    //标题在图片下方的 insets 必须在按钮有真实尺寸、内部子视图排版完成后才算：
    //创建时（CGRectZero）imageView/titleLabel 还是 0，算出来标题会压到图片上/看不见
    [self.joinButton layoutIfNeeded];
    [self layoutButtonText:self.joinButton];
    [self.startButton layoutIfNeeded];
    [self layoutButtonText:self.startButton];
    [self.orderButton layoutIfNeeded];
    [self layoutButtonText:self.orderButton];
    
    offset += btnSize;
    offset += labelHeight;
    offset += 30;
    self.topLine.frame = CGRectMake(0, offset, bounds.size.width, 1);
    offset += 1;
    CGRect frame = self.topPanel.frame;
    frame.size.height = offset;
    self.topPanel.frame = frame;
    
    CGRect topFrame = self.topPanel.frame;
    self.tableView.frame = CGRectMake(0, topFrame.origin.y + topFrame.size.height, topFrame.size.width, bounds.size.height - topFrame.origin.y - topFrame.size.height);
    self.historyButton.frame = CGRectMake(bounds.size.width - 85, topFrame.origin.y + topFrame.size.height + 36, 100, 30);
    self.emptyLabel.frame = CGRectMake(bounds.size.width/2 - 100, bounds.size.height/2 + 60, 200, 20);
    self.emptyImageView.center = CGPointMake(bounds.size.width/2, bounds.size.height/2);
}

- (void)onLeftBarBtn:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)initTopPannel {
    self.topPanel = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.topPanel];
    
    self.joinButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.joinButton setImage:[WFCUImage imageNamed:@"join_conference"] forState:UIControlStateNormal];
    [self.joinButton setTitle:WFCString(@"JoinConference") forState:UIControlStateNormal];
    [self.joinButton addTarget:self action:@selector(onJoinBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    self.startButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.startButton setImage:[WFCUImage imageNamed:@"start_conference"] forState:UIControlStateNormal];
    [self.startButton setTitle:WFCString(@"StartConference") forState:UIControlStateNormal];
    [self.startButton addTarget:self action:@selector(onStartBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    self.orderButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.orderButton setImage:[WFCUImage imageNamed:@"order_conference"] forState:UIControlStateNormal];
    [self.orderButton setTitle:WFCString(@"OrderConference") forState:UIControlStateNormal];
    [self.orderButton addTarget:self action:@selector(onOrderBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.topPanel addSubview:self.joinButton];
    [self.topPanel addSubview:self.startButton];
    [self.topPanel addSubview:self.orderButton];
    
    self.topLine = [[UIView alloc] initWithFrame:CGRectZero];
    self.topLine.backgroundColor = [WFCUConfigManager globalManager].separateColor;
    [self.topPanel addSubview:self.topLine];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)reloadData {
    __weak typeof(self)ws = self;
    
    [[WFCUConfigManager globalManager].appServiceProvider getFavConferences:^(NSArray<WFZConferenceInfo *> * _Nonnull conferences) {
        ws.favConferences = conferences;
        NSMutableArray *arrays = [[NSMutableArray alloc] init];
        for (WFZConferenceInfo *info in conferences) {
            [arrays addObject:[info toDictionary]];
        }
        [[NSUserDefaults standardUserDefaults] setObject:arrays forKey:@"SAVED_CONFERENCE_LIST"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } error:^(int errorCode, NSString * _Nonnull message) {
        NSLog(@"error");
    }];
}

- (void)setFavConferences:(NSArray<WFZConferenceInfo *> *)favConferences {
    _favConferences = favConferences;
    [self showEmptyConference:favConferences.count == 0];
    [self.tableView reloadData];
}

- (void)showEmptyConference:(BOOL)empty {
    self.emptyLabel.hidden = !empty;
    self.emptyImageView.hidden = !empty;
}

- (void)layoutButtonText:(UIButton *)button {
//    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [button.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [button setTitleColor:HEXCOLOR(0x0195ff) forState:UIControlStateNormal];
    button.imageView.layer.masksToBounds = YES;
    button.imageView.layer.cornerRadius = 8.f;
    //图标保持纵横比，绝不被压扁
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;

    [button layoutIfNeeded];
    CGFloat spacing = 6;
    CGFloat imageW = button.imageView.frame.size.width;
    CGFloat imageH = button.imageView.frame.size.height;
    CGFloat titleW = button.titleLabel.frame.size.width;
    CGFloat titleH = button.titleLabel.frame.size.height;

    //图片在上、文字在下，各自水平居中（标准 image-above-text 公式）。
    //注意：imageEdgeInsets 的 right 用 -文字宽（把图片拉回中间），而不是 left 用 +文字宽
    //（那会把图片往右挤、可用宽度变小，图标被压扁）。
    button.titleEdgeInsets = UIEdgeInsetsMake(imageH + spacing, -imageW, 0, 0);
    button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, titleH + spacing, -titleW);
}

- (void)onJoinBtn:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"请输入会议号及密码" preferredStyle:UIAlertControllerStyleAlert];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入会议号";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入会议密码（如果没有密码，请忽略）";
    }];
        
    [alertController addAction:[UIAlertAction actionWithTitle:WFCString(@"Ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *conferenceId = alertController.textFields.firstObject.text;
        NSString *pwd = alertController.textFields[1].text;
        WFZConferenceInfoViewController *vc = [[WFZConferenceInfoViewController alloc] init];
        vc.conferenceId = conferenceId;
        vc.password = pwd;
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:nav animated:YES completion:nil];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertController animated:true completion:nil];
}

- (void)onStartBtn:(id)sender {
    WFZStartConferenceViewController *vc = [[WFZStartConferenceViewController alloc] init];
    vc.createResult = ^(WFZConferenceInfo * _Nonnull conferenceInfo) {
        WFZConferenceInfoViewController *vc = [[WFZConferenceInfoViewController alloc] init];
        vc.conferenceId = conferenceInfo.conferenceId;
        vc.password = conferenceInfo.password;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:nav animated:YES completion:^{
                        
        }];
    };
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onOrderBtn:(id)sender {
    WFZOrderConferenceViewController *vc = [[WFZOrderConferenceViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)initTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    [self.view addSubview:self.tableView];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
}

- (UILabel *)emptyLabel {
    if (!_emptyLabel) {
        _emptyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _emptyLabel.font = [UIFont systemFontOfSize:14];
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.text = WFCString(@"NoConference");
        _emptyLabel.textColor = [UIColor grayColor];
        [self.view addSubview:_emptyLabel];
    }
    return _emptyLabel;
}

- (UIImageView *)emptyImageView {
    if (!_emptyImageView) {
        UIImage *img = [UIImage imageNamed:@"tea"];
        _emptyImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, img.size.width*2, img.size.height*2)];
        _emptyImageView.image = img;
        _emptyImageView.alpha = 0.5;
        [self.view addSubview:_emptyImageView];
    }
    return _emptyImageView;
}

- (void)showHistoryButton {
    self.historyButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.historyButton setTitle:WFCString(@"ConferenceHistory") forState:UIControlStateNormal];
    self.historyButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.historyButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    self.historyButton.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.9];
    self.historyButton.layer.cornerRadius = 15;
    self.historyButton.layer.borderColor = [UIColor blackColor].CGColor;
    [self.historyButton addTarget:self action:@selector(onHistoryButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.historyButton];
}

- (void)onHistoryButton:(id)sender {
    WFZConferenceHistoryListViewController *histVC = [[WFZConferenceHistoryListViewController alloc] init];
    [self.navigationController pushViewController:histVC animated:YES];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    WFZConferenceInfo *info = self.favConferences[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = info.conferenceTitle;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [[NSDate alloc] init];
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:info.startTime];
    
    NSString *detail;
    if([now timeIntervalSince1970] > info.endTime) {
        detail = @"会议已结束";
    } else if([now timeIntervalSince1970] > info.startTime ) {
        detail = @"会议已开始，请尽快加入";
    } else {
        NSDateFormatter * formatter = [NSDateFormatter new];
        
        if([calendar component:NSCalendarUnitDay fromDate:startDate] == [calendar component:NSCalendarUnitDay fromDate:now]) {
            detail = @"今天";
        } else {
            formatter.dateFormat=@"MM月dd日";
            detail = [formatter stringFromDate:startDate];
        }
        
        formatter.dateFormat=@"HH：mm";
        detail = [detail stringByAppendingFormat:@" %@ 开始会议", [formatter stringFromDate:startDate]];
    }
    cell.detailTextLabel.text = detail;
    
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.favConferences.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFZConferenceInfo *info = self.favConferences[indexPath.row];
    WFZConferenceInfoViewController *vc = [[WFZConferenceInfoViewController alloc] init];
    vc.conferenceId = info.conferenceId;
    vc.password = info.password;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        WFZConferenceInfo *info = self.favConferences[indexPath.row];
        __weak typeof(self)ws = self;
        [[WFCUConfigManager globalManager].appServiceProvider unfavConference:info.conferenceId success:^{
            [ws reloadData];
        } error:^(int errorCode, NSString * _Nonnull message) {
            
        }];
    }
}
@end
