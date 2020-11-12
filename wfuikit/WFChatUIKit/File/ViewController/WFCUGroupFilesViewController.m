//
//  WFCUGroupFilesViewController.m
//  WFChatUIKit
//
//  Created by dali on 2020/8/2.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUGroupFilesViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUFileRecordTableViewCell.h"
#import "WFCUBrowserViewController.h"


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
    
    self.title = WFCString(@"GroupFiles");
    
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] getConversationFiles:self.conversation fromUser:nil beforeMessageUid:0 count:20 success:^(NSArray<WFCCFileRecord *> *files) {
        ws.fileRecords = [files mutableCopy];
        [ws.tableView reloadData];
        ws.activityView.hidden = YES;
    } error:^(int error_code) {
        NSLog(@"load fire record error %d", error_code);
        ws.activityView.hidden = YES;
    }];
}


- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    WFCUFileRecordTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[WFCUFileRecordTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    WFCCFileRecord *record = self.fileRecords[indexPath.row];
    
    cell.fileRecord = record;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fileRecords.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCFileRecord *record = self.fileRecords[indexPath.row];
    return [WFCUFileRecordTableViewCell sizeOfRecord:record withCellWidth:self.view.bounds.size.width];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCFileRecord *record = self.fileRecords[indexPath.row];
    if ([record.userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        return YES;
    } else if(record.conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:record.conversation.target refresh:NO];
        if ([groupInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            return YES;
        }
        WFCCGroupMember *member = [[WFCCIMService sharedWFCIMService] getGroupMember:record.conversation.target memberId:[WFCCNetworkService sharedInstance].userId];
        if (member.type != Member_Type_Manager) {
            return NO;
        }
        
        WFCCGroupMember *senderMember = [[WFCCIMService sharedWFCIMService] getGroupMember:record.conversation.target memberId:record.userId];
        if (senderMember.type != Member_Type_Manager && senderMember.type != Member_Type_Owner) {
            return YES;
        }
    }
    
    return NO;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCFileRecord *record = self.fileRecords[indexPath.row];
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] getAuthorizedMediaUrl:record.messageUid mediaType:Media_Type_FILE mediaPath:record.url success:^(NSString *authorizedUrl) {
        WFCUBrowserViewController *bvc = [[WFCUBrowserViewController alloc] init];
        bvc.url = authorizedUrl;
        [ws.navigationController pushViewController:bvc animated:YES];
    } error:^(int error_code) {
        WFCUBrowserViewController *bvc = [[WFCUBrowserViewController alloc] init];
        bvc.url = record.url;
        [ws.navigationController pushViewController:bvc animated:YES];
    }];
}
@end
