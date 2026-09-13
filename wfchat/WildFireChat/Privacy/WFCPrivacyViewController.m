//
//  WFCPrivacyViewController.m
//  WildFireChat
//
//  Created by WF Chat on 2019/1/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <WFChatClient/WFCCCertificateManager.h>
#import "WFCPrivacyViewController.h"
#import <WebKit/WebKit.h>
#import "WFCConfig.h"

@interface WFCPrivacyViewController () <WKNavigationDelegate>
@property(nonatomic, strong)WKWebView *webview;
@end

@implementation WFCPrivacyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.webview = [[WKWebView alloc] initWithFrame:self.view.bounds];
    // 自签证书的 https 页面需要处理证书挑战
    self.webview.navigationDelegate = self;
    //页面在 iPad 右栏里，宽高不恒等于屏幕，补 autoresizing 跟随父视图（iPhone 上 no-op）
    self.webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    NSString *path;
    if (self.isPrivacy) {
        path = USER_PRIVACY_URL;
    } else {
        path = USER_AGREEMENT_URL;
    }
    
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:path]]];
    
    
    [self.view addSubview:self.webview];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    [[WFCCCertificateManager sharedManager] handleChallenge:challenge completion:completionHandler];
}
@end
