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

@interface WFCUBrowserViewController ()
@property (nonatomic, strong)WKWebView *webView;
@end

@implementation WFCUBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    
    [self.view addSubview:self.webView];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url]]];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"..." style:UIBarButtonItemStyleDone target:self action:@selector(onRightBtn:)];
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
