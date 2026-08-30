//
//  WFCDiagnoseViewController.m
//  WildFireChat
//
//  Created by Heavyrain Lee on 2019/11/11.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "WFCDiagnoseViewController.h"
#import "AFNetworking.h"
#import "WFCConfig.h"
#import "AppService.h"
#import <WFChatUIKit/WFChatUIKit.h>

@interface WFCDiagnoseViewController ()
@property (nonatomic, strong)UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong)UILabel *resultLabel;
@property (nonatomic, strong)UIButton *startButton;
@property (nonatomic, strong)UIButton *uploadLogsButton;
@end

@implementation WFCDiagnoseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = LocalizedString(@"Diagnose");
    
    if (@available(iOS 13.0, *)) {
        self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        
    } else {
        self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
    }
    self.indicatorView.color = [UIColor grayColor];
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.indicatorView.hidden = YES;
    [self.view addSubview:self.indicatorView];
    
    self.resultLabel = [[UILabel alloc] init];
    self.resultLabel.textAlignment = NSTextAlignmentCenter;
    self.resultLabel.text = LocalizedString(@"DiagnoseHint");
    self.resultLabel.numberOfLines = 0;
    [self.view addSubview:self.resultLabel];
    
    self.startButton = [[UIButton alloc] init];
    [self.startButton  setTitle:LocalizedString(@"TestNetwork") forState:UIControlStateNormal];
    [self.startButton setTitleColor:[WFCUConfigManager globalManager].naviTextColor forState:UIControlStateNormal];
    [self.startButton setBackgroundColor:[UIColor greenColor]];
    self.startButton.layer.masksToBounds = YES;
    self.startButton.layer.cornerRadius = 5.0;
    [self.startButton addTarget:self action:@selector(onStart:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.startButton];
    
    self.uploadLogsButton = [[UIButton alloc] init];
    [self.uploadLogsButton  setTitle:LocalizedString(@"UploadLogs") forState:UIControlStateNormal];
    [self.uploadLogsButton setTitleColor:[WFCUConfigManager globalManager].naviTextColor forState:UIControlStateNormal];
    [self.uploadLogsButton setBackgroundColor:[UIColor redColor]];
    self.uploadLogsButton.layer.masksToBounds = YES;
    self.uploadLogsButton.layer.cornerRadius = 5.0;
    [self.uploadLogsButton addTarget:self action:@selector(onUploadLogs:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.uploadLogsButton];
    
    [self layoutViews];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    //iPad 右栏里 viewDidLoad 那一刻的 bounds 可能是整屏宽（转场首帧按整屏排），
    //控件会偏到左栏那边；每次布局按当前 bounds 重排。iPhone 上 bounds 恒等于屏幕宽，取值不变。
    [self layoutViews];
}

- (void)layoutViews {
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    if (width <= 0 || height <= 0) {
        return;
    }
    self.indicatorView.center = CGPointMake(width/2, height/4 - 10);
    self.resultLabel.frame = CGRectMake(width/2 - 150, height/4 - 40, 300, 60);
    self.startButton.frame = CGRectMake(width/2 - 80, height/2 - 20, 160, 40);
    self.uploadLogsButton.frame = CGRectMake(width/2 - 80, height/2 + 40, 160, 40);
}

- (void)onStart:(id)sender {
    self.resultLabel.hidden = YES;
    self.indicatorView.hidden = NO;
    [self.indicatorView startAnimating];
    self.startButton.enabled = NO;
    self.uploadLogsButton.enabled = NO;
    
    NSDate *now = [[NSDate alloc] init];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    __weak typeof(self)ws =self;
    [manager GET:[NSString stringWithFormat:@"http://%@%@", IM_SERVER_HOST, @"/api/version"] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                double value = now.timeIntervalSinceNow;
                int duration = (int)((-value)*1000 + 0.5);
                [ws reportResult:[NSString stringWithFormat:LocalizedString(@"SpeedTestSuccess"), duration]];
            } else {
                [ws reportResult:[NSString stringWithFormat:LocalizedString(@"SpeedTestFailedUnrecognized"), responseObject]];
            }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [ws reportResult:[NSString stringWithFormat:LocalizedString(@"SpeedTestFailed"), error.localizedDescription]];
    }];
    
}

- (void)onUploadLogs:(id)sender {
    self.resultLabel.hidden = YES;
    self.indicatorView.hidden = NO;
    [self.indicatorView startAnimating];
    self.startButton.enabled = NO;
    self.uploadLogsButton.enabled = NO;
    
    __weak typeof(self)ws =self;
    [[AppService sharedAppService] uploadLogs:^{
        [ws reportResult:LocalizedString(@"UploadSuccess")];
    } error:^(NSString *errorMsg) {
        [ws reportResult:[NSString stringWithFormat:LocalizedString(@"UploadFailed"), errorMsg]];
    }];
}

- (void)reportResult:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.indicatorView.hidden = YES;
        self.resultLabel.hidden = NO;
        self.resultLabel.text = text;
        self.startButton.enabled = YES;
        self.uploadLogsButton.enabled = YES;
    });
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
