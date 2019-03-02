//
//  PCLoginConfirmViewController.m
//  WildFireChat
//
//  Created by heavyrain lee on 2019/3/2.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "PCLoginConfirmViewController.h"

@interface PCLoginConfirmViewController ()

@end

@implementation PCLoginConfirmViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    UIImageView *pcView = [[UIImageView alloc] initWithFrame:CGRectMake((width - 200)/2, 120, 200, 200)];
    pcView.image = [UIImage imageNamed:@"pc"];
    [self.view addSubview:pcView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((width - 200)/2, 320, 200, 16)];
    [label setText:@"确认电脑登陆"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:label];
    
    UIButton *loginBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, height - 150, width - 200, 40)];
    [loginBtn setBackgroundColor:[UIColor greenColor]];
    [loginBtn setTitle:@"登陆" forState:UIControlStateNormal];
    loginBtn.layer.masksToBounds = YES;
    loginBtn.layer.cornerRadius = 5.f;
    
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, height - 90, width - 200, 40)];
    [cancelBtn setTitle:@"取消登陆" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    
    [self.view addSubview:loginBtn];
    [self.view addSubview:cancelBtn];
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
