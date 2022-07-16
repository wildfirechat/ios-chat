//
//  WFCUConversationFilesViewController.m
//  WFChatUIKit
//
//  Created by dali on 2020/11/12.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import "WFCUConversationFilesViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUFilesViewController.h"
#import <SDWebImage/SDWebImage.h>
#import "WFCUImage.h"

@interface WFCUConversationFilesViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSArray<WFCCConversationInfo *> *conversations;
@end

@implementation WFCUConversationFilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    self.conversations = [[WFCCIMService sharedWFCIMService] getConversationInfos:@[@(Single_Type),@(Group_Type),@(SecretChat_Type)] lines:@[@(0)]];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.conversations.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    WFCCConversationInfo *conv = self.conversations[indexPath.row];
    if (conv.conversation.type == Single_Type) {
        WFCCUserInfo *user = [[WFCCIMService sharedWFCIMService] getUserInfo:conv.conversation.target refresh:NO];
        if (user.friendAlias.length) {
            cell.textLabel.text = user.friendAlias;
        } else if(user.displayName.length) {
            cell.textLabel.text = user.displayName;
        } else {
            cell.textLabel.text = @"用户";
        }
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:user.portrait] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
    } else if (conv.conversation.type == Group_Type) {
        WFCCGroupInfo *group = [[WFCCIMService sharedWFCIMService] getGroupInfo:conv.conversation.target refresh:NO];
        if (group.displayName.length) {
            cell.textLabel.text = group.displayName;
        } else {
            cell.textLabel.text = @"群组";
        }
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:group.portrait] placeholderImage: [WFCUImage imageNamed:@"group_default_portrait"]];
    } else if (conv.conversation.type == SecretChat_Type) {
        NSString *userId = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:conv.conversation.target].userId;
        WFCCUserInfo *user = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
        if (user.friendAlias.length) {
            cell.textLabel.text = user.friendAlias;
        } else if(user.displayName.length) {
            cell.textLabel.text = user.displayName;
        } else {
            cell.textLabel.text = @"用户";
        }
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:user.portrait] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCConversationInfo *conv = self.conversations[indexPath.row];
    WFCUFilesViewController *vc = [[WFCUFilesViewController alloc] init];
    vc.conversation = conv.conversation;
    [self.navigationController pushViewController:vc animated:YES];
}
@end
