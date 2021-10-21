//
//  WFPttChannelViewController.m
//  PttUIKit
//
//  Created by Hao Jia on 2021/10/14.
//

#ifdef WFC_PTT
#import "WFPttChannelViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <PttClient/WFPttClient.h>
#import <WFChatUIKit/WFChatUIKit.h>

@interface WFPttChannelViewController () <WFPttDelegate>
@property(nonatomic, strong)UIButton *startButton;
@end

@implementation WFPttChannelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
#define BTN_HEIGHT 48
    self.startButton = [[UIButton alloc] initWithFrame:CGRectMake(16, self.view.bounds.size.height - kTabbarSafeBottomMargin - BTN_HEIGHT - 16, self.view.bounds.size.width - 16 - 16, BTN_HEIGHT)];
    
    [self updateStartBtnStatus];
    
    self.startButton.backgroundColor = [UIColor blueColor];
    self.startButton.layer.cornerRadius = 10.f;
    self.startButton.layer.masksToBounds = YES;
    
    [self.view addSubview:self.startButton];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Invite" style:UIBarButtonItemStylePlain target:self action:@selector(invite:)];
}

- (void)updateStartBtnStatus {
    if([[[WFPttClient sharedClient] getSubscribedChannels] containsObject:self.channelId]) {
        self.startButton.enabled = YES;
        [self.startButton setTitle:@"按下开始讲话" forState:UIControlStateNormal];
        
        [self.startButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        
        [self.startButton addTarget:self action:@selector(onStart:) forControlEvents:UIControlEventTouchDown];
        [self.startButton addTarget:self action:@selector(onEnd:) forControlEvents:UIControlEventTouchUpInside];
        [self.startButton addTarget:self action:@selector(onEnd:) forControlEvents:UIControlEventTouchUpOutside];
    } else {
        [self.startButton setTitle:@"加入对讲" forState:UIControlStateNormal];
        [self.startButton setTitle:@"加入讲中..." forState:UIControlStateDisabled];
        
        [self.startButton removeTarget:self action:nil forControlEvents:UIControlEventTouchDown];
        [self.startButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        [self.startButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpOutside];
        
        [self.startButton addTarget:self action:@selector(onJoin:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)dismiss:(id)sender {
    if (self.navigationController.presentingViewController) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [WFPttClient sharedClient].delegate = self;
    [self updateMemberStatus];
}

- (void)updateMemberStatus {
    
}

- (void)invite:(id)sender {
    WFPttChannelInfo *info = [[WFPttClient sharedClient] getChannelInfo:self.channelId];
    
    WFCCPTTInviteMessageContent *invite = [[WFCCPTTInviteMessageContent alloc] init];
    invite.callId = info.channelId;
    invite.title = info.name;
    invite.host = info.owner;
    invite.desc = info.portrait;
    
    WFCCMessage *message = [[WFCCMessage alloc] init];
    message.content = invite;
    
    WFCUForwardViewController *controller = [[WFCUForwardViewController alloc] init];
    controller.message = message;
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:controller];
    [self.navigationController presentViewController:navi animated:YES completion:nil];
    
}

- (void)onStart:(id)sender {
    [self.startButton setTitle:@"松开结束讲话" forState:UIControlStateNormal];
    self.startButton.backgroundColor = [UIColor redColor];
    [[WFPttClient sharedClient] requestTalk:self.channelId startTalking:^(NSString *channelId) {
        NSLog(@"talking now...");
    } requestFailure:^(int errorCode) {
        NSLog(@"request talking failure");
    } talkingEnd:^(PttEndReason reason) {
        NSLog(@"talking ended");
    }];
}

- (void)onJoin:(id)sender {
    self.startButton.enabled = NO;
    __weak typeof(self)ws = self;
    [[WFPttClient sharedClient] joinChannel:self.channelId success:^{
        NSLog(@"join success");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [ws updateStartBtnStatus];
        });
    } error:^(int errorCode) {
        NSLog(@"join error");
    }];
}

- (void)onEnd:(id)sender {
    self.startButton.backgroundColor = [UIColor blueColor];
    [[WFPttClient sharedClient] releaseTalking:self.channelId];
}

#pragma mark - WFPttDelegate
- (void)didChannel:(NSString *)channelId startTalkingUser:(NSString *)userId {
    if ([self.channelId isEqualToString:channelId]) {
        [self updateMemberStatus];
    }
}

- (void)didChannel:(NSString *)channelId endTalkingUser:(NSString *)userId {
    if ([self.channelId isEqualToString:channelId]) {
        [self updateMemberStatus];
    }
}

- (void)didSubscriberChanged:(NSString *)channelId {
    
}

//接收到用户自定义数据
- (void)didChannel:(NSString *)channelId receiveData:(NSString *)data from:(NSString *)userId {
    
}
@end
#endif //WFC_PTT
