//
//  WFCMyProfileTableViewController.m
//  WildFireChat
//
//  Created by heavyrain lee on 2019/3/2.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "WFCMyProfileTableViewController.h"
#import "CreateBarCodeViewController.h"
#import <WFChatClient/WFCChatClient.h>


@interface WFCMyProfileTableViewController ()

@end

@implementation WFCMyProfileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)showMyQrCode {
    CreateBarCodeViewController *vc = [CreateBarCodeViewController new];
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
    vc.str = [NSString stringWithFormat:@"wildfirechat://user/%@", userInfo.userId];
    vc.logoUrl = userInfo.portrait;
    [self.navigationController pushViewController:vc animated:YES];
}
@end
