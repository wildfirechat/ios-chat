//
//  GroupMemberTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/18.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUGroupMemberTableViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUGroupMemberTableViewCell.h"

@interface WFCUGroupMemberTableViewController ()
@property (nonatomic, strong)NSMutableArray *members;
@property (nonatomic, strong)NSMutableArray *selectedMembers;;
@end

@implementation WFCUGroupMemberTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.members = [[NSMutableArray alloc] init];
    self.selectedMembers = [[NSMutableArray alloc] init];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(onCancel:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Ok") style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    
    self.members = [[[WFCCIMService sharedWFCIMService] getGroupMembers:self.groupId forceUpdate:YES] mutableCopy];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}


- (void)onCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onDone:(id)sender {
    if (self.selectResult) {
        self.selectResult(self.groupId, self.selectedMembers);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.members.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUGroupMemberTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"memberSelect"];
    
    if (cell == nil) {
        cell = [[WFCUGroupMemberTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"memberSelect"];
        if (self.selectable) {
            cell.isSelectable = YES;
        }
    }
    WFCCGroupMember *member = self.members[indexPath.row];
    WFCCUserInfo *user = [[WFCCIMService sharedWFCIMService] getUserInfo:member.memberId inGroup:self.groupId refresh:NO];
    cell.groupNameView.text = user.displayName;
    if (self.selectable) {
        if ([self.selectedMembers containsObject:member]) {
            cell.isSelected = YES;
        } else {
            cell.isSelected = NO;
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *member = self.members[indexPath.row];
    if ([self.selectedMembers containsObject:member]) {
        [self.selectedMembers removeObject:member];
    } else {
        if (self.multiSelect) {
            [self.selectedMembers removeAllObjects];
        }
        [self.selectedMembers addObject:member];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
