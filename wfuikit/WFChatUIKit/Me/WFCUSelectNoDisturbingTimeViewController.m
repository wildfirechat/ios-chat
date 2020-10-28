//
//  WFCUSelectNoDisturbingTimeViewController.m
//  WFChatUIKit
//
//  Created by dali on 2020/10/27.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import "WFCUSelectNoDisturbingTimeViewController.h"
#import "WFCUConfigManager.h"



@interface WFCUSelectNoDisturbingTimeViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)UIDatePicker *datePicker;
@end

@implementation WFCUSelectNoDisturbingTimeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 400)];
    self.datePicker.datePickerMode = UIDatePickerModeTime;
    [self.datePicker addTarget:self action:@selector(onTimeChanged:) forControlEvents:UIControlEventValueChanged];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.startMins*60];
    self.datePicker.date = date;
    
    self.tableView.tableFooterView = self.datePicker;
    
    
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
    
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}
- (void)onTimeChanged:(id)sender {
    NSDate *date = self.datePicker.date;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    
    NSInteger interval = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:[NSDate date]];
    if (self.tableView.indexPathForSelectedRow.row == 0) {
        self.startMins = (hour-interval/3600 + 24)%24*60 + minute;
    } else {
        self.endMins = (hour-interval/3600 + 24)%24*60 + minute;
    }
    
    
    [self.tableView reloadData];
}

- (void)didMoveToParentViewController:(UIViewController*)parent {
    [super didMoveToParentViewController:parent];
    if (self.onSelectTime) {
        self.onSelectTime(self.startMins, self.endMins);
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    NSInteger interval = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:[NSDate date]];
    if (indexPath.row == 0) {
        cell.textLabel.text = @"From";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%02d:%02d", (self.startMins/60+interval/3600)%24, self.startMins%60];
    } else {
        cell.textLabel.text = @"To";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%02d:%02d", (self.endMins/60+interval/3600)%24, self.endMins%60];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.startMins*60];
        self.datePicker.date = date;
    } else {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.endMins*60];
        self.datePicker.date = date;
    }
}
@end
