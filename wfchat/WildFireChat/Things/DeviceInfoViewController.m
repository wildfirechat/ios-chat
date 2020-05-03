//
//  DeviceInfoViewController.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/5/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "DeviceInfoViewController.h"

@interface DeviceInfoViewController ()
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UILabel *idLabel;
@property(nonatomic, strong)UILabel *tokenLabel;
@property(nonatomic, strong)UILabel *ownerLabel;
@end

@implementation DeviceInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat width = self.view.bounds.size.width;
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 120, width - 32, 20)];
    self.nameLabel.text = [NSString stringWithFormat:@"设备名称：%@", self.device.name];
    [self.view addSubview:self.nameLabel];
    
    self.idLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 148, width - 32, 20)];
    self.idLabel.text = [NSString stringWithFormat:@"设备ID：%@", self.device.deviceId];
    [self.view addSubview:self.idLabel];
    
    self.tokenLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 176, width - 32, 20)];
    self.tokenLabel.text = [NSString stringWithFormat:@"设备令牌：%@", self.device.token];
    [self.view addSubview:self.tokenLabel];
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
