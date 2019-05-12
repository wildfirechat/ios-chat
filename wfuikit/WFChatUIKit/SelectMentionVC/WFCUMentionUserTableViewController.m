//
//  WFCUMentionUserTableViewController.m
//  WFChatUIKit
//
//  Created by WF Chat on 2018/10/24.
//  Copyright © 2018 WF Chat. All rights reserved.
//

#import "WFCUMentionUserTableViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDWebImage.h"
#import "WFCUContactTableViewCell.h"

@interface WFCUMentionUserTableViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<WFCCGroupMember *> *groupMembers;
@property (nonatomic, strong)WFCCGroupMember *selectedMember;
@end

@implementation WFCUMentionUserTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.groupMembers = [[[WFCCIMService sharedWFCIMService] getGroupMembers:self.groupId forceUpdate:NO] mutableCopy];
    [self.groupMembers enumerateObjectsUsingBlock:^(WFCCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.memberId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            [self.groupMembers removeObjectAtIndex:idx];
            *stop = YES;
        }
    }];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(onCancel:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)onCancel:(id)sender {
    [self.delegate didCancelMentionAtRange:self.range];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onDone:(id)sender {
    if (self.selectedMember) {
        NSString *name = self.selectedMember.alias;
        if (!name.length) {
            WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.selectedMember.memberId inGroup:self.groupId refresh:NO];
            name = userInfo.displayName;
        }
        NSString *text = [NSString stringWithFormat:@"@%@ ", name];
        self.range = NSMakeRange(self.range.location, text.length);
        [self.delegate didMentionType:1 user:self.selectedMember.memberId range:self.range text:text];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self onCancel:sender];
    }
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groupMembers.count;
}

#define REUSEIDENTIFY @"reuseIdentifier"
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    WFCUContactTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSEIDENTIFY];
        contactCell.big = YES;
    }
    
    WFCCGroupMember *member = [self.groupMembers objectAtIndex:(indexPath.row)];
    if (member.alias.length) {
        contactCell.groupAlias = member.alias;
    }
    contactCell.userId = member.memberId;
    
    
    return contactCell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedMember = [self.groupMembers objectAtIndex:indexPath.row];
    [self onDone:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.f;
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
