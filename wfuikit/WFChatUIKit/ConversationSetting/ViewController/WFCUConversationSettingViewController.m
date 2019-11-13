//
//  ConversationSettingViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/11/2.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUConversationSettingViewController.h"
#import "SDWebImage.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUConversationSettingMemberCollectionViewLayout.h"
#import "WFCUConversationSettingMemberCell.h"
#import "WFCUContactListViewController.h"
#import "WFCUMessageListViewController.h"
#import "WFCUGeneralModifyViewController.h"
#import "WFCUSwitchTableViewCell.h"
#import "WFCUCreateGroupViewController.h"
#import "WFCUProfileTableViewController.h"
#import "WFCUCreateGroupViewController.h"
#import "GroupManageTableViewController.h"
#import "WFCUGroupMemberCollectionViewController.h"

#import "MBProgressHUD.h"
#import "WFCUMyProfileTableViewController.h"
#import "WFCUConversationSearchTableViewController.h"
#import "WFCUChannelProfileViewController.h"
#import "QrCodeHelper.h"
#import "UIView+Toast.h"
#import "WFCUConfigManager.h"
#import "WFCUUtilities.h"
#import "WFCUGroupAnnouncementViewController.h"


@interface WFCUConversationSettingViewController () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong)UICollectionView *memberCollectionView;
@property (nonatomic, strong)WFCUConversationSettingMemberCollectionViewLayout *memberCollectionViewLayout;
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)WFCCGroupInfo *groupInfo;
@property (nonatomic, strong)WFCCUserInfo *userInfo;
@property (nonatomic, strong)WFCCChannelInfo *channelInfo;
@property (nonatomic, strong)NSArray<WFCCGroupMember *> *memberList;

@property (nonatomic, strong)UIImageView *channelPortrait;
@property (nonatomic, strong)UILabel *channelName;
@property (nonatomic, strong)UILabel *channelDesc;

@property (nonatomic, strong)WFCUGroupAnnouncement *groupAnnouncement;

@property (nonatomic, assign)BOOL showMoreMember;
@property (nonatomic, assign)int extraBtnNumber;
@property (nonatomic, assign)int memberCollectionCount;
@end



#define Group_Member_Cell_Reuese_ID @"Group_Member_Cell_Reuese_ID"
#define Group_Member_Visible_Lines 9
@implementation WFCUConversationSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.conversation.type == Single_Type) {
        self.userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.conversation.target refresh:YES];
        self.memberList = @[self.conversation.target];
    } else if(self.conversation.type == Group_Type){
        self.groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.conversation.target refresh:YES];
        self.memberList = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.conversation.target forceUpdate:YES];
    } else if(self.conversation.type == Channel_Type) {
        self.channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:YES];
        self.memberList = @[self.conversation.target];
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    if(self.conversation.type == Group_Type) {
        __weak typeof(self)ws = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:kGroupMemberUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            if ([ws.conversation.target isEqualToString:note.object]) {
                ws.groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:ws.conversation.target refresh:NO];
                ws.memberList = [[WFCCIMService sharedWFCIMService] getGroupMembers:ws.conversation.target forceUpdate:NO];
                [ws setupMemberCollectionView];
                [ws.memberCollectionView reloadData];
            }
        }];
        [[WFCUConfigManager globalManager].appServiceProvider getGroupAnnouncement:self.groupInfo.target success:^(WFCUGroupAnnouncement *announcement) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.groupAnnouncement = announcement;
                if ([self isGroupManager] && self.groupInfo.type == GroupType_Restricted) {
                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:4 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                } else {
                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                }
                
            });
        } error:^(int error_code) {
            
        }];
    }
    
    if(self.conversation.type == Channel_Type) {
        CGFloat portraitWidth = 80;
        CGFloat top = 40;
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        self.channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:YES];
        
        self.channelPortrait = [[UIImageView alloc] initWithFrame:CGRectMake((screenWidth - portraitWidth)/2, top, portraitWidth, portraitWidth)];
        [self.channelPortrait sd_setImageWithURL:[NSURL URLWithString:[self.channelInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"channel_default_portrait"]];
        self.channelPortrait.userInteractionEnabled = YES;
        [self.channelPortrait addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapChannelPortrait:)]];
        
        top += portraitWidth;
        top += 20;
        self.channelName = [[UILabel alloc] initWithFrame:CGRectMake(40, top, screenWidth - 40 - 40, 18)];
        self.channelName.font = [UIFont systemFontOfSize:18];
        self.channelName.textAlignment = NSTextAlignmentCenter;
        self.channelName.text = self.channelInfo.name;
        

        top += 18;
        top += 20;
        
        if (self.channelInfo.desc) {
            NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:self.channelInfo.desc];
            UIFont *font = [UIFont systemFontOfSize:14];
            [attributeString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, self.channelInfo.desc.length)];
            NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
            CGRect rect = [attributeString boundingRectWithSize:CGSizeMake(screenWidth - 80, CGFLOAT_MAX) options:options context:nil];
            
            self.channelDesc = [[UILabel alloc] initWithFrame:CGRectMake(40, top, screenWidth - 80, rect.size.height)];
            self.channelDesc.font = [UIFont systemFontOfSize:14];
            self.channelDesc.textAlignment = NSTextAlignmentCenter;
            self.channelDesc.text = self.channelInfo.desc;
            self.channelDesc.numberOfLines = 0;
            [self.channelDesc sizeToFit];
            
            top += rect.size.height;
            top += 20;
        }
        
        
        UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, top)];
        [container addSubview:self.channelPortrait];
        [container addSubview:self.channelName];
        [container addSubview:self.channelDesc];
        self.tableView.tableHeaderView = container;
    }
}

