//
//  WFCUProfileTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/22.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUProfileTableViewController.h"
#import <SDWebImage/SDWebImage.h>
#import <WFChatClient/WFCChatClient.h>
#import "WFCUMessageListViewController.h"
#import "MBProgressHUD.h"
#import "WFCUMyPortraitViewController.h"
#import "WFCUVerifyRequestViewController.h"
#import "WFCUGeneralModifyViewController.h"
#import "WFCUVideoViewController.h"
#import "WFCUMultiVideoViewController.h"
#if WFCU_SUPPORT_VOIP
#import <WFAVEngineKit/WFAVEngineKit.h>
#endif
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "WFCUConfigManager.h"
#import "WFCUUserMessageListViewController.h"
#import "WFCUImage.h"
#import "WFCUProfileMoreTableViewController.h"
#import "MWPhotoBrowser.h"
#import "WFCUOrganizationViewController.h"
#import "WFCUOrganizationCache.h"
#import "WFCUOrganization.h"
#import "WFCUEmployee.h"
#import "WFCUOrgRelationship.h"
#import "WFCUUtilities.h"
#import "WFCUEmployeeEx.h"
#import "WFCUPanViewController.h"
#import "WFCUPadUtility.h"


@interface WFCUProfileTableViewController () <UITableViewDelegate, UITableViewDataSource, MWPhotoBrowserDelegate>
@property (strong, nonatomic)UIImageView *portraitView;
@property (strong, nonatomic)UILabel *aliasLabel;
@property (strong, nonatomic)UILabel *displayNameLabel;
@property (strong, nonatomic)UILabel *userNameLabel;
@property (strong, nonatomic)UILabel *domainLabel;
@property (strong, nonatomic)UILabel *starLabel;
@property (strong, nonatomic)UITableViewCell *headerCell;


@property (strong, nonatomic)UITableViewCell *sendMessageCell;
@property (strong, nonatomic)UITableViewCell *voipCallCell;
@property (strong, nonatomic)UITableViewCell *addFriendCell;
@property (strong, nonatomic)UITableViewCell *momentCell;
@property (strong, nonatomic)UITableViewCell *moreCell;
@property (nonatomic, strong)UITableViewCell *panCell;
@property (nonatomic, strong)UITableViewCell *userMessagesCell;
@property (nonatomic, strong)UITableViewCell *groupSourceCell;

@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<UITableViewCell *> *cells;
@property (nonatomic, strong)NSMutableArray<UITableViewCell *> *headerCells;

@property (nonatomic, strong)WFCCUserInfo *userInfo;

@property(nonatomic, strong)NSArray<NSNumber *> *organizationIds;

@property(nonatomic, assign)WFCCGroupMemberSourceType groupSourceType;
@property (nonatomic, strong)NSString *groupSourceTargetId;
@end

@implementation WFCUProfileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = WFCString(@"UserInfomation");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEmployeeExUpdated:) name:kEmployeeExUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrganizationUpdated:) name:kOrganizationUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendListUpdated:) name:kFriendListUpdated object:nil];
    
    self.userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.userId refresh:YES];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    //页面刚上屏时可能先按整屏宽排过一遍（安全区还没传下来，容器随后才把它钉回右栏），
    //表格不跟宽度走就会停在整屏宽上：整行按钮按 1210pt 排出来，内容中心偏到栏外
    //（缺陷 #24 实测：发送消息/视频聊天不居中）。跟上页面宽高，被钉回右栏时自己缩回来。
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"..." style:UIBarButtonItemStyleDone target:self action:@selector(onRightBtn:)];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.1)];

    [self loadOrganizationData:YES];

    [self loadData];
}

- (void)loadOrganizationData:(BOOL)refresh {
    WFCUEmployeeEx *employeeEx = [[WFCUOrganizationCache sharedCache] getEmployeeEx:self.userId refresh:refresh];
    if(employeeEx.relationships.count) {
        NSMutableArray<NSNumber *> *arr = [[NSMutableArray alloc] init];
        [employeeEx.relationships enumerateObjectsUsingBlock:^(WFCUOrgRelationship * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(obj.bottom) {
                [arr addObject:@(obj.organizationId)];
            }
        }];
        self.organizationIds = [arr mutableCopy];
    }
}

- (void)onFriendListUpdated:(NSNotification *)notification {
    [self loadData];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (WFCCUserInfo *userInfo in userInfoList) {
        if ([self.userId isEqualToString:userInfo.userId]) {
            self.userInfo = userInfo;
            [self loadData];
            break;
        }
    }
}

