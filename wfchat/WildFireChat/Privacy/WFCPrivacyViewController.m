//
//  WFCPrivacyViewController.m
//  WildFireChat
//
//  Created by WF Chat on 2019/1/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "WFCPrivacyViewController.h"
#import <WebKit/WebKit.h>

@interface WFCPrivacyViewController ()
@property(nonatomic, strong)WKWebView *webview;
@end

@implementation WFCPrivacyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.webview = [[WKWebView alloc] initWithFrame:self.view.bounds];
    
    NSString *path;
    if (self.isPrivacy) {
        path = @"http://www.wildfirechat.cn/firechat_user_privacy.html";
    } else {
        path = @"http://www.wildfirechat.cn/firechat_user_agreement.html";
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

@end
