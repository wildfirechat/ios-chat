//
//  BrowserViewController.m
//  WildFireChat
//
//  Created by heavyrain.lee on 2018/5/15.
//  Copyright © 2018 WildFireChat. All rights reserved.
//
#import <WebKit/WebKit.h>
#import "WFCUBrowserViewController.h"
#import "WFCUForwardViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WebViewJavascriptBridge.h"

@interface WFCUBrowserViewController ()
@property (nonatomic, strong)WKWebView *webView;

@property (nonatomic, strong)WebViewJavascriptBridge* bridge;

@property (nonatomic, strong)WVJBResponseCallback readyCallback;
@property (nonatomic, strong)WVJBResponseCallback errorCallback;
@end

@implementation WFCUBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKUserContentController * userContent = [[WKUserContentController alloc]init];
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContent;
    NSString *path =[[NSBundle bundleForClass:[self class]] pathForResource:@"wfjsbridge" ofType:@"js"];
    NSString *handlerJS = [NSString stringWithContentsOfFile:path encoding:kCFStringEncodingUTF8 error:nil];
    
    WKUserScript *usrScript = [[WKUserScript alloc] initWithSource:handlerJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    [userContent addUserScript:usrScript];

    self.webView = [[WKWebView alloc]initWithFrame:[UIScreen mainScreen].bounds configuration:configuration];
    
    [self.view addSubview:self.webView];
    
    if(self.loadWFJSBridge) {
        [self loadJSBridge];
    }
    
    if(self.url.length) {
        NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self.url, (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]", NULL, kCFStringEncodingUTF8));
        
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:encodedString]]];
        if(!self.hidenOpenInBrowser) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"..." style:UIBarButtonItemStyleDone target:self action:@selector(onRightBtn:)];
        }
    } else {
        [self.webView loadHTMLString:self.htmlString baseURL:nil];
    }
}

- (void)loadJSBridge {
    [WebViewJavascriptBridge enableLogging];
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView];
    
    __weak typeof(self)ws = self;
    [self.bridge registerHandler:@"getAuthCode" handler:^(NSDictionary *data, WVJBResponseCallback responseCallback) {
        NSString *appId = data[@"appId"];
        int appType = [data[@"appType"] intValue];
        [[WFCCIMService sharedWFCIMService] getAuthCode:appId type:appType host:self.webView.URL.host success:^(NSString *authCode) {
            responseCallback(authCode);
        } error:^(int error_code) {
            responseCallback(@(error_code));
        }];
    }];
    
    [self.bridge registerHandler:@"ready" handler:^(id data, WVJBResponseCallback responseCallback) {
        ws.readyCallback = responseCallback;
    }];
    
    [self.bridge registerHandler:@"error" handler:^(id data, WVJBResponseCallback responseCallback) {
        ws.errorCallback = responseCallback;
    }];
    
    [self.bridge registerHandler:@"config" handler:^(id data, WVJBResponseCallback responseCallback) {
        [[WFCCIMService sharedWFCIMService] configApplication:data[@"appId"] type:[data[@"appType"] intValue] timestamp:[data[@"timestamp"] longLongValue] nonce:data[@"nonceStr"] signature:data[@"signature"] success:^{
            ws.readyCallback(nil);
        } error:^(int error_code) {
            ws.errorCallback(@(error_code));
        }];
    }];
}

- (void)callJS:(NSString *)method data:(id)data response:(void(^)(id responseData))responseCallback {
    if(responseCallback) {
        [self.bridge callHandler:method data:data responseCallback:responseCallback];
    } else {
        [self.bridge callHandler:method data:data];
    }
}

- (void)onRightBtn:(id)sender {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    __weak typeof(self)ws = self;
    // Create cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    [alertController addAction:cancelAction];
    
    UIAlertAction *openInBrowserAction = [UIAlertAction actionWithTitle:WFCString(@"OpenInBrowser") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:ws.url]];
        [ws.navigationController popViewControllerAnimated:NO];
    }];
    [alertController addAction:openInBrowserAction];
    
    UIAlertAction *sendToFriendAction = [UIAlertAction actionWithTitle:WFCString(@"SendToFriend") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        WFCUForwardViewController *controller = [[WFCUForwardViewController alloc] init];
        WFCCLinkMessageContent *link = [[WFCCLinkMessageContent alloc] init];
        link.title = ws.webView.title;
        link.url = ws.webView.URL.absoluteString;
        link.thumbnailUrl = [NSString stringWithFormat:@"%@://%@/favicon.ico", ws.webView.URL.scheme, ws.webView.URL.host];
        WFCCMessage *msg = [[WFCCMessage alloc] init];
        msg.content = link;
        
        controller.message = msg;
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:controller];
        [ws.navigationController presentViewController:navi animated:YES completion:nil];
    }];
    [alertController addAction:sendToFriendAction];
    
    if(NSClassFromString(@"SDTimeLineTableViewController")) {
        UIAlertAction *sendToMomentsAction = [UIAlertAction actionWithTitle:WFCString(@"SendToMoments") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
        }];
        [alertController addAction:sendToMomentsAction];
    }
    
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
