//
//  BrowserViewController.h
//  WildFireChat
//
//  Created by heavyrain.lee on 2018/5/15.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUBrowserViewController : UIViewController
@property(nonatomic, strong)NSString *url;
@property(nonatomic, strong)NSString *htmlString;
@property(nonatomic, assign)BOOL hidenOpenInBrowser;
// 重新加载指定 URL（可用于 token 刷新后重载页面；webView 未初始化时仅更新 url，viewDidLoad 会加载）
- (void)loadUrl:(NSString *)urlString;
@end
