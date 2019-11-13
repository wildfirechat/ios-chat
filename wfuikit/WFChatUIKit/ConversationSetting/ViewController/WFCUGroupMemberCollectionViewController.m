//
//  WFCUGroupMemberCollectionViewController.m
//  WFChatUIKit
//
//  Created by heavyrain lee on 2019/8/18.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "WFCUGroupMemberCollectionViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUConversationSettingMemberCollectionViewLayout.h"
#import "WFCUConversationSettingMemberCell.h"
#import "WFCUContactListViewController.h"
#import "WFCUProfileTableViewController.h"
#import "WFCUConfigManager.h"
#import "UIView+Toast.h"

@interface WFCUGroupMemberCollectionViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong)UICollectionView *memberCollectionView;
@property (nonatomic, strong)WFCUConversationSettingMemberCollectionViewLayout *memberCollectionViewLayout;
@property (nonatomic, strong)NSArray<WFCCGroupMember *> *memberList;
@property (nonatomic, strong)WFCCGroupInfo *groupInfo;
@end


#define Group_Member_Cell_Reuese_ID @"cell"
@implementation WFCUGroupMemberCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.memberList = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.groupId forceUpdate:YES];
    self.groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.groupId refresh:YES];
    
    int memberCollectionCount;
    if ([self isGroupManager]) {
        memberCollectionCount = (int)self.memberList.count + 2;
    } else if(self.groupInfo.type == GroupType_Restricted) {
        if (self.groupInfo.joinType == 1 || self.groupInfo.joinType == 0) {
            memberCollectionCount = (int)self.memberList.count + 1;
        } else {
            memberCollectionCount = (int)self.memberList.count;
        }
    } else {
        memberCollectionCount = (int)self.memberList.count + 1;
    }
    self.memberCollectionViewLayout = [[WFCUConversationSettingMemberCollectionViewLayout alloc] initWithItemMargin:5];
    
    self.memberCollectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.memberCollectionViewLayout];
    self.memberCollectionView.delegate = self;
    self.memberCollectionView.dataSource = self;
    
    self.memberCollectionView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    [self.memberCollectionView registerClass:[WFCUConversationSettingMemberCell class] forCellWithReuseIdentifier:Group_Member_Cell_Reuese_ID];
    
    [self.view addSubview:self.memberCollectionView];
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupMemberUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([ws.groupId isEqualToString:note.object]) {
            ws.groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:ws.groupId refresh:NO];
            ws.memberList = [[WFCCIMService sharedWFCIMService] getGroupMembers:ws.groupId forceUpdate:NO];
            [ws.memberCollectionView reloadData];
        }
    }];
}


- (BOOL)isGroupOwner {
    return [self.groupInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId];
}

