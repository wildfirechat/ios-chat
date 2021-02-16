//
//  WFCUConferenceMemberManagerViewController.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2021/2/15.
//  Copyright © 2021 Tom Lee. All rights reserved.
//

#import "WFCUConferenceMemberManagerViewController.h"
#import "UIColor+YH.h"
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUConfigManager.h"
#import "WFCUConferenceMember.h"
#import "WFCUConferenceManager.h"
#import "WFCUConferenceMemberTableViewCell.h"
#import "WFCUConferenceInviteViewController.h"


@interface WFCUConferenceMemberManagerViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray<WFCUConferenceMember *> *participants;
@property (nonatomic, strong) NSMutableArray<WFCUConferenceMember *> *audiences;
@end

@implementation WFCUConferenceMemberManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 90)];
    UIView *barView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];
    barView.layer.cornerRadius = 10;
    barView.layer.masksToBounds = YES;
    barView.backgroundColor = [WFCUConfigManager globalManager].naviBackgroudColor;
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(8, 18, 40, 24)];
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(onClose:) forControlEvents:UIControlEventTouchUpInside];
    UIButton *inviteBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-8-40, 18, 40, 24)];
    [inviteBtn setTitle:@"邀请" forState:UIControlStateNormal];
    [inviteBtn addTarget:self action:@selector(onInvite:) forControlEvents:UIControlEventTouchUpInside];
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, 40)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"搜索";
    self.searchBar.barStyle = UIBarStyleDefault;
    [barView addSubview:closeBtn];
    [barView addSubview:inviteBtn];
    [topView addSubview:barView];
    [topView addSubview:self.searchBar];
    [self.view addSubview:topView];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topView.frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height - topView.frame.size.height) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.sectionIndexColor = [UIColor colorWithHexString:@"0x4e4e4e"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView registerClass:[WFCUConferenceMemberTableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(onClose:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConferenceMemberChanged:) name:@"kConferenceMemberChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConferenceEnded:) name:@"kConferenceEnded" object:nil];
    
    [self loadData];
    [self.tableView reloadData];
}

- (void)loadData {
    self.participants = [[NSMutableArray alloc] init];
    self.audiences = [[NSMutableArray alloc] init];
    
    NSArray<WFAVParticipantProfile *> *ps =  [WFAVEngineKit sharedEngineKit].currentSession.participants;
    for (WFAVParticipantProfile *p in ps) {
        WFCUConferenceMember *member = [[WFCUConferenceMember alloc] init];
        member.userId = p.userId;
        member.isHost = [p.userId isEqualToString:[WFAVEngineKit sharedEngineKit].currentSession.host];
        member.isVideoEnabled = !p.videoMuted;
        member.isMe = NO;
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
    member.isHost = [member.userId isEqualToString:[WFAVEngineKit sharedEngineKit].currentSession.host];
    member.isVideoEnabled = ![WFAVEngineKit sharedEngineKit].currentSession.isVideoMuted;
    member.isMe = YES;
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
- (void)onConferenceMemberChanged:(id)sender {
    [self loadData];
    [self.tableView reloadData];
}

- (void)onConferenceEnded:(id)sender {
    [self onClose:nil];
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
    
    pvc.invite = invite;
    
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
    navi.modalPresentationStyle = UIModalPresentationFullScreen;

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
        return @"参会者";
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
    
    if(member.isHost) {
        return;
    }
    
    if([[WFAVEngineKit sharedEngineKit].currentSession.host isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"成员互动管理" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:actionCancel];
        
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"邀请参与互动" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[WFCUConferenceManager sharedInstance] request:member.userId changeModel:NO inConference:[WFAVEngineKit sharedEngineKit].currentSession.callId];
        }];
        
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消互动" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[WFCUConferenceManager sharedInstance] request:member.userId changeModel:YES inConference:[WFAVEngineKit sharedEngineKit].currentSession.callId];
        }];
        
        if(indexPath.section == 0) {
            [alertController addAction:action2];
        } else {
            [alertController addAction:action1];
        }
        
        UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"移除成员" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [[WFCUConferenceManager sharedInstance] kickoff:member.userId inConference:[WFAVEngineKit sharedEngineKit].currentSession.callId];
        }];
        [alertController addAction:action3];
        
        [self presentViewController:alertController animated:YES completion:nil];
    } else if(member.isMe) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"成员互动管理" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:actionCancel];
        
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"参与互动" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[WFCUConferenceManager sharedInstance] requestChangeModel:NO inConference:[WFAVEngineKit sharedEngineKit].currentSession.callId];
        }];
        
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"退出互动" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[WFCUConferenceManager sharedInstance] requestChangeModel:YES inConference:[WFAVEngineKit sharedEngineKit].currentSession.callId];
        }];
        
        if(indexPath.section == 0) {
            [alertController addAction:action2];
        } else {
            [alertController addAction:action1];
        }
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(performDelete:) || action == @selector(performInvite:) || action == @selector(performCancel:)) {
        return YES; //显示自定义的菜单项
    } else {
        return NO;
    }
}

- (void)performDelete:(id)sender {
    
}
- (void)performInvite:(id)sender {
    
}
- (void)performCancel:(id)sender {
    
}
@end
