//
//  StartConferenceViewController.m
//  WFZoom
//
//  Created by WF Chat on 2021/9/3.
//  Copyright © 2021年 WildFireChat. All rights reserved.
//

#import "WFZStartConferenceViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "MBProgressHUD.h"
#import "WFZConferenceInfoViewController.h"
#import "WFCUConfigManager.h"
#import "WFZConferenceInfo.h"
#import "WFCUConferenceViewController.h"
#import "WFCUGeneralSwitchTableViewCell.h"
#import "WFCUGeneralModifyViewController.h"
#import "WFCUUtilities.h"


@interface WFZStartConferenceViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;

@property(nonatomic, assign)BOOL enableAudio;
@property(nonatomic, assign)BOOL enableVideo;

//成员加入时是否为主播
@property(nonatomic, assign)BOOL enableParticipant;
//成员是否可以切换主播/观众状态
@property(nonatomic, assign)BOOL enableSwitchMode;

@property(nonatomic, assign)BOOL advanceConference;

@property(nonatomic, assign)BOOL userPrivateConferenceId;
@property(nonatomic, strong)NSString *privateConferenceId;

@property(nonatomic, assign)BOOL enablePassword;
@property(nonatomic, strong)NSString *password;

@property(nonatomic, strong)NSString *conferenceTitle;

@property(nonatomic, assign)long long startTime;
@property(nonatomic, assign)long long endTime;

@property(nonatomic, strong)UIButton *joinBtn;

@property (nonatomic, strong) UIDatePicker *datePicker;
@end

@implementation WFZStartConferenceViewController
#if WFCU_SUPPORT_VOIP
- (void)viewDidLoad {
    [super viewDidLoad];
    self.enableAudio = YES;
    self.enableVideo = NO;
    self.enableParticipant = YES;
    self.enableSwitchMode = YES;
    self.advanceConference = NO;
    
    self.startTime = 0;
    self.endTime = [[[NSDate alloc] init] timeIntervalSince1970] + 3600;
    self.privateConferenceId = [[NSUserDefaults standardUserDefaults] stringForKey:WFZOOM_PRIVATE_CONFERENCE_ID];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [self.view addSubview:self.tableView];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(onLeftBarBtn:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"创建" style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor redColor];
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
    self.conferenceTitle = [NSString stringWithFormat:@"%@ 发起的会议", userInfo.displayName];
    [self.tableView reloadData];
}

- (void)onStartConference:(id)sender {
    [self createConference:YES];
}

- (void)createConference:(BOOL)andJoin {
    self.joinBtn.enabled = NO;
    self.navigationItem.rightBarButtonItem = nil;
    
    WFZConferenceInfo *info = [[WFZConferenceInfo alloc] init];
    if(self.userPrivateConferenceId) {
        info.conferenceId = self.privateConferenceId;
    }
    info.conferenceTitle = self.conferenceTitle;
    info.owner = [WFCCNetworkService sharedInstance].userId;
    if(self.enablePassword) {
        info.password = self.password;
    }
    info.pin = [NSString stringWithFormat:@"%d%d%d%d", arc4random()%10,arc4random()%10,arc4random()%10,arc4random()%10];
    info.startTime = self.startTime;
    info.endTime = self.endTime;
    info.audience = !self.enableParticipant;
    info.advance = self.advanceConference;
    info.allowSwitchMode = self.enableSwitchMode;
    
    __block MBProgressHUD *hud = [self startProgress:@"创建中"];
    __weak typeof(self)ws = self;
    [[WFCUConfigManager globalManager].appServiceProvider createConference:info success:^(NSString * _Nonnull conferenceId) {
        info.conferenceId = conferenceId;
        if(andJoin) {
            [ws stopProgress:hud finishText:nil];
            WFCUConferenceViewController *vc = [[WFCUConferenceViewController alloc] initWithConferenceInfo:info muteAudio:!self.enableAudio muteVideo:!self.enableVideo];
            [[WFAVEngineKit sharedEngineKit] presentViewController:vc];
            [self.navigationController dismissViewControllerAnimated:NO completion:nil];
        } else {
            [ws stopProgress:hud finishText:@"创建成功"];
            [self dismissViewControllerAnimated:NO completion:^{
                if(self.createResult) {
                    self.createResult(info);
                }
            }];
        }
    } error:^(int errorCode, NSString * _Nonnull message) {
        NSLog(@"error");
        [ws stopProgress:hud finishText:@"网络错误，请稍后重试！"];
    }];
}

- (void)onLeftBarBtn:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)onRightBarBtn:(id)sender {
    [self createConference:NO];
}

- (MBProgressHUD *)startProgress:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = text;
    [hud showAnimated:YES];
    return hud;
}

