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
    
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.indicatorView.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/4 - 10);
    self.indicatorView.hidden = YES;
    [self.view addSubview:self.indicatorView];
    
    self.resultLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - 150, self.view.bounds.size.height/4-40, 300, 60)];
    self.resultLabel.textAlignment = NSTextAlignmentCenter;
    self.resultLabel.text = @"点击\"测试网络\"开始测试";
    self.resultLabel.numberOfLines = 0;
    [self.view addSubview:self.resultLabel];
    
    self.startButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - 80, self.view.bounds.size.height/2 - 20, 160, 40)];
    [self.startButton  setTitle:@"测试网络" forState:UIControlStateNormal];
    [self.startButton setTitleColor:[WFCUConfigManager globalManager].naviTextColor forState:UIControlStateNormal];
    [self.startButton setBackgroundColor:[UIColor greenColor]];
    self.startButton.layer.masksToBounds = YES;
    self.startButton.layer.cornerRadius = 5.0;
    
    [self.startButton addTarget:self action:@selector(onStart:) forControlEvents:UIControlEventTouchDown];
    
    [self.view addSubview:self.startButton];
    
    
    self.uploadLogsButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - 80, self.view.bounds.size.height/2 + 40, 160, 40)];
    [self.uploadLogsButton  setTitle:@"上传日志" forState:UIControlStateNormal];
    [self.uploadLogsButton setTitleColor:[WFCUConfigManager globalManager].naviTextColor forState:UIControlStateNormal];
    [self.uploadLogsButton setBackgroundColor:[UIColor redColor]];
    self.uploadLogsButton.layer.masksToBounds = YES;
    self.uploadLogsButton.layer.cornerRadius = 5.0;
    
    [self.uploadLogsButton addTarget:self action:@selector(onUploadLogs:) forControlEvents:UIControlEventTouchDown];
    
    [self.view addSubview:self.uploadLogsButton];
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
                [ws reportResult:[NSString stringWithFormat:@"测速成功，延时为%dms", duration]];
            } else {
                [ws reportResult:[NSString stringWithFormat:@"测速失败，无法识别服务器返回的数据：%@", responseObject]];
            }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [ws reportResult:[NSString stringWithFormat:@"测速失败，错误原因:%@", error.localizedDescription]];
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
        [ws reportResult:@"上传成功"];
    } error:^(NSString *errorMsg) {
        [ws reportResult:[NSString stringWithFormat:@"上传失败：%@", errorMsg]];
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
