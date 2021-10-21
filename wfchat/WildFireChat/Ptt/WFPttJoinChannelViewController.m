//
//  WFPttJoinChannelViewController.m
//  PttUIKit
//
//  Created by Hao Jia on 2021/10/14.
//

#ifdef WFC_PTT
#import "WFPttJoinChannelViewController.h"

@interface WFPttJoinChannelViewController ()

@end

@implementation WFPttJoinChannelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss:)];
}

- (void)dismiss:(id)sender {
    if (self.navigationController.presentingViewController) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}
@end
#endif //WFC_PTT
