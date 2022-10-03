//
//  WFCUConferenceMemberManagerViewController.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2021/2/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//
#if WFCU_SUPPORT_VOIP
#import "WFCUConferenceMemberManagerViewController.h"
#import "UIColor+YH.h"

#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUUtilities.h"
#import "WFCUConferenceMember.h"
#import "WFCUConferenceManager.h"
#import "WFCUConferenceMemberTableViewCell.h"
#import "WFCUConferenceInviteViewController.h"
#import "WFZConferenceInfo.h"
#import "WFCUPinyinUtility.h"
#import "WFCUProfileTableViewController.h"
#import "WFCUImage.h"


@interface WFCUConferenceMemberManagerViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray<WFCUConferenceMember *> *participants;

@property(nonatomic, strong)UIButton *muteAllBtn;
@property(nonatomic, strong)UIButton *unmuteAllBtn;

@property(nonatomic, strong)UIButton *alertViewCheckBtn;
@end

@implementation WFCUConferenceMemberManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, 40)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"搜索";
    self.searchBar.barStyle = UIBarStyleDefault;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.sectionIndexColor = [UIColor colorWithHexString:@"0x4e4e4e"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView registerClass:[WFCUConferenceMemberTableViewCell class] forCellReuseIdentifier:@"cell"];
    self.tableView.tableHeaderView = self.searchBar;
    
    [self.view addSubview:self.tableView];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(onClose:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"邀请" style:UIBarButtonItemStyleDone target:self action:@selector(onInvite:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConferenceMemberChanged:) name:@"kConferenceMemberChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConferenceEnded:) name:@"kConferenceEnded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConferenceMutedStateChanged:) name:@"kConferenceMutedStateChanged" object:nil];
    self.title = @"参会人员";
    
    [self loadData];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(!self.muteAllBtn && [[WFCUConferenceManager sharedInstance] isOwner]) {
        CGRect bounds = self.view.bounds;
        CGFloat buttonHeight = 48;
        CGFloat buttonWidth = bounds.size.width/2 - 16 - 8;
        
        self.muteAllBtn = [self createBtn:CGRectMake(16, bounds.size.height - [WFCUUtilities wf_safeDistanceBottom] - buttonHeight - 16, buttonWidth, buttonHeight) title:@"全员静音" action:@selector(onMuteAllBtnPressed:)];
        self.unmuteAllBtn = [self createBtn:CGRectMake(bounds.size.width - 16 - buttonWidth, bounds.size.height - [WFCUUtilities wf_safeDistanceBottom] - buttonHeight - 16, buttonWidth, buttonHeight) title:@"取消全员静音" action:@selector(onUnmuteAllBtnPressed:)];
    }
}

- (UIButton *)createBtn:(CGRect)frame title:(NSString *)title action:(SEL)action {
    UIButton *btn = [[UIButton alloc] initWithFrame:frame];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:14];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn.layer.borderWidth = 1;
    btn.layer.borderColor = [UIColor grayColor].CGColor;
    btn.layer.masksToBounds = YES;
    btn.layer.cornerRadius = 5.f;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:btn];
    
    return btn;
}

- (UIButton *)alertViewCheckBtn {
    if(!_alertViewCheckBtn) {
        CGFloat width = [[[NSUserDefaults standardUserDefaults] objectForKey:@"wfc_conference_alert_checkbox_width"] floatValue];
        CGFloat height = [[[NSUserDefaults standardUserDefaults] objectForKey:@"wfc_conference_alert_checkbox_height"] floatValue];
        _alertViewCheckBtn = [[UIButton alloc] initWithFrame:CGRectMake(8, 44, width, height)];
        [_alertViewCheckBtn setImage:[WFCUImage imageNamed:@"multi_unselected"] forState:UIControlStateNormal];
        [_alertViewCheckBtn setImage:[WFCUImage imageNamed:@"multi_selected"] forState:UIControlStateSelected];
        [_alertViewCheckBtn.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_alertViewCheckBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_alertViewCheckBtn addTarget:self action:@selector(onAlertViewCheckBtnPressed:) forControlEvents:UIControlEventTouchDown];
    }
    return _alertViewCheckBtn;
}

- (void)onAlertViewCheckBtnPressed:(id)sender {
    self.alertViewCheckBtn.selected = !self.alertViewCheckBtn.selected;
}

- (void)onMuteAllBtnPressed:(id)sender {
    __weak typeof(self)ws = self;
    [self presentMuteAllAlertView:@"所有成员将被静音" actionTitle:@"全体静音" checkText:@"允许成员自主解除静音" handler:^(UIAlertAction *action) {
        [[WFCUConferenceManager sharedInstance] requestMuteAll:ws.alertViewCheckBtn.selected];
    }];
}

- (void)onUnmuteAllBtnPressed:(id)sender {
    __weak typeof(self)ws = self;
    [self presentMuteAllAlertView:@"已允许全体成员开麦" actionTitle:@"取消全体静音" checkText:@"是否要求成员开麦" handler:^(UIAlertAction *action) {
        [[WFCUConferenceManager sharedInstance] requestUnmuteAll:ws.alertViewCheckBtn.selected];
    }];
}