- (void)onEmployeeExUpdated:(NSNotification *)notification {
    NSString *employeeId = notification.object;
    if([employeeId isEqualToString:self.userId]) {
        [self loadOrganizationData:NO];
        [self.tableView reloadData];
    }
}

- (void)onOrganizationUpdated:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        keyWindow.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
    [keyWindow tintColorDidChange];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)onRightBtn:(id)sender {
    __weak typeof(self)ws = self;
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [actionSheet addAction:actionCancel];
    
    if ([[WFCCIMService sharedWFCIMService] isMyFriend:self.userId]) {
        UIAlertAction *deleteFriendAction = [UIAlertAction actionWithTitle:WFCString(@"DeleteFriend") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
            hud.label.text = WFCString(@"Processing");
            [hud showAnimated:YES];
            
            [[WFCCIMService sharedWFCIMService] deleteFriend:ws.userId success:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];

                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
                    hud.mode = MBProgressHUDModeText;
                    hud.label.text = WFCString(@"ProcessDone");
                    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                    [hud hideAnimated:YES afterDelay:1.f];
                });
            } error:^(int error_code) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];

                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
                    hud.mode = MBProgressHUDModeText;
                    hud.label.text = WFCString(@"ProcessFailure");
                    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                    [hud hideAnimated:YES afterDelay:1.f];
                });
            }];
        }];
        
        [actionSheet addAction:deleteFriendAction];
    } else {
        UIAlertAction *addFriendAction = [UIAlertAction actionWithTitle:WFCString(@"AddFriend") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            WFCUVerifyRequestViewController *vc = [[WFCUVerifyRequestViewController alloc] init];
            vc.userId = ws.userId;
            vc.sourceType = ws.sourceType;
            vc.sourceTargetId = ws.sourceTargetId;
            [ws.navigationController pushViewController:vc animated:YES];
        }];
        [actionSheet addAction:addFriendAction];
    }
    

    if ([[WFCCIMService sharedWFCIMService] isBlackListed:self.userId]) {
        UIAlertAction *addFriendAction = [UIAlertAction actionWithTitle:WFCString(@"RemoveFromBlacklist") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
            hud.label.text = WFCString(@"Processing");
            [hud showAnimated:YES];
            
            [[WFCCIMService sharedWFCIMService] setBlackList:ws.userId isBlackListed:NO success:^{
                [hud hideAnimated:YES];

                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = WFCString(@"ProcessDone");
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
            } error:^(int error_code) {
                [hud hideAnimated:YES];

                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = WFCString(@"ProcessFailure");
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
            }];
        }];
        [actionSheet addAction:addFriendAction];
    } else if (self.userInfo.type == 0) {  //Only normal user can add to blacklist, robot user not allowed.
        UIAlertAction *addFriendAction = [UIAlertAction actionWithTitle:WFCString(@"Add2Blacklist") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
            hud.label.text = WFCString(@"Processing");
            [hud showAnimated:YES];
            
            [[WFCCIMService sharedWFCIMService] setBlackList:ws.userId isBlackListed:YES success:^{
                [hud hideAnimated:YES];

                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = WFCString(@"ProcessDone");
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
            } error:^(int error_code) {
                [hud hideAnimated:YES];

                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = WFCString(@"ProcessFailure");
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
            }];
        }];
        [actionSheet addAction:addFriendAction];
    }
    
    
    UIAlertAction *aliasAction = [UIAlertAction actionWithTitle:WFCString(@"SetAlias") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [ws setFriendNote];
    }];
    [actionSheet addAction:aliasAction];
    
    if ([[WFCCIMService sharedWFCIMService] isMyFriend:self.userId]) {
        if ([[WFCCIMService sharedWFCIMService] isFavUser:self.userId]) {
            UIAlertAction *cancelStarAction = [UIAlertAction actionWithTitle:WFCString(@"Unstar") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [ws setFavUser];
            }];
            [actionSheet addAction:cancelStarAction];
        } else {
            UIAlertAction *setStarAction = [UIAlertAction actionWithTitle:WFCString(@"Star") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [ws setFavUser];
            }];
            [actionSheet addAction:setStarAction];
        }
    }
    
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)loadData {
    self.cells = [[NSMutableArray alloc] init];
    
    self.sendMessageCell = nil;
    self.voipCallCell = nil;
    self.addFriendCell = nil;
    self.momentCell = nil;
    self.moreCell = nil;
    self.userMessagesCell = nil;
    self.panCell = nil;
    
    self.headerCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    for (UIView *subView in self.headerCell.contentView.subviews) {
        [subView removeFromSuperview];
    }
    //按页面自己的宽度排，不是屏幕宽：iPad 双栏下这张资料页在右栏里，
    //按整屏宽排的话昵称、野火号会一路顶到栏外，右上角那颗星也落到看不见的地方。
    //下面这些 label 另配了 autoresizing，页面还没上屏时宽度先按屏幕宽算，
    //真宽度下来会自己纠回去。iPhone 上取值一个没变。
    CGFloat width = [WFCUPadUtility layoutWidthForView:self.view];
    
    self.portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 14, 58, 58)];
    
    self.portraitView.layer.cornerRadius = 10;
    self.portraitView.layer.masksToBounds = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onViewPortrait:)];
    [self.portraitView addGestureRecognizer:tap];
    self.portraitView.userInteractionEnabled = YES;
    
    
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[self.userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
    
    NSString *alias = [[WFCCIMService sharedWFCIMService] getFriendAlias:self.userId];
    CGFloat startPos = 8;

    if (alias.length) {
        self.aliasLabel = [[UILabel alloc] initWithFrame:CGRectMake(94, 8, width - 64 - 8, 21)];
        self.aliasLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.aliasLabel.text = alias;
        startPos += 24;
    }
    
    self.displayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(94, startPos, width - 94 - 8, 21)];
    self.displayNameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.displayNameLabel.text = self.userInfo.displayName;
    startPos += 24;

    self.userNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(94, startPos, width - 94 - 8, 11)];
    self.userNameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.userNameLabel.text = [NSString stringWithFormat:@"野火号:%@", self.userInfo.name];
    self.userNameLabel.font = [UIFont scaledSystemFontOfSize:12];
    self.userNameLabel.textColor = [UIColor grayColor];
    startPos += 16;
    
    if([WFCCUtilities isExternalTarget:self.userId]) {
        NSString *domainId = [WFCCUtilities getExternalDomain:self.userId];
        self.domainLabel = [[UILabel alloc] initWithFrame:CGRectMake(94, startPos, width - 94 - 8, 11)];
        self.domainLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.domainLabel.attributedText = [WFCCUtilities getExternal:domainId withName:nil withColor:[WFCUConfigManager globalManager].externalNameColor];
        self.domainLabel.font = [UIFont scaledSystemFontOfSize:12];
        startPos += 16;
    }
    
    
    if ([[WFCCIMService sharedWFCIMService] isFavUser:self.userId]) {
        self.starLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 16 - 20, self.displayNameLabel.frame.origin.y, 20, 20)];
        //贴右边，跟着行宽走
        self.starLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        self.starLabel.text = @"☆";
        self.starLabel.font = [UIFont scaledSystemFontOfSize:18];
        self.starLabel.textColor = [UIColor yellowColor];
        
        [self.headerCell.contentView addSubview:self.starLabel];
    }
    
    [self.headerCell.contentView addSubview:self.portraitView];
    [self.headerCell.contentView addSubview:self.displayNameLabel];
    [self.headerCell.contentView addSubview:self.userNameLabel];
    if(self.aliasLabel) {
        [self.headerCell.contentView addSubview:self.aliasLabel];
    }
    if(self.domainLabel) {
        [self.headerCell.contentView addSubview:self.domainLabel];
    }
    self.headerCells = [NSMutableArray new];
    [self.headerCells addObject:self.headerCell];
    
    if (self.userInfo.type == 1) {
        [self setupSendMessageCell:width];
    } else {
        if ([[WFCCIMService sharedWFCIMService] isMyFriend:self.userId]) {
            UITableViewCell *alisaCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"setAlisa"];
            alisaCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            //与下面那两颗整行按钮同一条：按承载它的视图起排 + FlexibleWidth，
            //否则页面还没上屏时按屏幕宽算，在 iPad 右栏里会一路顶到栏外
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(16, 0, [self buttonWidthInHostView:alisaCell.contentView fallback:width] - 16 - 60, 50)];
            btn.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [btn setTitle:WFCString(@"ModifyNickname") forState:UIControlStateNormal];
            [btn setTitleColor:[WFCUConfigManager globalManager].textColor forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:16];
            [btn addTarget:self action:@selector(setFriendNote) forControlEvents:UIControlEventTouchUpInside];
            btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            [alisaCell.contentView addSubview:btn];
            [self showSeparatorLine:alisaCell];
            [self.headerCells addObject:alisaCell];
        }
        
        if (self.fromConversation.type == Group_Type) {
            WFCCGroupMember * groupMember = [[WFCCIMService sharedWFCIMService] getGroupMember:self.fromConversation.target memberId:self.userId];
            NSMutableString *targetId = [[NSMutableString alloc] init];
            self.groupSourceType = [WFCCUtilities getGroupMemberSourceType:groupMember.extra sourceTargetId:targetId];
            if(self.groupSourceType > 0) {
                if(targetId.length) {
                    self.sourceTargetId = [targetId copy];
                }
                if(self.groupSourceType == GroupMemberSource_Invite) {
                    if([self.userId isEqualToString:self.sourceTargetId]) {
                        //可能是当前用户创建的群组，忽略。
                        NSLog(@"Maybe the creator of the group!");
                    } else {
                        if(self.sourceTargetId.length) {
                            self.groupSourceCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
                            self.groupSourceCell.textLabel.text = @"进群方式";
                            self.groupSourceCell.detailTextLabel.text = [NSString stringWithFormat:@"%@ 邀请入群", [WFCCUtilities getUserDisplayName:self.sourceTargetId inGroup:self.fromConversation.target]];
                            [self.cells addObject:self.groupSourceCell];
                        }
                    }
                } else if(self.groupSourceType == GroupMemberSource_QrCode) {
                    if(self.sourceTargetId.length) {
                        self.groupSourceCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
                        self.groupSourceCell.textLabel.text = WFCString(@"JoinGroupMethod");
                        self.groupSourceCell.detailTextLabel.text = [NSString stringWithFormat:WFCString(@"ScanQRCodeToJoinGroup"), [WFCCUtilities getUserDisplayName:self.sourceTargetId inGroup:self.fromConversation.target]];
                        [self.cells addObject:self.groupSourceCell];
                    }
                } else if(self.groupSourceType == GroupMemberSource_Card) {
                    if(self.sourceTargetId.length) {
                        self.groupSourceCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
                        self.groupSourceCell.textLabel.text = WFCString(@"JoinGroupMethod");
                        self.groupSourceCell.detailTextLabel.text = [NSString stringWithFormat:WFCString(@"ShareCardToJoinGroup"), [WFCCUtilities getUserDisplayName:self.sourceTargetId inGroup:self.fromConversation.target]];
                        [self.cells addObject:self.groupSourceCell];
                    }
                } else if(self.groupSourceType == GroupMemberSource_Search) {
                    self.groupSourceCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
                    self.groupSourceCell.textLabel.text = WFCString(@"JoinGroupMethod");
                    self.groupSourceCell.detailTextLabel.text = WFCString(@"JoinGroupBySearch");
                    [self.cells addObject:self.groupSourceCell];
                }
            }
            self.userMessagesCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
            self.userMessagesCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if([self.userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                self.userMessagesCell.textLabel.text = WFCString(@"MyMessages");
            } else {
                self.userMessagesCell.textLabel.text = WFCString(@"He`sMessages");
            }
            [self.cells addObject:self.userMessagesCell];
        }
        
        if (self.userInfo.type == 0) {
            if(NSClassFromString(@"SDTimeLineTableViewController")) {
                self.momentCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"momentCell"];
                for (UIView *subView in self.momentCell.subviews) {
                       [subView removeFromSuperview];
                }
                
                UIButton *momentButton = [[UIButton alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 100, 70)];
                [momentButton setTitle: @"朋友圈" forState:UIControlStateNormal];
                [momentButton setTitleColor:[WFCUConfigManager globalManager].textColor forState:UIControlStateNormal];
                momentButton.titleLabel.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:16];
                momentButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                [momentButton addTarget:self action:@selector(momentClick) forControlEvents:UIControlEventTouchUpInside];
                if (@available(iOS 14, *)) {
                    [self.momentCell.contentView addSubview:momentButton];
                } else {
                    [self.momentCell addSubview:momentButton];
                }
                self.momentCell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            
            // 添加"他/她的网盘"入口（域外用户不显示）
            if([WFCUConfigManager globalManager].panServiceProvider && ![WFCCUtilities isExternalTarget:self.userId]) {
                self.panCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"panCell"];
                self.panCell.textLabel.text = @"他/她的网盘";
                self.panCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        }
        
        if ([[WFCCIMService sharedWFCIMService] isMyFriend:self.userId]) {
            [self setupSendMessageCell:width];
            [self showSeparatorLine:self.sendMessageCell];
            [self setupVoipCallCell:width];
        } else if([[WFCCNetworkService sharedInstance].userId isEqualToString:self.userId]) {
            
        } else {
            self.addFriendCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
            for (UIView *subView in self.addFriendCell.subviews) {
                [subView removeFromSuperview];
            }
            UIView *host = [self hostViewOfCell:self.addFriendCell];
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 8, [self buttonWidthInHostView:host fallback:width] - 40, 40)];
            btn.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [btn setTitle:WFCString(@"AddFriend") forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor greenColor]];
            [btn addTarget:self action:@selector(onAddFriendBtn:) forControlEvents:UIControlEventTouchDown];
            btn.layer.cornerRadius = 5.f;
            btn.layer.masksToBounds = YES;
            if (@available(iOS 14, *)) {
                [self.addFriendCell.contentView addSubview:btn];
            } else {
                [self.addFriendCell addSubview:btn];
            }
            if(self.fromConversation.type == Group_Type) {
                WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.fromConversation.target refresh:NO];
                if(!groupInfo.privateChat) {
                    [self setupSendMessageCell:width];
                }
            } else if(self.sourceType == FriendSource_Org)  {
                //组织通讯录用户允许不添加好友聊天
                [self setupSendMessageCell:width];
                [self showSeparatorLine:self.sendMessageCell];
                [self setupVoipCallCell:width];
                [self showSeparatorLine:self.sendMessageCell];
            }
        }
    }
    [self.tableView reloadData];
}