- (MBProgressHUD *)stopProgress:(MBProgressHUD *)hud finishText:(NSString *)text {
    [hud hideAnimated:YES];
    if(text) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = text;
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
    }
    return hud;
}

- (void)setupDateKeyPan {
    CGRect bounds = self.view.bounds;
    CGFloat pickerHeight = 200;
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, bounds.size.height - pickerHeight - [WFCUUtilities wf_safeDistanceBottom] - 34, bounds.size.width, pickerHeight + [WFCUUtilities wf_safeDistanceBottom] + 34)];
    container.backgroundColor = [UIColor whiteColor];
    container.layer.borderWidth = 1.f;
    container.layer.borderColor = [UIColor grayColor].CGColor;
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 34, bounds.size.width, pickerHeight)];
    datePicker.locale = [NSLocale localeWithLocaleIdentifier:@"zh"];
    datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    [datePicker setDate:[NSDate dateWithTimeIntervalSince1970:self.endTime] animated:YES];
    [datePicker setMinimumDate:[NSDate date]];
    
    self.datePicker = datePicker;
    [container addSubview:self.datePicker];
    
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(16, 16, 64, 18)];
    UIButton *okBtn = [[UIButton alloc] initWithFrame:CGRectMake(bounds.size.width - 16 - 64, 16, 64, 18)];
    [cancelBtn setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(onCancelDataPicker:) forControlEvents:UIControlEventTouchUpInside];
    [cancelBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [okBtn setTitle:@"OK" forState:UIControlStateNormal];
    [okBtn addTarget:self action:@selector(onConfirmDataPicker:) forControlEvents:UIControlEventTouchUpInside];
    [okBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [container addSubview:cancelBtn];
    [container addSubview:okBtn];
    
    [self.view addSubview:container];
}

- (void)onCancelDataPicker:(id)sender {
    [self.datePicker.superview removeFromSuperview];
    self.datePicker = nil;
}

- (void)onConfirmDataPicker:(id)sender {
    NSDate *date = self.datePicker.date;
    [self.datePicker.superview removeFromSuperview];
    self.datePicker = nil;
    self.endTime = [date timeIntervalSince1970];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    __weak typeof(self)ws = self;
    
    if(indexPath.section == 0) {
        UITableViewCell *titleCell = [tableView dequeueReusableCellWithIdentifier:@"title"];
        if (!titleCell) {
            titleCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"title"];
        }
        titleCell.textLabel.text = @"会议主题";
        titleCell.detailTextLabel.text = self.conferenceTitle;
        return titleCell;
    } else if(indexPath.section == 1) {
        UITableViewCell *timeCell = [tableView dequeueReusableCellWithIdentifier:@"time"];
        if (!timeCell) {
            timeCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"time"];
            timeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        if (indexPath.row == 0) {
            timeCell.textLabel.text = @"开始时间";
            if (self.startTime == 0) {
                timeCell.detailTextLabel.text = @"现在";
            } else {
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.startTime];
                timeCell.detailTextLabel.text = [date descriptionWithLocale:[NSLocale systemLocale]];
            }
        } else {
            timeCell.textLabel.text = @"结束时间";
            if (self.endTime == 0) {
                timeCell.detailTextLabel.text = @"无限制";
            } else {
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.endTime];
                timeCell.detailTextLabel.text = [date descriptionWithLocale:[NSLocale systemLocale]];
            }
        }
        
        return timeCell;
    } else if(indexPath.section == 2) {
        WFCUGeneralSwitchTableViewCell *switchCell = [[WFCUGeneralSwitchTableViewCell alloc] init];
        if(indexPath.row == 0) {
            switchCell.textLabel.text = @"参与者开启摄像头、麦克风入会";
            switchCell.on = self.enableParticipant;
            switchCell.onSwitch = ^(BOOL value, int type, void (^handleBlock)(BOOL success)) {
                ws.enableParticipant = value;
                WFCUGeneralSwitchTableViewCell *switchModeCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2]];
                
                if(!ws.enableParticipant) {
                    switchModeCell.valueSwitch.enabled = YES;
                } else {
                    ws.enableSwitchMode = YES;
                    switchModeCell.on = YES;
                    switchModeCell.valueSwitch.enabled = NO;
                }
                handleBlock(YES);
            };
        } else {
            if(!self.enableParticipant) {
                switchCell.valueSwitch.enabled = YES;
            } else {
                self.enableSwitchMode = YES;
                switchCell.valueSwitch.enabled = NO;
            }
            switchCell.textLabel.text = @"允许参与者自主开启摄像头、麦克风";
            switchCell.on = self.enableSwitchMode;
            switchCell.onSwitch = ^(BOOL value, int type, void (^handleBlock)(BOOL success)) {
                ws.enableSwitchMode = value;
                handleBlock(YES);
            };
        }
        return switchCell;
    } else if(indexPath.section == 3) {
        WFCUGeneralSwitchTableViewCell *cell = [[WFCUGeneralSwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"switch2"];
        
        if(indexPath.row == 0) {
            if(!self.enablePassword) {
                self.password = nil;
            }
            cell.textLabel.text = @"启用密码";
            cell.detailTextLabel.text = self.password;
            cell.on = self.enablePassword;
            cell.onSwitch = ^(BOOL value, int type, void (^onDone)(BOOL success)) {
                ws.enablePassword = value;
                onDone(YES);
                if(value) {
                    [ws editPassword];
                } else {
                    [ws.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:3]] withRowAnimation:UITableViewRowAnimationFade];
                }
            };
        } else {
            cell.textLabel.text = @"使用个人会议号";
            if(self.advanceConference) {
                self.userPrivateConferenceId = NO;
                cell.valueSwitch.enabled = NO;
            } else {
                cell.valueSwitch.enabled = YES;
            }
            cell.detailTextLabel.text = self.privateConferenceId;
            cell.on = self.userPrivateConferenceId;
            cell.onSwitch = ^(BOOL value, int type, void (^onDone)(BOOL success)) {
                ws.userPrivateConferenceId = value;
                [ws.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:4]] withRowAnimation:UITableViewRowAnimationFade];
                onDone(YES);
            };
        }
        
        
        return cell;
        
    } else if(indexPath.section == 4) {
        WFCUGeneralSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch"];
        if (cell == nil) {
            cell = [[WFCUGeneralSwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"switch"];
        }
        if(self.userPrivateConferenceId) {
            self.advanceConference = NO;
            cell.valueSwitch.enabled = NO;
        } else {
            cell.valueSwitch.enabled = YES;
        }
        cell.textLabel.text = @"大规模会议";
        cell.detailTextLabel.attributedText = [[NSAttributedString alloc] initWithString:@"参会人员大于50人" attributes:@{NSForegroundColorAttributeName : [UIColor redColor]}];
        cell.on = self.advanceConference;
        cell.onSwitch = ^(BOOL value, int type, void (^onDone)(BOOL success)) {
            ws.advanceConference = value;
            [ws.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:3]] withRowAnimation:UITableViewRowAnimationFade];
            onDone(YES);
        };
        
        return cell;
    } else {
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        for (UIView *subView in cell.contentView.subviews) {
            [subView removeFromSuperview];
        }
        if(!self.joinBtn) {
            self.joinBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];
            [self.joinBtn setTitle:@"进入会议室" forState:UIControlStateNormal];
            [self.joinBtn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
            [self.joinBtn addTarget:self action:@selector(onStartConference:) forControlEvents:UIControlEventTouchUpInside];
        }
        if (@available(iOS 14, *)) {
            [cell.contentView addSubview:self.joinBtn];
        } else {
            [cell addSubview:self.joinBtn];
        }
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return 0;
    }
    return 10;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] init];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return 1;
    } else if(section == 1){
        return 2;
    } else if(section == 2) {
        return 2;
    } else if(section == 3) {
        return 2;
    } else if(section == 4) {
        return 1;
    } else {
        return 1;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        if(indexPath.row == 0) {
            WFCUGeneralModifyViewController *vc = [[WFCUGeneralModifyViewController alloc] init];
            vc.defaultValue = self.conferenceTitle;
            vc.titleText = @"会议主题";
            vc.noProgress = YES;
            __weak typeof(self) ws = self;
            vc.tryModify = ^(NSString *newValue, void (^result)(BOOL success)) {
                if (newValue) {
                    ws.conferenceTitle = newValue;
                    [ws.tableView reloadData];
                    result(YES);
                }
            };
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            [self.navigationController presentViewController:nav animated:YES completion:nil];
        }
    } else if(indexPath.section == 1) {
        if(indexPath.row == 1) {
            [self setupDateKeyPan];
        }
    } else if(indexPath.section == 3) {
        if(indexPath.row == 0) {
            [self editPassword];
        }
    }
}

- (void)editPassword {
    if(!self.enablePassword) {
        return;
    }
    WFCUGeneralModifyViewController *vc = [[WFCUGeneralModifyViewController alloc] init];
    vc.defaultValue = self.password;
    vc.titleText = @"会议密码";
    vc.noProgress = YES;
    __weak typeof(self) ws = self;
    vc.tryModify = ^(NSString *newValue, void (^result)(BOOL success)) {
        if (newValue) {
            ws.password = newValue;
            if(!newValue.length) {
                ws.enablePassword = NO;
            }
            [ws.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:3]] withRowAnimation:UITableViewRowAnimationFade];
            result(YES);
        }
    };
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}
#endif
@end
