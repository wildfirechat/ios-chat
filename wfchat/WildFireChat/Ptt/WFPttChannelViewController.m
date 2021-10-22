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

@interface WFPttChannelViewController ()
@property(nonatomic, strong)UIButton *startButton;
@property(nonatomic, strong)UIButton *joinButton;
@end

@implementation WFPttChannelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
#define BTN_HEIGHT 48
    self.startButton = [[UIButton alloc] initWithFrame:CGRectZero];
    self.startButton.layer.masksToBounds = YES;
    [self.startButton addTarget:self action:@selector(onStart:) forControlEvents:UIControlEventTouchDown];
    [self.startButton addTarget:self action:@selector(onEnd:) forControlEvents:UIControlEventTouchUpInside];
    [self.startButton addTarget:self action:@selector(onEnd:) forControlEvents:UIControlEventTouchUpOutside];
    
    
    self.joinButton = [[UIButton alloc] initWithFrame:CGRectMake(16, self.view.bounds.size.height - kTabbarSafeBottomMargin - BTN_HEIGHT - 16, self.view.bounds.size.width - 16 - 16, BTN_HEIGHT)];
    [self.joinButton setTitle:@"加入对讲" forState:UIControlStateNormal];
    [self.joinButton setTitle:@"加入讲中..." forState:UIControlStateDisabled];
    self.joinButton.backgroundColor = [UIColor blueColor];
    self.joinButton.layer.cornerRadius = 10.f;
    self.joinButton.layer.masksToBounds = YES;
    [self.joinButton addTarget:self action:@selector(onJoin:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.startButton];
    [self.view addSubview:self.joinButton];
    
    [self updateStartBtnStatus];
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Invite" style:UIBarButtonItemStylePlain target:self action:@selector(invite:)];
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kWFPttTalkingBeginNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [ws updateStartBtnStatus];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:kWFPttTalkingEndNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [ws updateStartBtnStatus];
    }];
}

- (void)updateStartBtnStatus {
    if([[[WFPttClient sharedClient] getSubscribedChannels] containsObject:self.channelId]) {
        self.joinButton.hidden = YES;
        self.startButton.hidden = NO;
        
        CGFloat btnSize = 100;
        NSString *title = @"按下讲话";
        UIColor *color = [UIColor redColor];
        if([[[WFPttClient sharedClient] getTalkingChanelId] isEqualToString:self.channelId]) {
            btnSize = 150;
            title = @"松开结束讲话";
            color = [UIColor greenColor];
        }
        
        CGRect bound = self.view.bounds;
        self.startButton.frame = CGRectMake((bound.size.width - btnSize)/2, self.view.bounds.size.height - kTabbarSafeBottomMargin - btnSize/2 - 160, btnSize, btnSize);
        [self.startButton setTitle:title forState:UIControlStateNormal];
        self.startButton.backgroundColor = color;
        self.startButton.layer.cornerRadius = btnSize/2;
    } else {
        self.joinButton.hidden = NO;
        self.startButton.hidden = YES;
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
    __weak typeof(self)ws = self;
    [[WFPttClient sharedClient] requestTalk:self.channelId startTalking:^(NSString *channelId) {
        NSLog(@"talking now...");
        [ws playPttRing:@"ptt_begin"];
        [ws updateStartBtnStatus];
    } requestFailure:^(int errorCode) {
        NSLog(@"request talking failure");
        [ws updateStartBtnStatus];
    } talkingEnd:^(PttEndReason reason) {
        NSLog(@"talking ended");
        [ws playPttRing:@"ptt_end"];
        [ws updateStartBtnStatus];
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

- (void)playPttRing:(NSString *)ring {
    if([[UIApplication sharedApplication].delegate respondsToSelector:@selector(playPttRing:)]) {
        [[UIApplication sharedApplication].delegate performSelector:@selector(playPttRing:) withObject:ring];
    }
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
#endif //WFC_PTT