//整行按钮实际挂在哪个视图上：iOS 14 起是 contentView，更早是 cell 本身。
//autoresizing 是相对父视图算的，所以起始宽度也得取自同一个视图。
- (UIView *)hostViewOfCell:(UITableViewCell *)cell {
    if (@available(iOS 14, *)) {
        return cell.contentView;
    }
    return cell;
}

- (CGFloat)buttonWidthInHostView:(UIView *)host fallback:(CGFloat)fallback {
    CGFloat width = host.bounds.size.width;
    return width > 0 ? width : fallback;
}

- (void)setupSendMessageCell:(CGFloat)width {
    self.sendMessageCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    for (UIView *subView in self.sendMessageCell.subviews) {
        [subView removeFromSuperview];
    }
    //按钮铺满整行、内容居中，所以宽度必须是行宽本身。loadData 有可能在页面还没上屏时跑
    //（viewDidLoad 里就调了一次），那时 width 退回的是屏幕宽 —— iPad 右栏比屏幕窄，
    //按屏幕宽排出来的按钮中心就偏到栏外去了，「发送消息」「视频聊天」于是不居中。
    //改成按承载它的那个视图起排，再配上 FlexibleWidth，真实行宽下来时自己纠回来。
    //iPhone 上行宽恒等于屏幕宽，最终取值与改之前一致。
    UIView *host = [self hostViewOfCell:self.sendMessageCell];
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, [self buttonWidthInHostView:host fallback:width], 50)];
    btn.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [btn setImage:[WFCUImage imageNamed:@"message"] forState:UIControlStateNormal];
    btn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10);
    [btn setTitle:WFCString(@"SendMessage") forState:UIControlStateNormal];
    [btn setTitleColor:[WFCUConfigManager globalManager].textColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleMedium size:16];
    [btn addTarget:self action:@selector(onSendMessageBtn:) forControlEvents:UIControlEventTouchDown];
    if (@available(iOS 14, *)) {
        [self.sendMessageCell.contentView addSubview:btn];
    } else {
        [self.sendMessageCell addSubview:btn];
    }
}

