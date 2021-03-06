//
//  WFCUPushToTalkMemberListViewController.m
//  WFChatUIKit
//
//  Created by dali on 2021/2/18.
//  Copyright © 2021 Wildfire Chat. All rights reserved.
//

#import "WFCUPushToTalkMemberListViewController.h"
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUConferenceInviteViewController.h"
#import "WFCUConferenceMember.h"
#import "WFCUConferenceMemberTableViewCell.h"

@interface WFCUPushToTalkMemberListViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<WFCUConferenceMember *> *participants;
@end

@implementation WFCUPushToTalkMemberListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(onClose:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"邀请" style:UIBarButtonItemStyleDone target:self action:@selector(onInvite:)];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView registerClass:[WFCUConferenceMemberTableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];
    
    [self loadData];
    [self.tableView reloadData];
}

- (void)loadData {
    self.participants = [[NSMutableArray alloc] init];
    
    NSArray<WFAVParticipantProfile *> *ps =  [WFAVEngineKit sharedEngineKit].currentSession.participants;
    for (WFAVParticipantProfile *p in ps) {
        WFCUConferenceMember *member = [[WFCUConferenceMember alloc] init];
        member.userId = p.userId;
        member.isHost = [p.userId isEqualToString:[WFAVEngineKit sharedEngineKit].currentSession.host];
        member.isVideoEnabled = !p.videoMuted;
        member.isMe = NO;
        
        if(member.isHost) {
            [self.participants insertObject:member atIndex:0];
        } else {
            [self.participants addObject:member];
        }
    }
    
    
    WFCUConferenceMember *member = [[WFCUConferenceMember alloc] init];
    member.userId = [WFCCNetworkService sharedInstance].userId;
    member.isHost = [member.userId isEqualToString:[WFAVEngineKit sharedEngineKit].currentSession.host];
    member.isVideoEnabled = ![WFAVEngineKit sharedEngineKit].currentSession.isVideoMuted;
    member.isMe = YES;
    
    if(self.participants.count && self.participants[0].isHost) {
        [self.participants insertObject:member atIndex:1];
    } else {
        [self.participants insertObject:member atIndex:0];
    }
}

- (void)onClose:(id)sender {
    [[WFAVEngineKit sharedEngineKit] dismissViewController:self];
}

- (void)onInvite:(id)sender {
    WFCUConferenceInviteViewController *pvc = [[WFCUConferenceInviteViewController alloc] init];
    
    WFCCPTTInviteMessageContent *invite = [[WFCCPTTInviteMessageContent alloc] init];
    WFAVCallSession *currentSession = [WFAVEngineKit sharedEngineKit].currentSession;
    invite.callId = currentSession.callId;
    invite.pin = currentSession.pin;
    invite.host = currentSession.host;
    invite.title = currentSession.title;
    invite.desc = currentSession.desc;
    
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
@end
