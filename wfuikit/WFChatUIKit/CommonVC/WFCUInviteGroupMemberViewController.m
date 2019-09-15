//
//  InviteGroupMemberViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/18.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUInviteGroupMemberViewController.h"


@interface WFCUInviteGroupMemberViewController ()
@property (nonatomic, strong)UITextField *memberField;
@end

@implementation WFCUInviteGroupMemberViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(onCancel:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Ok") style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    
    CGRect rect = self.view.bounds;
    self.memberField = [[UITextField alloc] initWithFrame:CGRectMake(20, kStatusBarAndNavigationBarHeight + 50, rect.size.width - 40, 40)];
    [self.memberField setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.memberField];
    [self.view setBackgroundColor:[UIColor grayColor]];
    [self.memberField becomeFirstResponder];
}


- (void)onCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onDone:(id)sender {
    if (self.inviteMember && self.memberField.text) {
        self.inviteMember(self.groupId, @[self.memberField.text]);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