- (void)setupVoipCallCell:(CGFloat)width {
#if WFCU_SUPPORT_VOIP
        self.voipCallCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        for (UIView *subView in self.voipCallCell.subviews) {
            [subView removeFromSuperview];
        }
        //与 setupSendMessageCell: 同一条，见那里的注释
        UIView *host = [self hostViewOfCell:self.voipCallCell];
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, [self buttonWidthInHostView:host fallback:width], 50)];
        btn.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [btn setImage:[WFCUImage imageNamed:@"video"] forState:UIControlStateNormal];
        btn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10);
        [btn setTitle:WFCString(@"VOIPCall") forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(onVoipCallBtn:) forControlEvents:UIControlEventTouchDown];
        [btn setTitleColor:[UIColor colorWithHexString:@"0x5b6e8e"] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleMedium size:16];
        if (@available(iOS 14, *)) {
            [self.voipCallCell.contentView addSubview:btn];
        } else {
            [self.voipCallCell addSubview:btn];
        }
#endif
}

- (UITableViewCell *)moreCell {
    if(!_moreCell) {
        _moreCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"more_cell"];
        _moreCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        _moreCell.textLabel.text = WFCString(@"More");
    }
    return _moreCell;
}

- (UIEdgeInsets)hiddenSeparatorLine:(UITableViewCell *)cell {
    return cell.separatorInset = UIEdgeInsetsMake(self.view.frame.size.width, 0, 0, 0);
}

