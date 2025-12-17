//
//  GroupInfoViewController.m
//  WildFireChat
//
//  Created by heavyrain lee on 2019/3/3.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "WFCUGroupInfoViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "WFCUConfigManager.h"
#import "WFCUImage.h"
#import "WFCUMessageListViewController.h"
#import "WFCUUtilities.h"

@interface WFCUGroupInfoViewController ()
@property (nonatomic, strong)WFCCGroupInfo *groupInfo;
@property (nonatomic, strong)UIImageView *groupProtraitView;
@property (nonatomic, strong)UILabel *groupNameLabel;
@property (nonatomic, strong)NSArray<WFCCGroupMember *> *members;
@property (nonatomic, strong)UIButton *btn;
@property (nonatomic, assign)BOOL isJoined;
@end

@implementation WFCUGroupInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.groupNameLabel.text = @"群组";
    self.groupProtraitView.image = [WFCUImage imageNamed:@"contact_group_icon"];
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSArray<WFCCGroupInfo *> *groupInfoList = note.userInfo[@"groupInfoList"];
        for (WFCCGroupInfo *groupInfo in groupInfoList) {
            if ([ws.groupId isEqualToString:groupInfo.target]) {
                ws.groupInfo = groupInfo;
                break;
            }
        }
    }];
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupMemberUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([ws.groupId isEqualToString:note.object]) {
            ws.members = [[WFCCIMService sharedWFCIMService] getGroupMembers:ws.groupId forceUpdate:NO];
        }
        
    }];
    
    self.groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.groupId refresh:NO];
    self.view.backgroundColor = [UIColor whiteColor];
    self.members = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.groupId forceUpdate:NO];
}

- (void)setGroupInfo:(WFCCGroupInfo *)groupInfo {
    _groupInfo = groupInfo;
    if(groupInfo) {
        if(groupInfo.portrait.length) {
            [self.groupProtraitView sd_setImageWithURL:[NSURL URLWithString:groupInfo.portrait] placeholderImage:[WFCUImage imageNamed:@""]];
        }
        
        if(groupInfo.displayName.length) {
            if(groupInfo.memberCount > 0) {
                self.groupNameLabel.text = [NSString stringWithFormat:@"%@(%ld)", groupInfo.displayName, groupInfo.memberCount];
            } else {
                self.groupNameLabel.text = groupInfo.displayName;
            }
        }
    }
}

- (void)setMembers:(NSArray<WFCCGroupMember *> *)members {
    _members = members;
    __block BOOL isContainMe = NO;
    [members enumerateObjectsUsingBlock:^(WFCCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.memberId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            *stop = YES;
            isContainMe = YES;
        }
    }];
    
    if(!isContainMe) {
        __weak typeof(self)ws = self;
        [[WFCUConfigManager globalManager].appServiceProvider getGroupMembersForPortrait:self.groupId success:^(NSArray<NSDictionary<NSString *, NSString *> *> *groupMembers) {
            [ws onGetGroupMember:groupMembers];
        } error:^(int error_code) {
            NSLog(@"error");
        }];
    }
    self.isJoined = isContainMe;
}

- (void)onGetGroupMember:(NSArray<NSDictionary<NSString *, NSString *> *> *)groupMembers {
    if(!self.groupInfo.portrait.length) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *imagePath = [WFCCUtilities getGroupGridPortrait:self.groupId memberPortraits:groupMembers width:50 defaultUserPortrait:^UIImage *(NSString *userId) {
                return [WFCUImage imageNamed:@"PersonalChat"];
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.groupProtraitView.image = [UIImage imageWithContentsOfFile:imagePath];
            });
        });
    }
    
    if(!self.groupInfo.name.length) {
        __block NSString *name = @"";
        [groupMembers enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSString *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString* memberName = [obj objectForKey:@"name"];
            if(memberName.length + name.length < 64) {
                name = [NSString stringWithFormat:@"%@,%@", name, memberName];
            } else {
                name = [NSString stringWithFormat:@"%@等", name];
            }
        }];
        
        if(self.groupInfo.memberCount > 0) {
            self.groupNameLabel.text = [NSString stringWithFormat:@"%@(%ld)", name, self.groupInfo.memberCount];
        } else {
            self.groupNameLabel.text = name;
        }
    }
}

- (void)setIsJoined:(BOOL)isJoined {
    _isJoined = isJoined;
    if (isJoined) {
        [self.btn setTitle:WFCString(@"StartChat") forState:UIControlStateNormal];
    } else {
        [self.btn setTitle:WFCString(@"StartChat") forState:UIControlStateNormal];
    }
}

- (void)onButtonPressed:(id)sender {
    if (self.isJoined) {
        WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
        mvc.conversation = [[WFCCConversation alloc] init];
        mvc.conversation.type = Group_Type;
        mvc.conversation.target = self.groupId;
        mvc.conversation.line = 0;
        
        mvc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:mvc animated:YES];
    } else {
        __weak typeof(self) ws = self;
        NSString *memberExtra = nil;
        if(self.sourceType) {
            memberExtra = [WFCCUtilities getGroupMemberExtra:self.sourceType sourceTargetId:self.sourceTargetId];
        }
        
        [[WFCCIMService sharedWFCIMService] addMembers:@[[WFCCNetworkService sharedInstance].userId] toGroup:self.groupId memberExtra:memberExtra notifyLines:@[@(0)] notifyContent:nil success:^{
            [[WFCCIMService sharedWFCIMService] getGroupMembers:ws.groupId forceUpdate:YES];
            ws.isJoined = YES;
            [ws onButtonPressed:nil];
        } error:^(int error_code) {
            
        }];
    }
}

- (UIButton *)btn {
    if (!_btn) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _btn = [[UIButton alloc] initWithFrame:CGRectMake(width/2 - 80, 280, 160, 44)];
        _btn.layer.masksToBounds = YES;
        _btn.layer.cornerRadius = 5.f;
        [self.view addSubview:_btn];
        [_btn setBackgroundColor:[UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]];
        [_btn addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchDown];
    }
    return _btn;
}

- (UILabel *)groupNameLabel {
    if (!_groupNameLabel) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _groupNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(width/2 - 100, 200, 200, 24)];
        _groupNameLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_groupNameLabel];
    }
    return _groupNameLabel;
}

- (UIImageView *)groupProtraitView {
    if (!_groupProtraitView) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _groupProtraitView = [[UIImageView alloc] initWithFrame:CGRectMake(width/2 - 32, 120, 64, 64)];
        [self.view addSubview:_groupProtraitView];
    }
    return _groupProtraitView;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
