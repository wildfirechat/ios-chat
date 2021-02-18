//
//  WFCUPushToTalkMemberListViewController.m
//  WFChatUIKit
//
//  Created by dali on 2021/2/18.
//  Copyright © 2021 Tom Lee. All rights reserved.
//

#import "WFCUPushToTalkMemberListViewController.h"
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUConferenceInviteViewController.h"

@interface WFCUPushToTalkMemberListViewController ()

@end

@implementation WFCUPushToTalkMemberListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(onClose:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"邀请" style:UIBarButtonItemStyleDone target:self action:@selector(onInvite:)];
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

@end