- (void)setupMemberCollectionView {
    if (self.conversation.type == Single_Type || self.conversation.type == Group_Type) {
        self.memberCollectionViewLayout = [[WFCUConversationSettingMemberCollectionViewLayout alloc] initWithItemMargin:5];

        if (self.conversation.type == Single_Type) {
            self.extraBtnNumber = 1;
            self.memberCollectionCount = 2;
        } else if(self.conversation.type == Group_Type) {
            if ([self isGroupManager]) {
                self.extraBtnNumber = 2;
                self.memberCollectionCount = (int)self.memberList.count + self.extraBtnNumber;
            } else if(self.groupInfo.type == GroupType_Restricted) {
                if (self.groupInfo.joinType == 1 || self.groupInfo.joinType == 0) {
                    self.extraBtnNumber = 1;
                    self.memberCollectionCount = (int)self.memberList.count + self.extraBtnNumber;
                } else {
                    self.memberCollectionCount = (int)self.memberList.count;
                }
            } else {
                self.extraBtnNumber = 1;
                self.memberCollectionCount = (int)self.memberList.count + self.extraBtnNumber;
            }
            if (self.memberCollectionCount > Group_Member_Visible_Lines * 4) {
                self.memberCollectionCount = Group_Member_Visible_Lines * 4;
                self.showMoreMember = YES;
            }
        } else if(self.conversation.type == Channel_Type) {
            self.memberCollectionCount = 1;
        }
        
        self.memberCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [self.memberCollectionViewLayout getHeigthOfItemCount:self.memberCollectionCount]) collectionViewLayout:self.memberCollectionViewLayout];
        self.memberCollectionView.delegate = self;
        self.memberCollectionView.dataSource = self;
        
        self.memberCollectionView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        
        [self.memberCollectionView registerClass:[WFCUConversationSettingMemberCell class] forCellWithReuseIdentifier:Group_Member_Cell_Reuese_ID];
        
        if (self.showMoreMember) {
            UIView *head = [[UIView alloc] init];
            CGRect frame = self.memberCollectionView.frame;
            frame.size.height += 36;
            head.frame = frame;
            [head addSubview:self.memberCollectionView];
            
            UIButton *moreBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, frame.size.height - 36, frame.size.width, 36)];
            [moreBtn setTitle:WFCString(@"ShowAllMembers") forState:UIControlStateNormal];
            
            [moreBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [moreBtn addTarget:self action:@selector(onViewAllMember:) forControlEvents:UIControlEventTouchDown];
            [head addSubview:moreBtn];
            
            head.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
            
            self.tableView.tableHeaderView = head;
        } else {
            self.tableView.tableHeaderView = self.memberCollectionView;
        }
    }

}

