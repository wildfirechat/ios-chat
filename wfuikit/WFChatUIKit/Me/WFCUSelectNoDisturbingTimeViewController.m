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
    
    
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
    
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}
- (void)onTimeChanged:(UIDatePicker *)sender {
    NSDate *date = sender.date;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    
    NSInteger interval = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:[NSDate date]];
    if (sender.tag == 0) {
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
        UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 96, 3, 96, 35)];
        datePicker.datePickerMode = UIDatePickerModeTime;
        [datePicker addTarget:self action:@selector(onTimeChanged:) forControlEvents:UIControlEventValueChanged];
        datePicker.tag = indexPath.row;
        
        [cell.contentView addSubview:datePicker];
    }
    UIDatePicker *datePicker = nil;
    for (UIView *view in cell.contentView.subviews) {
        if([view isKindOfClass:[UIDatePicker class]]) {
            datePicker = (UIDatePicker *)view;
            break;
        }
    }
    
    if(indexPath.row == 0) {
        datePicker.date = [NSDate dateWithTimeIntervalSince1970:self.startMins*60];
    } else {
        datePicker.date = [NSDate dateWithTimeIntervalSince1970:self.endMins*60];
    }
    
    NSInteger interval = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:[NSDate date]];
    if (indexPath.row == 0) {
        cell.textLabel.text = @"From";
    } else {
        cell.textLabel.text = @"To";
    }
    
    return cell;
}

@end
