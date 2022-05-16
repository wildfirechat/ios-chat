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
@end