- (void)showSeparatorLine:(UITableViewCell *)cell {
    cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)onViewPortrait:(id)sender {
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.displaySelectionButtons = NO;
    browser.alwaysShowControls = NO;
    browser.zoomPhotosToFill = YES;
    browser.enableGrid = NO;
    browser.startOnGrid = NO;
    browser.enableSwipeToDismiss = NO;
    browser.autoPlayOnAppear = NO;
    [browser setCurrentPhotoIndex:0];
    [self.navigationController pushViewController:browser animated:YES];
}

- (void)momentClick {
    Class cls = NSClassFromString(@"SDTimeLineTableViewController");
    UIViewController *vc = [[cls alloc] init];
    [vc performSelector:@selector(setUserId:) withObject:self.userId]; 
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)panCellClick {
    WFCUPanViewController *vc = [[WFCUPanViewController alloc] init];
    vc.viewMode = WFCUPanViewModeUserPublic;
    vc.targetUserId = self.userId;
    vc.targetUserName = self.userInfo.displayName;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onSendMessageBtn:(id)sender {
    NSString *dialinRobotId = [WFCUConfigManager globalManager].dialinRobotId;
    if (dialinRobotId.length && [dialinRobotId isEqualToString:self.userId]) {
        void (^handler)(UIViewController *) = [WFCUConfigManager globalManager].dialinRobotHandler;
        if (handler) {
            handler(self);
            return;
        }
    }
    WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
    mvc.conversation = [WFCCConversation conversationWithType:Single_Type target:self.userId line:0];
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isKindOfClass:[WFCUMessageListViewController class]]) {
            WFCUMessageListViewController *old = (WFCUMessageListViewController*)vc;
            if (old.conversation.type == Single_Type && [old.conversation.target isEqualToString:self.userId]) {
                [self.navigationController popToViewController:vc animated:YES];
                return;
            }
        }
    }
    UINavigationController *nav = self.navigationController;
    [self.navigationController popToRootViewControllerAnimated:NO];
    mvc.hidesBottomBarWhenPushed = YES;
    [nav pushViewController:mvc animated:YES];
}