- (void)onViewAllMember:(id)sender {
    WFCUGroupMemberCollectionViewController *vc = [[WFCUGroupMemberCollectionViewController alloc] init];
    vc.groupId = self.groupInfo.target;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onTapChannelPortrait:(id)sender {
    WFCUChannelProfileViewController *pvc = [[WFCUChannelProfileViewController alloc] init];
    pvc.channelInfo = self.channelInfo;
    [self.navigationController pushViewController:pvc animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
- (BOOL)isChannelOwner {
    if (self.conversation.type != Channel_Type) {
        return false;
    }
    
    return [self.channelInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId];
}

- (BOOL)isGroupOwner {
    if (self.conversation.type != Group_Type) {
        return false;
    }
    
    return [self.groupInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId];
}

- (BOOL)isGroupManager {
    if (self.conversation.type != Group_Type) {
        return false;
    }
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

- (void)onDeleteAndQuit:(id)sender {
    if(self.conversation.type == Group_Type) {
        if ([self isGroupOwner]) {
            __weak typeof(self) ws = self;
            [[WFCCIMService sharedWFCIMService] removeConversation:self.conversation clearMessage:YES];
            [[WFCCIMService sharedWFCIMService] dismissGroup:self.conversation.target notifyLines:@[@(0)] notifyContent:nil success:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ws.navigationController popToRootViewControllerAnimated:YES];
                });
            } error:^(int error_code) {
                
            }];
        } else {
            __weak typeof(self) ws = self;
            [[WFCCIMService sharedWFCIMService] quitGroup:self.conversation.target notifyLines:@[@(0)] notifyContent:nil success:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ws.navigationController popToRootViewControllerAnimated:YES];
                });
            } error:^(int error_code) {
                
            }];
        }
    } else {
        if ([self isChannelOwner]) {
            __weak typeof(self) ws = self;
            [[WFCCIMService sharedWFCIMService] destoryChannel:self.conversation.target success:^{
                [[WFCCIMService sharedWFCIMService] removeConversation:ws.conversation clearMessage:YES];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ws.navigationController popToRootViewControllerAnimated:YES];
                });
            } error:^(int error_code) {
                
            }];
        } else {
            __weak typeof(self) ws = self;
            [[WFCCIMService sharedWFCIMService] listenChannel:self.conversation.target listen:NO success:^{
                [[WFCCIMService sharedWFCIMService] removeConversation:ws.conversation clearMessage:YES];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ws.navigationController popToRootViewControllerAnimated:YES];
                });
            } error:^(int error_code) {
                
            }];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.conversation.type == Single_Type) {
        self.userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.conversation.target refresh:NO];
        self.memberList = @[self.conversation.target];
    } else if(self.conversation.type == Group_Type) {
        self.groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.conversation.target refresh:NO];
        self.memberList = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.conversation.target forceUpdate:NO];
    } else if(self.conversation.type == Channel_Type) {
        self.channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:NO];
        self.memberList = @[self.conversation.target];
    }
    [self setupMemberCollectionView];
    
    [self.memberCollectionView reloadData];
    [self.tableView reloadData];
}
#pragma mark - UITableViewDataSource<NSObject>
- (BOOL)isGroupNameCell:(NSIndexPath *)indexPath {
  if(self.conversation.type == Group_Type && indexPath.section == 0 && indexPath.row == 0) {
    return YES;
  }
  return NO;
}

- (BOOL)isGroupPortraitCell:(NSIndexPath *)indexPath {
  if(self.conversation.type == Group_Type && indexPath.section == 0 && indexPath.row == 1) {
    return YES;
  }
  return NO;
}

- (BOOL)isGroupQrCodeCell:(NSIndexPath *)indexPath {
    if(self.conversation.type == Group_Type && indexPath.section == 0 && indexPath.row == 2) {
        return YES;
    }
    return NO;
}

- (BOOL)isGroupManageCell:(NSIndexPath *)indexPath {
  if(self.conversation.type == Group_Type && indexPath.section == 0 && indexPath.row == 3) {
    if ([self isGroupManager] && self.groupInfo.type == GroupType_Restricted) {
        return YES;
    } else {
        return NO;
    }
  }
  return NO;
}

- (BOOL)isGroupAnnouncementCell:(NSIndexPath *)indexPath {
    if(self.conversation.type == Group_Type && indexPath.section == 0) {
        if ([self isGroupManager] && self.groupInfo.type == GroupType_Restricted) {
            if (indexPath.row == 4) {
                return YES;
            }
        } else {
            if (indexPath.row == 3) {
                return YES;
            }
        }
    }
    return NO;
}


- (BOOL)isSearchMessageCell:(NSIndexPath *)indexPath {
  if((self.conversation.type == Group_Type && indexPath.section == 1 && indexPath.row == 0)
     ||(self.conversation.type == Single_Type && indexPath.section == 0 && indexPath.row == 0)
     ||(self.conversation.type == Channel_Type && indexPath.section == 0 && indexPath.row == 0)) {
    return YES;
  }
  return NO;
}