- (void)presentMuteAllAlertView:(NSString *)message actionTitle:(NSString *)actionTitle checkText:(NSString *)checkText handler:(void (^)(UIAlertAction *action))handler {
    __weak typeof(self)ws = self;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"%@\n\n\n", message] preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    [alertController addAction:action1];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDestructive handler:handler];
    [alertController addAction:action2];
    
    [self.alertViewCheckBtn setTitle:[NSString stringWithFormat:@" %@", checkText] forState:UIControlStateNormal];
    [alertController.view addSubview:self.alertViewCheckBtn];
    
    [self presentViewController:alertController animated:NO completion:^{
        CGSize size = alertController.view.bounds.size;
        if(ws.alertViewCheckBtn.frame.size.width != size.width - 16 || ws.alertViewCheckBtn.frame.size.height != size.height - 88) {
            [[NSUserDefaults standardUserDefaults] setObject:@(size.width - 16) forKey:@"wfc_conference_alert_checkbox_width"];
            [[NSUserDefaults standardUserDefaults] setObject:@(size.height - 88) forKey:@"wfc_conference_alert_checkbox_height"];
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [[NSUserDefaults standardUserDefaults] synchronize];
            });
        }
        ws.alertViewCheckBtn.frame = CGRectMake(8, 44, size.width - 16, size.height - 88);
    }];
}

- (void)loadData {
    self.participants = [[NSMutableArray alloc] init];
    
    WFAVCallSession *callSession = [WFAVEngineKit sharedEngineKit].currentSession;
    NSArray<WFAVParticipantProfile *> *ps =  [WFAVEngineKit sharedEngineKit].currentSession.participants;
    
    NSMutableArray *audiences = [[NSMutableArray alloc] init];
    for (WFAVParticipantProfile *p in ps) {
        WFCUConferenceMember *member = [[WFCUConferenceMember alloc] init];
        member.userId = p.userId;
        member.isHost = [p.userId isEqualToString:[WFCUConferenceManager sharedInstance].currentConferenceInfo.owner];
        member.isVideoEnabled = !p.videoMuted;
        member.isAudioEnabled = !p.audioMuted;
        member.isMe = NO;
        member.isAudience = p.audience;
        member.isAudioOnly = callSession.audioOnly;
        
        if(self.searchBar.isFirstResponder && ![self isMatchSearchText:member.userId]) {
            continue;
        }
        
        if (p.audience) {
            [audiences addObject:member];
        } else {
            if(member.isHost) {
                [self.participants insertObject:member atIndex:0];
            } else {
                [self.participants addObject:member];
            }
        }
    }
    
    
    WFCUConferenceMember *member = [[WFCUConferenceMember alloc] init];
    member.userId = [WFCCNetworkService sharedInstance].userId;
    member.isHost = [member.userId isEqualToString:[WFCUConferenceManager sharedInstance].currentConferenceInfo.owner];
    member.isVideoEnabled = !callSession.isVideoMuted;
    member.isAudioEnabled = !callSession.isAudioMuted;
    member.isMe = YES;
    member.isAudience = callSession.isAudience;
    member.isAudioOnly = callSession.audioOnly;
    if(!self.searchBar.isFirstResponder || [self isMatchSearchText:member.userId]) {
        if(self.participants.count && self.participants[0].isHost) {
            [self.participants insertObject:member atIndex:1];
        } else {
            [self.participants insertObject:member atIndex:0];
        }
    }
    [self.participants addObjectsFromArray:audiences];
}

- (BOOL)isMatchSearchText:(NSString *)userId {
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
    NSString *searchString = self.searchBar.text;
    BOOL matched = NO;
    if([userInfo.displayName containsString:searchString] || [userInfo.friendAlias containsString:searchString]) {
        matched = YES;
    } else {
        WFCUPinyinUtility *pu = [[WFCUPinyinUtility alloc] init];
        if(![pu isChinese:searchString]) {
            if([pu isMatch:userInfo.displayName ofPinYin:searchString] || [pu isMatch:userInfo.friendAlias ofPinYin:searchString]) {
                matched = YES;
            }
        }
    }
    return matched;;
}

- (void)onResetKeyboard:(id)sender {
    [self.searchBar resignFirstResponder];
}

- (void)onConferenceMemberChanged:(id)sender {
    [self loadData];
    [self.tableView reloadData];
}

- (void)onConferenceEnded:(id)sender {
    [self onClose:nil];
}

- (void)onConferenceMutedStateChanged:(id)sender {
    [self loadData];
    [self.tableView reloadData];
}