- (BOOL)isGroupManager {
    if ([self isGroupOwner]) {
        return YES;
    }
    __block BOOL isManager = false;
    [self.memberList enumerateObjectsUsingBlock:^(WFCCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.memberId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            if (obj.type != Member_Type_Normal) {
                isManager = YES;
            }
            *stop = YES;
        }
    }];
    return isManager;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if([self isGroupManager]) {
        return self.memberList.count + 2;
    } else {
        if (self.groupInfo.type == GroupType_Restricted && self.groupInfo.joinType != 1 && self.groupInfo.joinType != 0) {
            return self.memberList.count;
        }
        return self.memberList.count + 1;
    }
    
    return 0;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFCUConversationSettingMemberCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:Group_Member_Cell_Reuese_ID forIndexPath:indexPath];
    if (indexPath.row < self.memberList.count) {
        WFCCGroupMember *member = self.memberList[indexPath.row];
        [cell setModel:member withType:Group_Type];
    } else {
        if (indexPath.row == self.memberList.count) {
            [cell.headerImageView setImage:[UIImage imageNamed:@"addmember"]];
            cell.nameLabel.text = nil;
            cell.nameLabel.hidden = YES;
        } else {
            [cell.headerImageView setImage:[UIImage imageNamed:@"removemember"]];
            cell.nameLabel.text = nil;
            cell.nameLabel.hidden = YES;
        }
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self)ws = self;
    if (indexPath.row == self.memberList.count) {
        WFCUContactListViewController *pvc = [[WFCUContactListViewController alloc] init];
        pvc.selectContact = YES;
        pvc.multiSelect = YES;
        NSMutableArray *disabledUser = [[NSMutableArray alloc] init];
        
        for (WFCCGroupMember *member in self.memberList) {
            [disabledUser addObject:member.memberId];
        }
        pvc.selectResult = ^(NSArray<NSString *> *contacts) {
            [[WFCCIMService sharedWFCIMService] addMembers:contacts toGroup:ws.groupId notifyLines:@[@(0)] notifyContent:nil success:^{
                [[WFCCIMService sharedWFCIMService] getGroupMembers:ws.groupId forceUpdate:YES];
                
            } error:^(int error_code) {
                
            }];
        };
        pvc.disableUsersSelected = YES;
        
        pvc.disableUsers = disabledUser;
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
        [self.navigationController presentViewController:navi animated:YES completion:nil];
    } else if(indexPath.row == self.memberList.count + 1) {
        WFCUContactListViewController *pvc = [[WFCUContactListViewController alloc] init];
        pvc.selectContact = YES;
        pvc.multiSelect = YES;
        pvc.selectResult = ^(NSArray<NSString *> *contacts) {
            [[WFCCIMService sharedWFCIMService] kickoffMembers:contacts fromGroup:self.groupId notifyLines:@[@(0)] notifyContent:nil success:^{
                [[WFCCIMService sharedWFCIMService] getGroupMembers:ws.groupId forceUpdate:YES];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSMutableArray *tmpArray = [self.memberList mutableCopy];
                    NSMutableArray *removeArray = [[NSMutableArray alloc] init];
                    [tmpArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        WFCCGroupMember *member = obj;
                        if([contacts containsObject:member.memberId]) {
                            [removeArray addObject:member];
                        }
                    }];
                    [tmpArray removeObjectsInArray:removeArray];
                    self.memberList = [tmpArray mutableCopy];
                    [self.memberCollectionView reloadData];
                });
            } error:^(int error_code) {
                
            }];
        };
        NSMutableArray *candidateUsers = [[NSMutableArray alloc] init];
        NSMutableArray *disableUsers = [[NSMutableArray alloc] init];
        BOOL isOwner = [self isGroupOwner];
        
        for (WFCCGroupMember *member in self.memberList) {
            [candidateUsers addObject:member.memberId];
            if (!isOwner && (member.type == Member_Type_Manager || [self.groupInfo.owner isEqualToString:member.memberId])) {
                [disableUsers addObject:member.memberId];
            }
        }
        [disableUsers addObject:[WFCCNetworkService sharedInstance].userId];
        pvc.candidateUsers = candidateUsers;
        pvc.disableUsers = [disableUsers copy];
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
        [self.navigationController presentViewController:navi animated:YES completion:nil];
    } else {
        WFCCGroupMember *member = [self.memberList objectAtIndex:indexPath.row];
        NSString *userId = member.memberId;
        
        if (self.groupInfo.privateChat) {
          if (![self.groupInfo.owner isEqualToString:userId] && ![self.groupInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
              WFCCGroupMember *gm = [[WFCCIMService sharedWFCIMService] getGroupMember:self.groupId memberId:[WFCCNetworkService sharedInstance].userId];
              if (gm.type != Member_Type_Manager) {
                  WFCCGroupMember *gm = [[WFCCIMService sharedWFCIMService] getGroupMember:self.groupId memberId:userId];
                  if (gm.type != Member_Type_Manager) {
                      [self.view makeToast:WFCString(@"NotAllowTemporarySession") duration:1 position:CSToastPositionCenter];
                      return;
                  }
              }
          }
        }
        
        WFCUProfileTableViewController *vc = [[WFCUProfileTableViewController alloc] init];
        vc.userId = userId;
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