- (BOOL)isMessageSilentCell:(NSIndexPath *)indexPath {
  if((self.conversation.type == Group_Type && indexPath.section == 2 && indexPath.row == 0)
     ||(self.conversation.type == Single_Type && indexPath.section == 1 && indexPath.row == 0)
     ||(self.conversation.type == Channel_Type && indexPath.section == 1 && indexPath.row == 0)) {
    return YES;
  }
  return NO;
}

- (BOOL)isSetTopCell:(NSIndexPath *)indexPath {
  if((self.conversation.type == Group_Type && indexPath.section == 2 && indexPath.row == 1)
     ||(self.conversation.type == Single_Type && indexPath.section == 1 && indexPath.row == 1)
     ||(self.conversation.type == Channel_Type && indexPath.section == 1 && indexPath.row == 1)) {
    return YES;
  }
  return NO;
}

- (BOOL)isSaveGroupCell:(NSIndexPath *)indexPath {
  if((self.conversation.type == Group_Type && indexPath.section == 2 && indexPath.row == 2)) {
    return YES;
  }
  return NO;
}

- (BOOL)isGroupNameCardCell:(NSIndexPath *)indexPath {
  if((self.conversation.type == Group_Type && indexPath.section == 3 && indexPath.row == 0)) {
    return YES;
  }
  return NO;
}

- (BOOL)isShowNameCardCell:(NSIndexPath *)indexPath {
  if((self.conversation.type == Group_Type && indexPath.section == 3 && indexPath.row == 1)) {
    return YES;
  }
  return NO;
}

- (BOOL)isClearMessageCell:(NSIndexPath *)indexPath {
  if((self.conversation.type == Group_Type && indexPath.section == 4 && indexPath.row == 0)
     || (self.conversation.type == Single_Type && indexPath.section == 2 && indexPath.row == 0)
     || (self.conversation.type == Channel_Type && indexPath.section == 2 && indexPath.row == 0)) {
    return YES;
  }
  return NO;
}

- (BOOL)isQuitGroup:(NSIndexPath *)indexPath {
    if(self.conversation.type == Group_Type && indexPath.section == 5 && indexPath.row == 0) {
        return YES;
    }
    return NO;
}

- (BOOL)isUnsubscribeChannel:(NSIndexPath *)indexPath {
    if (self.conversation.type == Channel_Type && indexPath.section == 3 && indexPath.row == 0) {
        return YES;
    }
    return NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.conversation.type == Group_Type) {
        if (section == 0) {
            if ([self isGroupManager] && self.groupInfo.type == GroupType_Restricted) {
                return 5; //群名称，群头像，群二维码，群管理，群公告
            } else {
                return 4; //群名称，群头像，群二维码，群公告
            }
            
        } else if(section == 1) {
            return 1; //查找聊天内容
        } else if(section == 2) {
            return 3; //消息免打扰，置顶聊天，保存到通讯录
        } else if(section == 3) {
            return 2; //群昵称，显示群昵称
        } else if(section == 4) {
            return 1; //清空聊天记录
        } else if(section == 5) {
            return 1; //删除退群
        }
    } else if(self.conversation.type == Single_Type) {
        if(section == 0) {
            return 1; //查找聊天内容
        } else if(section == 1) {
            return 2; //消息免打扰，置顶聊天
        } else if(section == 2) {
            return 1; //清空聊天记录
        }
    } else if(self.conversation.type == Channel_Type) {
        if(section == 0) {
            return 1; //查找聊天内容
        } else if(section == 1) {
            return 2; //消息免打扰，置顶聊天
        } else if(section == 2) {
            return 1; //清空聊天记录
        } else if(section == 3) {
            return 1; //取消订阅/销毁订阅
        }
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isGroupAnnouncementCell:indexPath]) {
        float height = [WFCUUtilities getTextDrawingSize:self.groupAnnouncement.text font:[UIFont systemFontOfSize:12] constrainedSize:CGSizeMake(self.view.bounds.size.width - 48, 1000)].height;
        if (height > 136) {
            height = 136;
        }
        return height + 48;
    }
    return 48;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}