- (void)onVoipCallBtn:(id)sender {
#if WFCU_SUPPORT_VOIP
    __weak typeof(self)ws = self;
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *actionVoice = [UIAlertAction actionWithTitle:WFCString(@"VoiceCall") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        WFCCConversation *conversation = [WFCCConversation conversationWithType:Single_Type target:ws.userInfo.userId line:0];
        [self startCall:@[ws.userInfo.userId] isMulti:NO conversation:conversation audioOnly:YES];
    }];
    
    UIAlertAction *actionVideo = [UIAlertAction actionWithTitle:WFCString(@"VideoCall") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        WFCCConversation *conversation = [WFCCConversation conversationWithType:Single_Type target:ws.userInfo.userId line:0];
        [self startCall:@[ws.userInfo.userId] isMulti:NO conversation:conversation audioOnly:NO];
    }];
    
    //把action添加到actionSheet里
    [actionSheet addAction:actionVoice];
    [actionSheet addAction:actionVideo];
    [actionSheet addAction:actionCancel];
    
    
    //相当于之前的[actionSheet show];
    [self presentViewController:actionSheet animated:YES completion:nil];
#endif
}

#if WFCU_SUPPORT_VOIP
- (void)startCall:(NSArray<NSString *> *)targetIds isMulti:(BOOL)isMulti conversation:(WFCCConversation *)conversation audioOnly:(BOOL)isAudioOnly {
    [WFCUUtilities checkRecordOrCameraPermission:YES complete:^(BOOL granted) {
        if(granted) {
            if(isAudioOnly) {
                UIViewController *videoVC;
                if(isMulti) {
                    videoVC = [[WFCUMultiVideoViewController alloc] initWithTargets:targetIds conversation:conversation audioOnly:isAudioOnly];
                } else {
                    videoVC = [[WFCUVideoViewController alloc] initWithTargets:targetIds conversation:conversation audioOnly:isAudioOnly];
                }
                [[WFAVEngineKit sharedEngineKit] presentViewController:videoVC];
            } else {
                [WFCUUtilities checkRecordOrCameraPermission:NO complete:^(BOOL granted) {
                    if(granted) {
                        UIViewController *videoVC;
                        if(isMulti) {
                            videoVC = [[WFCUMultiVideoViewController alloc] initWithTargets:targetIds conversation:conversation audioOnly:isAudioOnly];
                        } else {
                            videoVC = [[WFCUVideoViewController alloc] initWithTargets:targetIds conversation:conversation audioOnly:isAudioOnly];
                        }
                        [[WFAVEngineKit sharedEngineKit] presentViewController:videoVC];
                    }
                } viewController:self];
            }
        }
    } viewController:self];
}
#endif

