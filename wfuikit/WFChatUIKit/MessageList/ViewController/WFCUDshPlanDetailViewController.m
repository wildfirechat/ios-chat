//
//  WFCUDshPlanDetailViewController.m
//  WFChatUIKit
//
//  DSH plan-review 全屏计划详情页。底部 批准/拒绝 按钮发送 DSH_ANSWER 后返回。
//

#import "WFCUDshPlanDetailViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatClient/WFCCDshMessageContents.h>
#import "WFCUDshState.h"
#import "WFCUUtilities.h"
#import "WFCUConfigManager.h"
#import "UIFont+YH.h"

@interface WFCUAgentPlanDetailViewController ()
@property (nonatomic, strong)WFCCConversation *conversation;
@property (nonatomic, strong)NSString *qid;
@property (nonatomic, strong)NSString *questionId;
@property (nonatomic, strong)NSString *plan;
@property (nonatomic, strong)NSString *approveLabel;
@property (nonatomic, strong)NSString *rejectLabel;

@property (nonatomic, strong)UITextView *planTextView;
@property (nonatomic, strong)UIView *bottomBar;
@property (nonatomic, strong)UIButton *approveButton;
@property (nonatomic, strong)UIButton *rejectButton;
@end

@implementation WFCUAgentPlanDetailViewController

- (instancetype)initWithConversation:(WFCCConversation *)conversation
                                 qid:(NSString *)qid
                          questionId:(NSString *)questionId
                                plan:(NSString *)plan
                        approveLabel:(NSString *)approveLabel
                         rejectLabel:(NSString *)rejectLabel {
    self = [super init];
    if (self) {
        self.conversation = conversation;
        self.qid = qid;
        self.questionId = questionId;
        self.plan = plan;
        self.approveLabel = approveLabel;
        self.rejectLabel = rejectLabel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"计划详情";
    self.view.backgroundColor = [UIColor whiteColor];

    CGFloat bottomBarHeight = 56 + [WFCUUtilities wf_safeDistanceBottom];

    self.planTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - bottomBarHeight)];
    self.planTextView.font = [UIFont monospacedSystemFontOfSize:[WFCUConfigManager scaledSize:13] weight:UIFontWeightRegular];
    self.planTextView.textColor = [UIColor blackColor];
    self.planTextView.editable = NO;
    self.planTextView.alwaysBounceVertical = YES;
    self.planTextView.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12);
    self.planTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.planTextView.text = self.plan;
    [self.view addSubview:self.planTextView];

    self.bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - bottomBarHeight, self.view.bounds.size.width, bottomBarHeight)];
    self.bottomBar.backgroundColor = [UIColor whiteColor];
    self.bottomBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bottomBar.bounds.size.width, 0.5)];
    topLine.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
    topLine.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.bottomBar addSubview:topLine];
    [self.view addSubview:self.bottomBar];

    CGFloat padding = 16;
    CGFloat btnWidth = (self.view.bounds.size.width - padding * 3) / 2.0;
    CGFloat btnHeight = 40;
    CGFloat btnY = 8;

    self.approveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.approveButton setTitle:self.approveLabel forState:UIControlStateNormal];
    [self.approveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.approveButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15];
    self.approveButton.backgroundColor = [WFCUAgentState accentColor];
    self.approveButton.layer.cornerRadius = 6;
    self.approveButton.frame = CGRectMake(padding, btnY, btnWidth, btnHeight);
    [self.approveButton addTarget:self action:@selector(onApprove) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.approveButton];

    self.rejectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rejectButton setTitle:self.rejectLabel forState:UIControlStateNormal];
    [self.rejectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.rejectButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15];
    self.rejectButton.backgroundColor = [UIColor redColor];
    self.rejectButton.layer.cornerRadius = 6;
    self.rejectButton.frame = CGRectMake(padding * 2 + btnWidth, btnY, btnWidth, btnHeight);
    [self.rejectButton addTarget:self action:@selector(onReject) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.rejectButton];
}

- (void)decide:(NSString *)label {
    WFCCAgentAnswerMessageContent *answer = [[WFCCAgentAnswerMessageContent alloc] init];
    answer.qid = self.qid;
    answer.answers = @[@{@"id": self.questionId, @"selected": @[label]}];
    [[WFCCIMService sharedWFCIMService] send:self.conversation content:answer success:nil error:nil];

    //通知提问卡片立即本地置灰（不依赖服务端推送实时性）
    [[NSNotificationCenter defaultCenter] postNotificationName:WFCUDshAnsweredNotification object:nil userInfo:@{@"qid": self.qid ?: @""}];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onApprove {
    [self decide:self.approveLabel];
}

- (void)onReject {
    [self decide:self.rejectLabel];
}

@end
