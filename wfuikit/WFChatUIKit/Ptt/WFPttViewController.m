//
//  WFPttViewController.m
//  PttUIKit
//
//  Created by Hao Jia on 2021/10/14.
//

#ifdef WFC_PTT
#import "WFPttViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <PttClient/WFPttClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "WFCUUtilities.h"

@interface WFPttViewController ()
@property(nonatomic, strong)UIButton *startButton;
@end

@implementation WFPttViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
#define BTN_HEIGHT 48
    self.startButton = [[UIButton alloc] initWithFrame:CGRectZero];
    self.startButton.layer.masksToBounds = YES;
    [self.startButton addTarget:self action:@selector(onStart:) forControlEvents:UIControlEventTouchDown];
    [self.startButton addTarget:self action:@selector(onEnd:) forControlEvents:UIControlEventTouchUpInside];
    [self.startButton addTarget:self action:@selector(onEnd:) forControlEvents:UIControlEventTouchUpOutside];
    
    [self.view addSubview:self.startButton];
    
    [self updateStartBtnStatus];
    
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(onClose:)];
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kWFPttTalkingBeginNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [ws updateStartBtnStatus];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:kWFPttTalkingEndNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [ws updateStartBtnStatus];
    }];
}

- (void)updateStartBtnStatus {
        self.startButton.hidden = NO;
        
        CGFloat btnSize = 100;
        NSString *title = @"按下讲话";
        UIColor *color = [UIColor redColor];
        if([[WFPttClient sharedClient] getTalkingConversation] == self.conversation) {
            btnSize = 150;
            title = @"松开结束讲话";
            color = [UIColor greenColor];
        }
        
        CGRect bound = self.view.bounds;
        self.startButton.frame = CGRectMake((bound.size.width - btnSize)/2, self.view.bounds.size.height - [WFCUUtilities wf_safeDistanceBottom] - btnSize/2 - 160, btnSize, btnSize);
        [self.startButton setTitle:title forState:UIControlStateNormal];
        self.startButton.backgroundColor = color;
        self.startButton.layer.cornerRadius = btnSize/2;
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

- (void)onClose:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)onStart:(id)sender {
    __weak typeof(self)ws = self;
    [[WFPttClient sharedClient] requestTalk:self.conversation startTalking:^(void) {
        NSLog(@"talking now...");
        [ws playPttRing:@"ptt_begin"];
        [ws updateStartBtnStatus];
    } onAmplitude:^(int averageAmp){
        NSLog(@"on amp %d", averageAmp);
    } requestFailure:^(int errorCode) {
        NSLog(@"request talking failure");
        [ws updateStartBtnStatus];
    } talkingEnd:^(PttEndReason reason) {
        NSLog(@"talking ended");
        [ws playPttRing:@"ptt_end"];
        [ws updateStartBtnStatus];
    }];
}

- (void)onEnd:(id)sender {
    self.startButton.backgroundColor = [UIColor blueColor];
    [[WFPttClient sharedClient] releaseTalking:self.conversation];
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
