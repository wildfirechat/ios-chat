//
//  WFCConversationTableViewController.m
//  WildFireChat
//
//  Created by heavyrain lee on 2019/3/2.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "WFCConversationTableViewController.h"
#import "QQLBXScanViewController.h"
#import "StyleDIY.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>

@interface WFCConversationTableViewController ()

@end

@implementation WFCConversationTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


- (void)scanQrCodeAction:(id)sender {
    QQLBXScanViewController *vc = [QQLBXScanViewController new];
    vc.libraryType = SLT_Native;
    vc.scanCodeType = SCT_QRCode;
    
    vc.style = [StyleDIY qqStyle];
    
    //镜头拉远拉近功能
    vc.isVideoZoom = YES;
    vc.hidesBottomBarWhenPushed = YES;
    vc.scanResult = ^(NSString *str) {
        NSLog(@"str scanned %@", str);
        if ([str rangeOfString:@"wildfirechat://user" options:NSCaseInsensitiveSearch].location == 0) {
            NSString *userId = [str lastPathComponent];
            WFCUProfileTableViewController *vc2 = [[WFCUProfileTableViewController alloc] init];
            vc2.userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
            if (vc2.userInfo == nil) {
                return;
            }
            vc2.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc2 animated:YES];
        } else if ([str rangeOfString:@"wildfirechat://group" options:NSCaseInsensitiveSearch].location == 0) {
            
        } else if ([str rangeOfString:@"wildfirechat://pcsession" options:NSCaseInsensitiveSearch].location == 0) {
            
        }
        
    };
    [self.navigationController pushViewController:vc animated:YES];
}

@end
