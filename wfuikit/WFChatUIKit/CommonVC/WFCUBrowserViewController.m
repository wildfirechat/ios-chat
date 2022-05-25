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
#import "dsbridge.h"
#import "WFCUConfigManager.h"
#import "WFCUContactListViewController.h"

@interface WFCUBrowserViewController ()
@property (nonatomic, strong)DWKWebView *webView;
@property(nonatomic, strong)NSMutableDictionary<NSString *, NSNumber *> *configDict;
@end

@implementation WFCUBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.configDict = [[NSMutableDictionary alloc] init];
    self.webView = [[DWKWebView alloc] initWithFrame:self.view.bounds];
    
    [self.view addSubview:self.webView];
    [self.webView addJavascriptObject:self namespace:nil];
    
#ifdef DEBUG
    [self.webView setDebugMode:YES];
#endif
    
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

- (void)getAuthCode:(NSDictionary *)message completion:(JSCallback)completionHandler {
    NSString *appId = message[@"appId"];
    int appType = [message[@"appType"] intValue];
    [[WFCCIMService sharedWFCIMService] getAuthCode:appId type:appType host:self.webView.URL.host success:^(NSString *authCode) {
        completionHandler(0, authCode,YES);
    } error:^(int error_code) {
        completionHandler(error_code, nil,YES);
    }];
}

- (void)openUrl:(NSString *)url {
    WFCUBrowserViewController *browser = [[WFCUBrowserViewController alloc] init];
    browser.url = url;
    browser.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:browser animated:YES];
}

- (void)close:(NSDictionary *)message completion:(JSCallback)completionHandler {
    [self.navigationController popoverPresentationController];
    completionHandler(0, nil, YES);
}

- (void)config:(NSDictionary *)message {
    NSString *appId = message[@"appId"];
    int appType = [message[@"apptype"] intValue];
    int64_t timestamp = [message[@"timestamp"] longLongValue];
    NSString *nonceStr = message[@"nonceStr"];
    NSString *signature = message[@"signature"];
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] configApplication:appId type:appType timestamp:timestamp nonce:nonceStr signature:signature success:^{
        if(ws.webView.URL.host)
            [ws.configDict setObject:@(YES) forKey:ws.webView.URL.host];
        [ws.webView callHandler:@"ready" arguments:nil];
    } error:^(int error_code) {
        if(ws.webView.URL.host)
            [ws.configDict removeObjectForKey:ws.webView.URL.host];
        [ws.webView callHandler:@"error" arguments:@[@(error_code)]];
    }];
}

- (void)chooseContacts:(NSDictionary *)message completion:(JSCallback)completionHandler {
    if(!self.webView.URL.host || ![self.configDict[self.webView.URL.host] boolValue]) {
        NSLog(@"Error host %@ not config!", self.webView.URL.host);
        completionHandler(1, nil, YES);
        return;
    }
    
    int max = [message[@"max"] intValue];
    WFCUContactListViewController *contactVC = [[WFCUContactListViewController alloc] init];
    if(max > 0) {
        contactVC.multiSelect = YES;
        contactVC.maxSelectCount = max;
    }
    contactVC.selectContact = YES;
    contactVC.isPushed = YES;
    contactVC.selectResult = ^(NSArray<NSString *> *contacts) {
        if(contacts.count) {
            NSMutableArray *output = [[NSMutableArray alloc] init];
            [contacts enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:obj refresh:NO];
                if(userInfo) {
                    [output addObject:@{@"uid":userInfo.userId, @"displayName":userInfo.displayName}];
                } else {
                    [output addObject:@{@"uid":obj}];
                }
            }];
            completionHandler(0, output, YES);
        } else {
            completionHandler(1, nil, YES);
        }
    };
    [self.navigationController pushViewController:contactVC animated:YES];
}

- (void)toast:(NSDictionary *)message {
    NSLog(@"toast: %@", message);
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if(!parent) {
        [self.webView removeJavascriptObject:nil];
    }
}
@end
