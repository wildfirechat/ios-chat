//
//  ManagerTableViewController.m
//  WFChatUIKit
//
//  Created by heavyrain lee on 2019/6/26.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "GroupMuteTableViewController.h"
#import "SDWebImage.h"
#import "WFCUContactListViewController.h"
#import "WFCUGeneralSwitchTableViewCell.h"

@interface GroupMuteTableViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSMutableArray<WFCCGroupMember *> *managerList;
@end

@implementation GroupMuteTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = WFCString(@"GroupMuteSetting");
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    WFCUGeneralSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[WFCUGeneralSwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.textLabel.text = WFCString(@"MuteAll");
        cell.onSwitch = ^(BOOL value, void (^onDone)(BOOL success)) {
            [[WFCCIMService sharedWFCIMService] modifyGroupInfo:self.groupInfo.target type:Modify_Group_Mute newValue:value?@"1":@"0" notifyLines:@[@(0)] notifyContent:nil success:^{
                onDone(YES);
            } error:^(int error_code) {
                onDone(NO);
            }];
        };
    }
    
    cell.on = self.groupInfo.mute;
    
   
    
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}
@end