- (UITableViewCell *)cellOfTable:(UITableView *)tableView WithTitle:(NSString *)title withDetailTitle:(NSString *)detailTitle withDisclosureIndicator:(BOOL)withDI withSwitch:(BOOL)withSwitch withSwitchType:(SwitchType)type {
    if (withSwitch) {
        WFCUSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"styleSwitch"];
        if(cell == nil) {
            cell = [[WFCUSwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"styleSwitch" conversation:self.conversation];
        }
        cell.detailTextLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
        cell.textLabel.text = title;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.type = type;
      
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"style1Cell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"style1Cell"];
        }
        cell.textLabel.text = title;
        cell.detailTextLabel.text = detailTitle;
        cell.accessoryType = withDI ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
      
        return cell;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
  if ([self isGroupNameCell:indexPath]) {
    return [self cellOfTable:tableView WithTitle:WFCString(@"GroupName") withDetailTitle:self.groupInfo.name withDisclosureIndicator:YES withSwitch:NO withSwitchType:SwitchType_Conversation_None];
  } else if ([self isGroupPortraitCell:indexPath]) {
    UITableViewCell *cell = [self cellOfTable:tableView WithTitle:WFCString(@"ChangePortrait") withDetailTitle:nil withDisclosureIndicator:NO withSwitch:NO withSwitchType:SwitchType_Conversation_None];
    UIImageView *portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 56, 8, 40, 40)];
    [portraitView sd_setImageWithURL:[NSURL URLWithString:[self.groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"group_default_portrait"]];
    cell.accessoryView = portraitView;
    return cell;
  } else if([self isGroupQrCodeCell:indexPath]) {
    UITableViewCell *cell = [self cellOfTable:tableView WithTitle:WFCString(@"GroupQRCode") withDetailTitle:nil withDisclosureIndicator:YES withSwitch:NO withSwitchType:SwitchType_Conversation_None];
      
      CGFloat width = [UIScreen mainScreen].bounds.size.width;
      UIImage *qrcode = [UIImage imageNamed:@"qrcode"];
      UIImageView *qrview = [[UIImageView alloc] initWithFrame:CGRectMake(width - 56, 5, 30, 30)];
      qrview.image = qrcode;
      [cell addSubview:qrview];
      
      return cell;
  } else if ([self isGroupManageCell:indexPath]) {
    return [self cellOfTable:tableView WithTitle:WFCString(@"GroupManage") withDetailTitle:nil withDisclosureIndicator:YES withSwitch:NO withSwitchType:SwitchType_Conversation_None];
  } else if([self isGroupAnnouncementCell:indexPath]) {
//    return [self cellOfTable:tableView WithTitle:@"群公告" withDetailTitle:nil withDisclosureIndicator:YES withSwitch:NO withSwitchType:SwitchType_Conversation_None];
      
      UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"announcementCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"announcementCell"];
        }
        cell.textLabel.text = @"群公告";
        cell.detailTextLabel.text = self.groupAnnouncement.text;
        cell.detailTextLabel.numberOfLines = 10;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
      
        return cell;
      
  } else if ([self isSearchMessageCell:indexPath]) {
    return [self cellOfTable:tableView WithTitle:WFCString(@"SearchMessageContent") withDetailTitle:nil withDisclosureIndicator:NO withSwitch:NO withSwitchType:SwitchType_Conversation_None];
  } else if ([self isMessageSilentCell:indexPath]) {
    return [self cellOfTable:tableView WithTitle:WFCString(@"Silent") withDetailTitle:nil withDisclosureIndicator:NO withSwitch:YES withSwitchType:SwitchType_Conversation_Silent];
  } else if ([self isSetTopCell:indexPath]) {
    return [self cellOfTable:tableView WithTitle:WFCString(@"PinChat") withDetailTitle:nil withDisclosureIndicator:NO withSwitch:YES withSwitchType:SwitchType_Conversation_Top];
  } else if ([self isSaveGroupCell:indexPath]) {
    return [self cellOfTable:tableView WithTitle:WFCString(@"SaveToContact") withDetailTitle:nil withDisclosureIndicator:NO withSwitch:YES withSwitchType:SwitchType_Conversation_Save_To_Contact];
  } else if ([self isGroupNameCardCell:indexPath]) {
    WFCCGroupMember *groupMember = [[WFCCIMService sharedWFCIMService] getGroupMember:self.conversation.target memberId:[WFCCNetworkService sharedInstance].userId];
      if (groupMember.alias.length) {
          return [self cellOfTable:tableView WithTitle:WFCString(@"NicknameInGroup") withDetailTitle:groupMember.alias withDisclosureIndicator:YES withSwitch:NO withSwitchType:SwitchType_Conversation_None];
      } else {
          return [self cellOfTable:tableView WithTitle:WFCString(@"NicknameInGroup") withDetailTitle:WFCString(@"Unset") withDisclosureIndicator:YES withSwitch:NO withSwitchType:SwitchType_Conversation_None];
      }
    
  } else if([self isShowNameCardCell:indexPath]) {
    return [self cellOfTable:tableView WithTitle:WFCString(@"ShowMemberNickname") withDetailTitle:nil withDisclosureIndicator:NO withSwitch:YES withSwitchType:SwitchType_Conversation_Show_Alias];
  } else if ([self isClearMessageCell:indexPath]) {
    return [self cellOfTable:tableView WithTitle:WFCString(@"ClearChatHistory") withDetailTitle:nil withDisclosureIndicator:NO withSwitch:NO withSwitchType:SwitchType_Conversation_None];
  } else if([self isQuitGroup:indexPath]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"buttonCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"buttonCell"];
            for (UIView *subView in cell.subviews) {
                [subView removeFromSuperview];
            }
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 4, self.view.frame.size.width - 40, 40)];
            if ([self isGroupOwner]) {
                [btn setTitle:WFCString(@"DismissGroup") forState:UIControlStateNormal];
            } else {
                [btn setTitle:WFCString(@"QuitGroup") forState:UIControlStateNormal];
            }
            
            btn.layer.cornerRadius = 5.f;
            btn.layer.masksToBounds = YES;
            
            btn.backgroundColor = [UIColor redColor];
            [btn addTarget:self action:@selector(onDeleteAndQuit:) forControlEvents:UIControlEventTouchUpInside];
            [cell addSubview:btn];
        }
        return cell;
  } else if([self isUnsubscribeChannel:indexPath]) {
      UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"buttonCell"];
      if (cell == nil) {
          cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"buttonCell"];
          for (UIView *subView in cell.subviews) {
              [subView removeFromSuperview];
          }
          UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 4, self.view.frame.size.width - 40, 40)];
          if ([self isChannelOwner]) {
              [btn setTitle:WFCString(@"DestroyChannel") forState:UIControlStateNormal];
          } else {
              [btn setTitle:WFCString(@"UnscribeChannel") forState:UIControlStateNormal];
          }
          
          btn.layer.cornerRadius = 5.f;
          btn.layer.masksToBounds = YES;
          
          btn.backgroundColor = [UIColor redColor];
          [btn addTarget:self action:@selector(onDeleteAndQuit:) forControlEvents:UIControlEventTouchUpInside];
          [cell addSubview:btn];
      }
      return cell;
  }
    return nil;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.conversation.type == Single_Type) {
        return 3;
    } else if(self.conversation.type == Group_Type) {
        return 6;
    } else if(self.conversation.type == Channel_Type) {
        return 4;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self)weakSelf = self;
  if ([self isGroupNameCell:indexPath]) {
      if (self.groupInfo.type == GroupType_Restricted && ![self isGroupManager]) {
          [self.view makeToast:WFCString(@"OnlyManangerCanChangeGroupNameHint") duration:1 position:CSToastPositionCenter];
          return;
      }
    WFCUGeneralModifyViewController *gmvc = [[WFCUGeneralModifyViewController alloc] init];
    gmvc.defaultValue = self.groupInfo.name;
    gmvc.titleText = WFCString(@"ModifyGroupName");
    gmvc.canEmpty = NO;
    gmvc.tryModify = ^(NSString *newValue, void (^result)(BOOL success)) {
      [[WFCCIMService sharedWFCIMService] modifyGroupInfo:self.groupInfo.target type:Modify_Group_Name newValue:newValue notifyLines:@[@(0)] notifyContent:nil success:^{
        result(YES);
      } error:^(int error_code) {
        result(NO);
      }];
    };
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:gmvc];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
  } else if ([self isGroupPortraitCell:indexPath]) {
      if (self.groupInfo.type == GroupType_Restricted && ![self isGroupManager]) {
          [self.view makeToast:WFCString(@"OnlyManangerCanChangeGroupPortraitHint") duration:1 position:CSToastPositionCenter];
          return;
      }
    WFCUCreateGroupViewController *vc = [[WFCUCreateGroupViewController alloc] init];
    vc.isModifyPortrait = YES;
    vc.groupId = self.groupInfo.target;
    vc.memberIds = [[NSMutableArray alloc] init];
    for (WFCCGroupMember *member in self.memberList) {
      [vc.memberIds addObject:member.memberId];
    }
    
    [self.navigationController pushViewController:vc animated:YES];
  } else if ([self isGroupManageCell:indexPath]) {
      GroupManageTableViewController *gmvc = [[GroupManageTableViewController alloc] init];
      gmvc.groupInfo = self.groupInfo;
      [self.navigationController pushViewController:gmvc animated:YES];
  } else if ([self isSearchMessageCell:indexPath]) {
      WFCUConversationSearchTableViewController *mvc = [[WFCUConversationSearchTableViewController alloc] init];
      mvc.conversation = self.conversation;
      mvc.hidesBottomBarWhenPushed = YES;
      [self.navigationController pushViewController:mvc animated:YES];
  } else if ([self isMessageSilentCell:indexPath]) {
    
  } else if ([self isSetTopCell:indexPath]) {
    
  } else if ([self isSaveGroupCell:indexPath]) {
    
  } else if ([self isGroupNameCardCell:indexPath]) {
    WFCUGeneralModifyViewController *gmvc = [[WFCUGeneralModifyViewController alloc] init];
    WFCCGroupMember *groupMember = [[WFCCIMService sharedWFCIMService] getGroupMember:self.conversation.target memberId:[WFCCNetworkService sharedInstance].userId];
    gmvc.defaultValue = groupMember.alias;
    gmvc.titleText = WFCString(@"ModifyMyGroupNameCard");
    gmvc.canEmpty = NO;
    gmvc.tryModify = ^(NSString *newValue, void (^result)(BOOL success)) {
      [[WFCCIMService sharedWFCIMService] modifyGroupAlias:self.conversation.target alias:newValue notifyLines:@[@(0)] notifyContent:nil success:^{
        result(YES);
      } error:^(int error_code) {
        result(NO);
      }];
    };
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:gmvc];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
  } else if([self isShowNameCardCell:indexPath]) {
    
  } else if ([self isClearMessageCell:indexPath]) {
      UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:WFCString(@"ConfirmDelete") message:nil preferredStyle:UIAlertControllerStyleActionSheet];

      UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

      }];
      UIAlertAction *actionDelete = [UIAlertAction actionWithTitle:WFCString(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
          [[WFCCIMService sharedWFCIMService] clearMessages:self.conversation];
              MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakSelf.view animated:NO];
              hud.label.text = WFCString(@"Deleted");
              hud.mode = MBProgressHUDModeText;
              hud.removeFromSuperViewOnHide = YES;
              [hud hideAnimated:NO afterDelay:1.5];
          
          [[NSNotificationCenter defaultCenter] postNotificationName:kMessageListChanged object:weakSelf.conversation];
      }];
      
      //把action添加到actionSheet里
      [actionSheet addAction:actionDelete];
      [actionSheet addAction:actionCancel];
      
      //相当于之前的[actionSheet show];
      dispatch_async(dispatch_get_main_queue(), ^{
          [self presentViewController:actionSheet animated:YES completion:nil];
      });
  } else if([self isGroupQrCodeCell:indexPath]) {
      if (gQrCodeDelegate) {
          [gQrCodeDelegate showQrCodeViewController:self.navigationController type:QRType_Group target:self.groupInfo.target];
      }
  } else if([self isGroupAnnouncementCell:indexPath]) {
      WFCUGroupAnnouncementViewController *vc = [[WFCUGroupAnnouncementViewController alloc] init];
      vc.announcement = self.groupAnnouncement;
      vc.isManager = [self isGroupManager];
      [self.navigationController pushViewController:vc animated:YES];
  }
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.conversation.type == Group_Type || self.conversation.type == Single_Type) {
        return self.memberCollectionCount;
    } else if(self.conversation.type == Channel_Type) {
        return self.memberList.count;
    }
    return 0;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFCUConversationSettingMemberCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:Group_Member_Cell_Reuese_ID forIndexPath:indexPath];
    if (indexPath.row < self.memberCollectionCount-self.extraBtnNumber) {
        WFCCGroupMember *member = self.memberList[indexPath.row];
        [cell setModel:member withType:self.conversation.type];
    } else {
        if (indexPath.row == self.memberCollectionCount-self.extraBtnNumber) {
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
    if (indexPath.row == self.memberCollectionCount-self.extraBtnNumber) {
        WFCUContactListViewController *pvc = [[WFCUContactListViewController alloc] init];
        pvc.selectContact = YES;
        pvc.multiSelect = YES;
        NSMutableArray *disabledUser = [[NSMutableArray alloc] init];
      if(self.conversation.type == Group_Type) {
          
        for (WFCCGroupMember *member in [[WFCCIMService sharedWFCIMService] getGroupMembers:self.groupInfo.target forceUpdate:NO]) {
            [disabledUser addObject:member.memberId];
        }
        pvc.selectResult = ^(NSArray<NSString *> *contacts) {
            [[WFCCIMService sharedWFCIMService] addMembers:contacts toGroup:ws.conversation.target notifyLines:@[@(0)] notifyContent:nil success:^{
              [[WFCCIMService sharedWFCIMService] getGroupMembers:ws.conversation.target forceUpdate:YES];
                
            } error:^(int error_code) {
              
            }];
        };
        pvc.disableUsersSelected = YES;
      } else {
        [disabledUser addObject:self.conversation.target];
        pvc.selectResult = ^(NSArray<NSString *> *contacts) {
            WFCUCreateGroupViewController *vc = [[WFCUCreateGroupViewController alloc] init];
            vc.memberIds = [contacts mutableCopy];
            if(![vc.memberIds containsObject:self.conversation.target]) {
              [vc.memberIds insertObject:self.conversation.target atIndex:0];
            }
            
            if(![vc.memberIds containsObject:[WFCCNetworkService sharedInstance].userId]) {
                [vc.memberIds insertObject:[WFCCNetworkService sharedInstance].userId atIndex:0];
            }
            
            vc.hidesBottomBarWhenPushed = YES;
            UINavigationController *nav = self.navigationController;
            [self.navigationController popToRootViewControllerAnimated:NO];
            [nav pushViewController:vc animated:YES];
            
            vc.onSuccess = ^(NSString *groupId) {
                WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
                mvc.conversation = [[WFCCConversation alloc] init];
                mvc.conversation.type = Group_Type;
                mvc.conversation.target = groupId;
                mvc.conversation.line = 0;
                
                mvc.hidesBottomBarWhenPushed = YES;
                [nav pushViewController:mvc animated:YES];
            };
            
        };
        pvc.disableUsersSelected = YES;
      }
        pvc.disableUsers = disabledUser;
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
        [self.navigationController presentViewController:navi animated:YES completion:nil];
    } else if(indexPath.row == self.memberCollectionCount-self.extraBtnNumber + 1) {
        WFCUContactListViewController *pvc = [[WFCUContactListViewController alloc] init];
        pvc.selectContact = YES;
        pvc.multiSelect = YES;
        __weak typeof(self)ws = self;
        pvc.selectResult = ^(NSArray<NSString *> *contacts) {
          [[WFCCIMService sharedWFCIMService] kickoffMembers:contacts fromGroup:self.conversation.target notifyLines:@[@(0)] notifyContent:nil success:^{
            [[WFCCIMService sharedWFCIMService] getGroupMembers:ws.conversation.target forceUpdate:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
              NSMutableArray *tmpArray = [ws.memberList mutableCopy];
              NSMutableArray *removeArray = [[NSMutableArray alloc] init];
              [tmpArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                WFCCGroupMember *member = obj;
                if([contacts containsObject:member.memberId]) {
                  [removeArray addObject:member];
                }
              }];
              [tmpArray removeObjectsInArray:removeArray];
              ws.memberList = [tmpArray mutableCopy];
              [ws setupMemberCollectionView];
              [ws.memberCollectionView reloadData];
            });
          } error:^(int error_code) {
            
          }];
      };
        NSMutableArray *candidateUsers = [[NSMutableArray alloc] init];
        NSMutableArray *disableUsers = [[NSMutableArray alloc] init];
        BOOL isOwner = [self isGroupOwner];
        
        for (WFCCGroupMember *member in [[WFCCIMService sharedWFCIMService] getGroupMembers:self.groupInfo.target forceUpdate:NO]) {
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
      NSString *userId;
      if(self.conversation.type == Group_Type) {
        WFCCGroupMember *member = [self.memberList objectAtIndex:indexPath.row];
        userId = member.memberId;
          
        if (self.groupInfo.privateChat) {
          if (![self.groupInfo.owner isEqualToString:userId] && ![self.groupInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
              WFCCGroupMember *gm = [[WFCCIMService sharedWFCIMService] getGroupMember:self.conversation.target memberId:[WFCCNetworkService sharedInstance].userId];
              if (gm.type != Member_Type_Manager) {
                  WFCCGroupMember *gm = [[WFCCIMService sharedWFCIMService] getGroupMember:self.conversation.target memberId:userId];
                  if (gm.type != Member_Type_Manager) {
                      [self.view makeToast:WFCString(@"NotAllowTemporarySession") duration:1 position:CSToastPositionCenter];
                      return;
                  }
              }
          }
        }

      } else {
        userId = self.conversation.target;
      }
//        if ([[WFCCNetworkService sharedInstance].userId isEqualToString:userId]) {
//            WFCUMyProfileTableViewController *vc = [[WFCUMyProfileTableViewController alloc] init];
//            vc.hidesBottomBarWhenPushed = YES;
//            [self.navigationController pushViewController:vc animated:YES];
//        } else {
            WFCUProfileTableViewController *vc = [[WFCUProfileTableViewController alloc] init];
            vc.userId = userId;
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
//        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
