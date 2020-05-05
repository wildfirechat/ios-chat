//
//  DeviceTableViewController.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/5/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "DeviceTableViewController.h"
#import "DeviceViewController.h"
#import "CreateDeviceViewController.h"
#import "Device.h"
#import "AppService.h"
#import "MBProgressHUD.h"

@interface DeviceTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSArray<Device *> *devices;
@end

@implementation DeviceTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我的设备";
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"+" style:UIBarButtonItemStyleDone target:self action:@selector(onRightBtn:)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    __weak typeof(self) ws = self;
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"获取中...";
    [hud showAnimated:YES];
    
    [[AppService sharedAppService] getMyDevices:^(NSArray<Device *> * _Nonnull devices) {
        [hud hideAnimated:NO];
        
        ws.devices = devices;
        [ws.tableView reloadData];
    } error:^(int error_code) {
        [hud hideAnimated:NO];
        hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"获取失败";
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
    }];
}

- (void)onRightBtn:(id)sender {
    CreateDeviceViewController *vc = [[CreateDeviceViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    Device *device = [self.devices objectAtIndex:indexPath.row];
    cell.textLabel.text = device.name;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devices.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Device *device = [self.devices objectAtIndex:indexPath.row];
    DeviceViewController *vc = [[DeviceViewController alloc] init];
    vc.device = device;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