- (void)onClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onInvite:(id)sender {
    WFCUConferenceInviteViewController *pvc = [[WFCUConferenceInviteViewController alloc] init];
    
    WFCCConferenceInviteMessageContent *invite = [[WFCCConferenceInviteMessageContent alloc] init];
    WFAVCallSession *currentSession = [WFAVEngineKit sharedEngineKit].currentSession;
    invite.callId = currentSession.callId;
    invite.pin = currentSession.pin;
    invite.audioOnly = currentSession.audioOnly;
    invite.host = currentSession.host;
    invite.title = currentSession.title;
    invite.desc = currentSession.desc;
    invite.audience = currentSession.defaultAudience;
    invite.advanced = currentSession.isAdvanced;
    invite.password = [WFCUConferenceManager sharedInstance].currentConferenceInfo.password;
    
    pvc.invite = invite;
    
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];

    [self presentViewController:navi animated:YES completion:nil];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    WFCUConferenceMemberTableViewCell *cell = (WFCUConferenceMemberTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.member = self.participants[indexPath.row];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.participants.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUConferenceMember *member;
    member = self.participants[indexPath.row];
    __weak typeof(self)ws = self;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"成员管理" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    UIAlertAction *showProfile = [UIAlertAction actionWithTitle:@"查看用户信息" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        WFCUProfileTableViewController *vc = [[WFCUProfileTableViewController alloc] init];
        vc.userId = member.userId;
        vc.hidesBottomBarWhenPushed = YES;
        [ws.navigationController pushViewController:vc animated:YES];
    }];
    
    UIAlertAction *requestPublish = [UIAlertAction actionWithTitle:@"邀请发言" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//        [[WFCUConferenceManager sharedInstance] request:member.userId changeModel:NO inConference:[WFAVEngineKit sharedEngineKit].currentSession.callId];
        [[WFCUConferenceManager sharedInstance] requestMember:member.userId Mute:NO];
    }];
    
    UIAlertAction *requestUnpublish = [UIAlertAction actionWithTitle:@"取消发言" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[WFCUConferenceManager sharedInstance] requestMember:member.userId Mute:YES];
    }];
    
    UIAlertAction *requestQuit = [UIAlertAction actionWithTitle:@"移除成员" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        WFAVCallSession *currentSession = [WFAVEngineKit sharedEngineKit].currentSession;
        [currentSession kickoffParticipant:member.userId success:^{
            NSLog(@"kickoff success");
        } error:^(int error_code) {
            NSLog(@"kickoff error");
        }];
    }];
    
    UIAlertAction *enableAudio = [UIAlertAction actionWithTitle:@"开启音频" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[WFCUConferenceManager sharedInstance] muteAudio:member.isAudioEnabled];
    }];
    UIAlertAction *enableVideo = [UIAlertAction actionWithTitle:@"开启视频" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[WFCUConferenceManager sharedInstance] muteVideo:member.isVideoEnabled];
    }];
    UIAlertAction *enableAudioVideo = [UIAlertAction actionWithTitle:@"开启音视频" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[WFCUConferenceManager sharedInstance] muteAudioVideo:member.isVideoEnabled];
    }];
    
    UIAlertAction *muteAudio = [UIAlertAction actionWithTitle:@"关闭音频" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[WFCUConferenceManager sharedInstance] muteAudio:member.isAudioEnabled];
    }];
    
    UIAlertAction *muteVideo = [UIAlertAction actionWithTitle:@"关闭视频" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[WFCUConferenceManager sharedInstance] muteVideo:member.isVideoEnabled];
    }];
    
    UIAlertAction *muteAudioVideo = [UIAlertAction actionWithTitle:@"关闭音视频" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[WFCUConferenceManager sharedInstance] muteAudioVideo:member.isVideoEnabled];
    }];
    
    [alertController addAction:actionCancel];
    [alertController addAction:showProfile];
    
    if([[WFCUConferenceManager sharedInstance].currentConferenceInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId] && !member.isMe) {
        if(!member.isAudience) {
            [alertController addAction:requestUnpublish];
        } else {
            [alertController addAction:requestPublish];
        }
        [alertController addAction:requestQuit];
    } else if(member.isMe) {
        if(member.isAudience) {
            if([[WFCUConferenceManager sharedInstance].currentConferenceInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId] || [WFCUConferenceManager sharedInstance].currentConferenceInfo.allowSwitchMode) {
                [alertController addAction:enableAudio];
                [alertController addAction:enableVideo];
                [alertController addAction:enableAudioVideo];
            } else {
                //Todo 举手请求发言
            }
        } else {
            if(member.isAudioEnabled) {
                [alertController addAction:muteAudio];
            } else {
                [alertController addAction:enableAudio];
            }
            
            if(member.isVideoEnabled) {
                [alertController addAction:muteVideo];
            } else {
                [alertController addAction:enableVideo];
            }
            
            if(member.isAudioEnabled && member.isVideoEnabled) {
                [alertController addAction:muteAudioVideo];
            } else if(!member.isAudioEnabled && !member.isVideoEnabled) {
                [alertController addAction:enableAudioVideo];
            }
        }
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}
#pragma mark - UISearchBarDelegate
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self loadData];
    [self.tableView reloadData];
    self.searchBar.showsCancelButton = YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [self loadData];
    [self.tableView reloadData];
    self.searchBar.showsCancelButton = NO;
    self.searchBar.text = nil;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self loadData];
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
}
@end
#endif
