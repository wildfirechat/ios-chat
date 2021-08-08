//
//  WFCUConferenceMemberManagerViewController.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2021/2/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUConferenceMemberManagerViewController.h"
#import "UIColor+YH.h"
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUConfigManager.h"
#import "WFCUConferenceMember.h"
#import "WFCUConferenceManager.h"
#import "WFCUConferenceMemberTableViewCell.h"
#import "WFCUConferenceInviteViewController.h"
#import "WFCUPinyinUtility.h"
#import "WFCUProfileTableViewController.h"


@interface WFCUConferenceMemberManagerViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray<WFCUConferenceMember *> *participants;
@property (nonatomic, strong) NSMutableArray<WFCUConferenceMember *> *audiences;
@end

@implementation WFCUConferenceMemberManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, 40)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"搜索";
    self.searchBar.barStyle = UIBarStyleDefault;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
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

- (void)loadData {
    self.participants = [[NSMutableArray alloc] init];
    self.audiences = [[NSMutableArray alloc] init];
    
    WFAVCallSession *callSession = [WFAVEngineKit sharedEngineKit].currentSession;
    NSArray<WFAVParticipantProfile *> *ps =  [WFAVEngineKit sharedEngineKit].currentSession.participants;
    for (WFAVParticipantProfile *p in ps) {
        WFCUConferenceMember *member = [[WFCUConferenceMember alloc] init];
        member.userId = p.userId;
        member.isHost = [p.userId isEqualToString:[WFAVEngineKit sharedEngineKit].currentSession.host];
        member.isVideoEnabled = !p.videoMuted;
        member.isAudioEnabled = !p.audioMuted;
        member.isMe = NO;
        member.isAudience = p.audience;
        member.isAudioOnly = callSession.audioOnly;
        
        if(self.searchBar.isFirstResponder && ![self isMatchSearchText:member.userId]) {
            continue;
        }
        
        if (p.audience) {
            [self.audiences addObject:member];
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
    member.isHost = [member.userId isEqualToString:callSession.host];
    member.isVideoEnabled = !callSession.isVideoMuted;
    member.isAudioEnabled = !callSession.isAudioMuted;
    member.isMe = YES;
    member.isAudience = callSession.isAudience;
    member.isAudioOnly = callSession.audioOnly;
    if(!self.searchBar.isFirstResponder || [self isMatchSearchText:member.userId]) {
        if([WFAVEngineKit sharedEngineKit].currentSession.audience) {
            [self.audiences insertObject:member atIndex:0];
        } else {
            if(self.participants.count && self.participants[0].isHost) {
                [self.participants insertObject:member atIndex:1];
            } else {
                [self.participants insertObject:member atIndex:0];
            }
        }
    }
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
    
    pvc.invite = invite;
    
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];

    [self presentViewController:navi animated:YES completion:nil];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    WFCUConferenceMemberTableViewCell *cell = (WFCUConferenceMemberTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(indexPath.section == 0) {
        cell.member = self.participants[indexPath.row];
    } else {
        cell.member = self.audiences[indexPath.row];
    }

    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"互动成员";
    } else {
        return @"听众";
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(self.audiences.count) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return self.participants.count;
    } else {
        return self.audiences.count;
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUConferenceMember *member;
    if(indexPath.section == 0) {
        member = self.participants[indexPath.row];
    } else {
        member = self.audiences[indexPath.row];
    }
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
    
    UIAlertAction *requestPublish = [UIAlertAction actionWithTitle:@"邀请参与互动" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[WFCUConferenceManager sharedInstance] request:member.userId changeModel:NO inConference:[WFAVEngineKit sharedEngineKit].currentSession.callId];
    }];
    
    UIAlertAction *requestUnpublish = [UIAlertAction actionWithTitle:@"取消互动" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[WFCUConferenceManager sharedInstance] request:member.userId changeModel:YES inConference:[WFAVEngineKit sharedEngineKit].currentSession.callId];
    }];
    
    UIAlertAction *requestQuit = [UIAlertAction actionWithTitle:@"移除成员" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        WFAVCallSession *currentSession = [WFAVEngineKit sharedEngineKit].currentSession;
        [currentSession kickoffParticipant:member.userId success:^{
            NSLog(@"kickoff success");
        } error:^(int error_code) {
            NSLog(@"kickoff error");
        }];
    }];
    
    UIAlertAction *publish = [UIAlertAction actionWithTitle:@"参与互动" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[WFCUConferenceManager sharedInstance] requestChangeModel:NO inConference:[WFAVEngineKit sharedEngineKit].currentSession.callId];
    }];
    
    UIAlertAction *unpublish = [UIAlertAction actionWithTitle:@"退出互动" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[WFCUConferenceManager sharedInstance] requestChangeModel:YES inConference:[WFAVEngineKit sharedEngineKit].currentSession.callId];
    }];
    
    [alertController addAction:actionCancel];
    [alertController addAction:showProfile];
    
    if([[WFAVEngineKit sharedEngineKit].currentSession.host isEqualToString:[WFCCNetworkService sharedInstance].userId] && !member.isMe) {
        if(indexPath.section == 0) {
            [alertController addAction:requestUnpublish];
        } else {
            [alertController addAction:requestPublish];
        }
        [alertController addAction:requestQuit];
    } else if(member.isMe) {
        if(indexPath.section == 0) {
            [alertController addAction:unpublish];
        } else {
            [alertController addAction:publish];
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