- (void)onAddFriendBtn:(id)sender {
    WFCUVerifyRequestViewController *vc = [[WFCUVerifyRequestViewController alloc] init];
    vc.userId = self.userId;
    vc.sourceType = self.sourceType;
    vc.sourceTargetId = self.sourceTargetId;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource<NSObject>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.headerCells.count;
    } else if (section == 1) {
        int count = 1;//more
        if (self.momentCell) {
            count++;
        }
        if (self.panCell) {
            count++;
        }
        
        count+= self.organizationIds.count;
        
        return count;
    } else if(section == 2) {
        return self.cells.count;
    } else {
        if (self.sendMessageCell) {
            int i = 1;
            if (self.voipCallCell) {
                i++;
            }
            if(self.addFriendCell) {
                i++;
            }
            return i;
        } else {
            return 1;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"section:%ld",(long)indexPath.section);
    if (indexPath.section == 0) {
       return self.headerCells[indexPath.row];
    } else if (indexPath.section == 1) {
        if(self.momentCell && indexPath.row == 0) {
            return self.momentCell;
        }
        
        int index = indexPath.row;
        if(self.momentCell)
            index--;
        
        if(self.panCell && index == 0) {
            return self.panCell;
        }
        if(self.panCell)
            index--;
        
        if(index < self.organizationIds.count) {
            NSInteger orgId = [self.organizationIds[index] integerValue];
            WFCUOrganization *org = [[WFCUOrganizationCache sharedCache] getOrganization:orgId refresh:NO];
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"org_cell"];
            if(!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"org_cell"];
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = @"部门";
            cell.detailTextLabel.text = org.name;
            return cell;
        } else {
            return self.moreCell;
        }
    } else if (indexPath.section == 2) {
        return self.cells[indexPath.row];
    } else {
        if (self.sendMessageCell) {
            if (indexPath.row == 0) {
                return self.sendMessageCell;
            } else if(indexPath.row == 1) {
                if(self.voipCallCell) {
                    return self.voipCallCell;
                }
            }
            return self.addFriendCell;
        } else {
            return self.addFriendCell;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.sendMessageCell || self.voipCallCell || self.addFriendCell) {
        return 4;
    } else {
        if(self.cells.count > 0)
            return 3;
        return 2;
    }
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section != 0) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 10)];
        view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        return view;
    } else {
        return nil;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else {
        return 10;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @" ";
}

//「发送消息」「视频聊天」「加好友」「设置备注」这几颗按钮和头部那颗星，
//frame 都是在 loadData（viewDidLoad 里就跑了一次）那一刻按当时拿到的宽度定的，
//页面还没上屏时拿到的会是屏幕宽 —— 双栏下右栏比屏幕窄，整行按钮按屏幕宽排出来
//中心就偏到栏外去了（缺陷 #24）。行宽到 willDisplayCell: 才真正定下来，
//按真实行宽把这几处重排一次；之后旋转/分屏宽度再变，也会再走这里。
//iPhone 上行宽恒等于屏幕宽，整段是 no-op。
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![WFCUPadUtility isPad] || tableView != self.tableView) {
        return;
    }
    UIView *host = [self hostViewOfCell:cell];
    CGFloat rowWidth = host.bounds.size.width;
    if (rowWidth <= 0) {
        return;
    }
    for (UIView *subview in host.subviews) {
        if (![subview isKindOfClass:[UIButton class]]) {
            continue;
        }
        CGRect frame = subview.frame;
        if (cell == self.sendMessageCell || cell == self.voipCallCell) {
            //铺满整行、内容居中
            frame.origin.x = 0;
            frame.size.width = rowWidth;
        } else if (cell == self.addFriendCell) {
            //左右各留 20
            frame.origin.x = 20;
            frame.size.width = rowWidth - 40;
        } else if (cell == self.momentCell) {
            //「朋友圈」：左边 16，与 loadData 里同一个算法
            frame.origin.x = 16;
            frame.size.width = rowWidth - 100;
        } else if (indexPath.section == 0 && indexPath.row == 1) {
            //「设置备注」：左边 16、右边给 accessory 留 60，内容靠左
            frame.origin.x = 16;
            frame.size.width = rowWidth - 16 - 60;
        }
        subview.frame = frame;
    }
    if (indexPath.section == 0 && indexPath.row == 0 && self.starLabel) {
        //头部右上角那颗星贴行右缘
        CGRect frame = self.starLabel.frame;
        frame.origin.x = rowWidth - 16 - 20;
        self.starLabel.frame = frame;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([tableView cellForRowAtIndexPath:indexPath] == self.userMessagesCell) {
        WFCUUserMessageListViewController *vc = [[WFCUUserMessageListViewController alloc] init];
        vc.userId = self.userId;
        vc.conversation = self.fromConversation;
        [self.navigationController pushViewController:vc animated:YES];
    } else if([tableView cellForRowAtIndexPath:indexPath] == self.moreCell) {
        WFCUProfileMoreTableViewController *moreVC = [[WFCUProfileMoreTableViewController alloc] init];
        moreVC.userId = self.userId;
        [[WFCCIMService sharedWFCIMService] getCommonGroups:self.userId success:^(NSArray<NSString *> *groupIds) {
            moreVC.commonGroupIds = groupIds;
        } error:^(int error_code) {
            
        }];
        [self.navigationController pushViewController:moreVC animated:YES];
    } else if(indexPath.section == 1) {
        if(self.momentCell && indexPath.row == 0) {
            //click momentCell
            return;
        }
        
        int index = (int)indexPath.row;
        if(self.momentCell)
            index--;
        
        if(self.panCell && index == 0) {
            [self panCellClick];
            return;
        }
        if(self.panCell)
            index--;
        
        if(index < self.organizationIds.count) {
            NSInteger orgId = [self.organizationIds[index] integerValue];
            NSArray<WFCUOrgRelationship *> *rs = [[WFCUOrganizationCache sharedCache] getRelationship:self.userId refresh:YES];
            __block NSInteger index = orgId;
            NSMutableArray *ids = [[NSMutableArray alloc] init];
            while (index) {
                [ids insertObject:@(index) atIndex:0];
                [rs enumerateObjectsUsingBlock:^(WFCUOrgRelationship * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if(obj.organizationId == index) {
                        index = obj.parentOrganizationId;
                        *stop = YES;
                    }
                }];
            }
            WFCUOrganizationViewController *orgVC = [[WFCUOrganizationViewController alloc] init];
            orgVC.organizationIds = ids;
            orgVC.hidesBottomBarWhenPushed = YES;
            orgVC.isPushed = YES;
            [self.navigationController pushViewController:orgVC animated:YES];
        }
    }
}
#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return 100;
        } else {
            return 50;
        }
    } else if(indexPath.section == 1) {
        return 50;
    } else if(indexPath.section == 2) {
        if (self.momentCell) {
            return 120;
        } else {
            return 50;
        }
    }  else {
        return 50;
    }
}

