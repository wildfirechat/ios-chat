//
//  WFCAboutViewController.m
//  WFChatUIKit
//
//  Created by heavyrain.lee on 2019/1/22.
//  Copyright © 2019 heavyrain.lee. All rights reserved.
//

#import "WFCAboutViewController.h"
#import <WebKit/WebKit.h>


@interface WFCAboutViewController ()
@property(nonatomic, strong)WKWebView *webview;
@end

@implementation WFCAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webview = [[WKWebView alloc] initWithFrame:self.view.bounds];
    //页面在 iPad 右栏里，宽高不恒等于屏幕，补 autoresizing 跟随父视图（iPhone 上 no-op）
    self.webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.wildfirechat.cn"]]];
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
