//
//  WFCUGroupFilesViewController.m
//  WFChatUIKit
//
//  Created by dali on 2020/8/2.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import "WFCUGroupFilesViewController.h"
#import <WFChatClient/WFCChatClient.h>

@interface WFCUGroupFilesViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)UIActivityIndicatorView *activityView;

@property(nonatomic, strong)NSMutableArray<WFCCFileRecord *> *fileRecords;
@end

@implementation WFCUGroupFilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityView.center = self.view.center;
    [self.view addSubview:self.activityView];
    
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] getConversationFiles:self.conversation beforeMessageUid:0 count:20 success:^(NSArray<WFCCFileRecord *> *files) {
        ws.fileRecords = [files mutableCopy];
        [ws.tableView reloadData];
        ws.activityView.hidden = YES;
    } error:^(int error_code) {
        NSLog(@"load fire record error %d", error_code);
        ws.activityView.hidden = YES;
    }];
}


- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    WFCCFileRecord *record = self.fileRecords[indexPath.row];
    
    cell.textLabel.text = record.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"from user %@", record.userId];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fileRecords.count;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WFCCFileRecord *record = self.fileRecords[indexPath.row];
        __weak typeof(self) ws = self;
        [[WFCCIMService sharedWFCIMService] deleteFileRecord:record.messageUid success:^{
            [ws.fileRecords removeObject:record];
            [ws.tableView reloadData];
        } error:^(int error_code) {
            
        }];
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"delete";
}
@end