- (void)setFriendNote {
    WFCUGeneralModifyViewController *gmvc = [[WFCUGeneralModifyViewController alloc] init];
    NSString *previousAlias = [[WFCCIMService sharedWFCIMService] getFriendAlias:self.userId];
    gmvc.defaultValue = previousAlias;
    gmvc.titleText = @"设置备注";
    gmvc.canEmpty = YES;
    __weak typeof(self)ws = self;
    gmvc.tryModify = ^(NSString *newValue, void (^result)(BOOL success)) {
        if (![newValue isEqualToString:previousAlias]) {
            [[WFCCIMService sharedWFCIMService] setFriend:self.userId alias:newValue success:^{
                result(YES);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [ws loadData];
                });
            } error:^(int error_code) {
                result(NO);
            }];
        }
    };
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:gmvc];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)setFavUser {
    BOOL isFav = [[WFCCIMService sharedWFCIMService] isFavUser:self.userId];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Processing");
    [hud showAnimated:YES];
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] setFavUser:self.userId fav:!isFav success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];

            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = WFCString(@"ProcessDone");
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [ws loadData];
            });
        });
    } error:^(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];

            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = WFCString(@"ProcessFailure");
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        });
    }];
}

#pragma mark - MWPhotoBrowserDelegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return 1;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    MWPhoto *photo = [MWPhoto photoWithURL:[NSURL URLWithString:self.userInfo.portrait]];
    return photo;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    return nil;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    return NO;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    NSLog(@"Photo at index %lu selected %@", (unsigned long)index, selected ? @"YES" : @"NO");
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    NSLog(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
