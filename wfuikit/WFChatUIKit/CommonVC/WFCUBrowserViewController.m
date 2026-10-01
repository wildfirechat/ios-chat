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
#import "WFCUPanGroupPickerViewController.h"

@interface WFCUBrowserViewController () <WKNavigationDelegate>
@property (nonatomic, strong)DWKWebView *webView;
@property(nonatomic, strong)NSMutableDictionary<NSString *, NSNumber *> *configDict;

@property (nonatomic, assign)BOOL authed;

// setPageHeader：页面把标题栏交给宿主画，按钮点击多次回调（complete:NO）。
@property (nonatomic, copy)JSCallback pageHeaderCallback;
@property (nonatomic, strong)NSArray<NSDictionary *> *pageHeaderActions;
@end

@implementation WFCUBrowserViewController

/*
 野火开放平台，从JS调用原生代码有2种形式:
 一种是异步形式，参数带有completion:(JSCallback)completionHandler，返回结果使用completionHandler回调回去。请参考getAuthCode:completion:方法；
 另外一种是同步形式，直接返回数据。注意同步接口一定要返回参数，如果没有有效返回数据，请返回nil，不要用void函数。请参考 config: 方法
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    self.configDict = [[NSMutableDictionary alloc] init];
    self.webView = [[DWKWebView alloc] initWithFrame:self.view.bounds];
    //viewDidLoad 那一刻的 bounds 还不是真实尺寸（工作台网页在 iPad 上常驻右栏，
    //首次上屏时是过渡值，之后旋转/分屏/栏宽变化还会再变），不跟的话网页就停在
    //初始尺寸上、填不满右栏。iPhone 上视图恒等于屏幕宽，这一行是 no-op。
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:self.webView];
    // 工作台等自签证书的 https 页面需要处理证书挑战
    self.webView.navigationDelegate = self;
    [self.webView addJavascriptObject:self namespace:nil];
    
#ifdef DEBUG
    [self.webView setDebugMode:YES];
#endif
    
    if(self.url.length) {
        NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self.url, (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]", NULL, kCFStringEncodingUTF8));
        if (![NSURL URLWithString:encodedString].scheme) {
            encodedString = [@"http://" stringByAppendingString:encodedString];
        }
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
    
    if(!self.authed) {
        //需要认证的页面不让用浏览器打开
        UIAlertAction *openInBrowserAction = [UIAlertAction actionWithTitle:WFCString(@"OpenInBrowser") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (@available(iOS 10, *)) {
                [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:ws.url] options:@{} completionHandler:nil];
            } else {
                [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:ws.url]];
            }
            
            [ws.navigationController popViewControllerAnimated:NO];
        }];
        [alertController addAction:openInBrowserAction];
    }
    
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
    if (!appType) {
        appType = [message[@"apptype"] intValue];
    }
    __weak typeof(self) ws = self;
    [[WFCCIMService sharedWFCIMService] getAuthCode:appId type:appType host:self.webView.URL.host success:^(NSString *authCode) {
        ws.authed = YES;
        completionHandler(0, authCode,YES);
    } error:^(int error_code) {
        completionHandler(error_code, nil,YES);
    }];
}

- (id)openUrl:(NSString *)url {
    WFCUBrowserViewController *browser = [[WFCUBrowserViewController alloc] init];
    browser.url = url;
    browser.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:browser animated:YES];
    return nil;
}

/// 在线文档页（<root>/doc/...）不会调用 config: 做签名，chooseContacts/chooseGroup 需要跳过签名门控。
- (BOOL)isPanDocPage {
    NSString *path = self.webView.URL.path ?: @"";
    return [path isEqualToString:@"/doc"] ||
           [path hasPrefix:@"/doc/"] ||
           [path rangeOfString:@"/pan/doc"].location != NSNotFound;
}

/// 下载文档/历史版本：交给系统（应用内打开文件会白屏）。参数是地址字符串或 {url,name}。
- (id)downloadFile:(id)arg {
    NSString *url = nil;
    if ([arg isKindOfClass:[NSString class]]) {
        url = arg;
    } else if ([arg isKindOfClass:[NSDictionary class]]) {
        url = arg[@"url"];
    }
    NSURL *nsurl = url.length ? [NSURL URLWithString:url] : nil;
    if (!nsurl || !nsurl.scheme) {
        NSLog(@"downloadFile ignored: %@", arg);
        return nil;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 10, *)) {
            [[UIApplication sharedApplication] openURL:nsurl options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:nsurl];
        }
    });
    return nil;
}

/// 页面标题栏交给宿主：{title?,subtitle?,actions:[{id,text,icon,primary}]}。
/// 按钮点击用 complete:NO 多次回调按钮 id（回调常驻）。
- (void)setPageHeader:(NSDictionary *)message completion:(JSCallback)completionHandler {
    self.pageHeaderCallback = completionHandler;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([message isKindOfClass:[NSDictionary class]]) {
            NSString *title = message[@"title"];
            NSString *subtitle = message[@"subtitle"];
            if (title.length) {
                self.title = title;
            }
            self.navigationItem.prompt = subtitle.length ? subtitle : nil;
            NSArray *actions = message[@"actions"];
            if ([actions isKindOfClass:[NSArray class]]) {
                self.pageHeaderActions = actions;
                NSMutableArray *items = [NSMutableArray array];
                for (NSInteger i = 0; i < actions.count; i++) {
                    NSDictionary *action = actions[i];
                    if (![action isKindOfClass:[NSDictionary class]]) {
                        continue;
                    }
                    NSString *text = action[@"text"] ?: action[@"id"];
                    if (!text.length) {
                        continue;
                    }
                    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:text style:UIBarButtonItemStylePlain target:self action:@selector(onPageHeaderAction:)];
                    item.tag = i;
                    [items addObject:item];
                }
                self.navigationItem.rightBarButtonItems = items.count ? items : nil;
            } else {
                self.pageHeaderActions = nil;
                self.navigationItem.rightBarButtonItems = nil;
            }
        }
    });
}

- (void)onPageHeaderAction:(UIBarButtonItem *)sender {
    if (sender.tag < 0 || sender.tag >= (NSInteger)self.pageHeaderActions.count) {
        return;
    }
    NSDictionary *action = self.pageHeaderActions[sender.tag];
    NSString *actionId = action[@"id"];
    if (actionId.length && self.pageHeaderCallback) {
        self.pageHeaderCallback(0, actionId, NO);
    }
}

/// 群多选：回 {code:0, data:"<JSON串 [{gid,name,portrait}]>"}，取消回 -1。
- (void)chooseGroup:(NSDictionary *)message completion:(JSCallback)completionHandler {
    if (![self isPanDocPage] && (!self.webView.URL.host || ![self.configDict[self.webView.URL.host] boolValue])) {
        NSLog(@"Error host %@ not config!", self.webView.URL.host);
        completionHandler(1, nil, YES);
        return;
    }
    
    WFCUPanGroupPickerViewController *picker = [[WFCUPanGroupPickerViewController alloc] init];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:picker];
    picker.selectResult = ^(NSArray<WFCCGroupInfo *> *groups) {
        NSMutableArray *output = [[NSMutableArray alloc] init];
        for (WFCCGroupInfo *group in groups) {
            [output addObject:@{@"gid": group.target ?: @"",
                                @"name": group.displayName.length ? group.displayName : (group.name ?: @""),
                                @"portrait": group.portrait ?: @""}];
        }
        if (output.count) {
            NSData *data = [NSJSONSerialization dataWithJSONObject:output options:0 error:nil];
            NSString *json = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"[]";
            completionHandler(0, json, YES);
        } else {
            completionHandler(1, nil, YES);
        }
    };
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}

- (void)close:(NSDictionary *)message completion:(JSCallback)completionHandler {
    [self.navigationController popoverPresentationController];
    completionHandler(0, nil, YES);
}

- (id)config:(NSDictionary *)message {
    NSString *appId = message[@"appId"];
    int appType = [message[@"appType"] intValue];
    if (!appType) {
        appType = [message[@"apptype"] intValue];
    }
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
    return nil;
}

- (void)chooseContacts:(NSDictionary *)message completion:(JSCallback)completionHandler {
    // 在线文档页不调用 config: 做签名，跳过该校验，否则分享选人会静默失败。
    if(![self isPanDocPage] && (!self.webView.URL.host || ![self.configDict[self.webView.URL.host] boolValue])) {
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
                    [output addObject:@{@"uid":userInfo.userId, @"name":userInfo.name ?: @"", @"displayName":userInfo.displayName ?: @"", @"portrait":userInfo.portrait ?: @""}];
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

- (id)toast:(NSDictionary *)message {
    NSLog(@"toast: %@", message);
    return nil;
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if(!parent) {
        [self.webView removeJavascriptObject:nil];
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    // 工作台等自签证书的 https 页面
    [[WFCCCertificateManager sharedManager] handleChallenge:challenge completion:completionHandler];
}
@end
