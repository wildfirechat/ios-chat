//
//  GroupInfoViewController.m
//  WildFireChat
//
//  Created by heavyrain lee on 2019/3/3.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "GroupInfoViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDWebImage.h"
#import <WFChatUIKit/WFChatUIKit.h>


@interface GroupInfoViewController ()
@property (nonatomic, strong)WFCCGroupInfo *groupInfo;
@property (nonatomic, strong)UIImageView *groupProtraitView;
@property (nonatomic, strong)UILabel *groupNameLabel;
@property (nonatomic, strong)NSArray<WFCCGroupMember *> *members;
@property (nonatomic, strong)UIButton *btn;
@property (nonatomic, assign)BOOL isJoined;
@end

@implementation GroupInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([ws.groupId isEqualToString:note.object]) {
            WFCCGroupInfo *groupInfo = note.userInfo[@"groupInfo"];
            ws.groupInfo = groupInfo;
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
    [self.groupProtraitView sd_setImageWithURL:[NSURL URLWithString:groupInfo.portrait] placeholderImage:[UIImage imageNamed:@""]];
    self.groupNameLabel.text = groupInfo.name;
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
    self.isJoined = isContainMe;
}

- (void)setIsJoined:(BOOL)isJoined {
    _isJoined = isJoined;
    if (isJoined) {
        [self.btn setTitle:@"进入聊天" forState:UIControlStateNormal];
    } else {
        [self.btn setTitle:@"加入聊天" forState:UIControlStateNormal];
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
        [[WFCCIMService sharedWFCIMService] addMembers:@[[WFCCNetworkService sharedInstance].userId] toGroup:self.groupId notifyLines:@[@(0)] notifyContent:nil success:^{
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
