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

@interface WFCUProfileTableViewController () <UITableViewDelegate, UITableViewDataSource, MWPhotoBrowserDelegate>
@property (strong, nonatomic)UIImageView *portraitView;
@property (strong, nonatomic)UILabel *aliasLabel;
@property (strong, nonatomic)UILabel *displayNameLabel;
@property (strong, nonatomic)UILabel *userNameLabel;
@property (strong, nonatomic)UILabel *starLabel;
@property (strong, nonatomic)UITableViewCell *headerCell;


@property (strong, nonatomic)UILabel *mobileLabel;
@property (strong, nonatomic)UILabel *emailLabel;
@property (strong, nonatomic)UILabel *addressLabel;
@property (strong, nonatomic)UILabel *companyLabel;
@property (strong, nonatomic)UILabel *socialLabel;

@property (strong, nonatomic)UITableViewCell *sendMessageCell;
@property (strong, nonatomic)UITableViewCell *voipCallCell;
@property (strong, nonatomic)UITableViewCell *addFriendCell;
@property (strong, nonatomic)UITableViewCell *momentCell;
@property (strong, nonatomic)UITableViewCell *moreCell;
@property (nonatomic, strong)UITableViewCell *userMessagesCell;

@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<UITableViewCell *> *cells;
@property (nonatomic, strong)NSMutableArray<UITableViewCell *> *headerCells;

@property (nonatomic, strong)WFCCUserInfo *userInfo;
@end

@implementation WFCUProfileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = WFCString(@"UserInfomation");
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kUserInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSArray<WFCCUserInfo *> *userInfoList = note.userInfo[@"userInfoList"];
        for (WFCCUserInfo *userInfo in userInfoList) {
            if ([ws.userId isEqualToString:userInfo.userId]) {
                WFCCUserInfo *userInfo = note.userInfo[@"userInfo"];
                ws.userInfo = userInfo;
                [ws loadData];
                break;
            }
        }
    }];
    
    self.userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.userId refresh:YES];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"..." style:UIBarButtonItemStyleDone target:self action:@selector(onRightBtn:)];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.1)];


    [self loadData];
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
            UIAlertAction *cancelStarAction = [UIAlertAction actionWithTitle:WFCString(@"Star") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [ws setFavUser];
            }];
            [actionSheet addAction:cancelStarAction];
        } else {
            UIAlertAction *setStarAction = [UIAlertAction actionWithTitle:WFCString(@"Unstar") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [ws setFavUser];
            }];
            [actionSheet addAction:setStarAction];
        }
    }
    
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)loadData {
    self.cells = [[NSMutableArray alloc] init];
    
    self.headerCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    for (UIView *subView in self.headerCell.contentView.subviews) {
        [subView removeFromSuperview];
    }
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    
    self.portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 14, 58, 58)];
    
    self.portraitView.layer.cornerRadius = 10;
    self.portraitView.layer.masksToBounds = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onViewPortrait:)];
    [self.portraitView addGestureRecognizer:tap];
    self.portraitView.userInteractionEnabled = YES;
    
    
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[self.userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
    
    NSString *alias = [[WFCCIMService sharedWFCIMService] getFriendAlias:self.userId];
    if (alias.length) {
        self.aliasLabel = [[UILabel alloc] initWithFrame:CGRectMake(94, 8, width - 64 - 8, 21)];
        self.aliasLabel.text = alias;
        
        self.displayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(94, 32, width - 94 - 8, 21)];
        self.displayNameLabel.text = self.userInfo.displayName;
        
        self.userNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(94, 60, width - 94 - 8, 11)];
        self.userNameLabel.text = [NSString stringWithFormat:@"野火号:%@", self.userInfo.name];
        self.userNameLabel.font = [UIFont systemFontOfSize:12];
        self.userNameLabel.textColor = [UIColor grayColor];
    } else {
        self.aliasLabel = [[UILabel alloc] initWithFrame:CGRectZero];

        self.displayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(94, 23, width - 94 - 8, 21)];
        self.displayNameLabel.text = self.userInfo.displayName;
        self.displayNameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:20];
        
        self.userNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(94, 50, width - 94 - 8, 21)];
        self.userNameLabel.text = [NSString stringWithFormat:@"野火号:%@", self.userInfo.name];
        self.userNameLabel.font = [UIFont systemFontOfSize:12];
        self.userNameLabel.textColor = [UIColor grayColor];
    }
    
    if ([[WFCCIMService sharedWFCIMService] isFavUser:self.userId]) {
        self.starLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 16 - 20, self.displayNameLabel.frame.origin.y, 20, 20)];
        self.starLabel.text = @"☆";
        self.starLabel.font = [UIFont systemFontOfSize:18];
        self.starLabel.textColor = [UIColor yellowColor];
        
        [self.headerCell.contentView addSubview:self.starLabel];
    }
    
    [self.headerCell.contentView addSubview:self.portraitView];
    [self.headerCell.contentView addSubview:self.displayNameLabel];
    [self.headerCell.contentView addSubview:self.userNameLabel];
    [self.headerCell.contentView addSubview:self.aliasLabel];
    self.headerCells = [NSMutableArray new];
    [self.headerCells addObject:self.headerCell];
    
    if (self.userInfo.type == 1) {
        [self setupSendMessageCell:width];
    } else {
        if ([[WFCCIMService sharedWFCIMService] isMyFriend:self.userId]) {
            UITableViewCell *alisaCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"setAlisa"];
            alisaCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 16 - 60, 50)];
            [btn setTitle:WFCString(@"ModifyNickname") forState:UIControlStateNormal];
            [btn setTitleColor:[WFCUConfigManager globalManager].textColor forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:16];
            [btn addTarget:self action:@selector(setFriendNote) forControlEvents:UIControlEventTouchUpInside];
            btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            [alisaCell.contentView addSubview:btn];
            [self showSeparatorLine:alisaCell];
            [self.headerCells addObject:alisaCell];
        }
        
        if (self.fromConversation.type == Group_Type) {
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
                momentButton.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:16];
                momentButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                [momentButton addTarget:self action:@selector(momentClick) forControlEvents:UIControlEventTouchUpInside];
                if (@available(iOS 14, *)) {
                    [self.momentCell.contentView addSubview:momentButton];
                } else {
                    [self.momentCell addSubview:momentButton];
                }
                self.momentCell.selectionStyle = UITableViewCellSelectionStyleNone;
                self.momentCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        }
        
        if ([[WFCCIMService sharedWFCIMService] isMyFriend:self.userId]) {
            [self setupSendMessageCell:width];
            [self showSeparatorLine:self.sendMessageCell];
            
    #if WFCU_SUPPORT_VOIP
            self.voipCallCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
            for (UIView *subView in self.voipCallCell.subviews) {
                [subView removeFromSuperview];
            }
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, width, 50)];
            [btn setImage:[WFCUImage imageNamed:@"video"] forState:UIControlStateNormal];
            btn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10);
            [btn setTitle:WFCString(@"VOIPCall") forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(onVoipCallBtn:) forControlEvents:UIControlEventTouchDown];
            [btn setTitleColor:[UIColor colorWithHexString:@"0x5b6e8e"] forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:16];
            if (@available(iOS 14, *)) {
                [self.voipCallCell.contentView addSubview:btn];
            } else {
                [self.voipCallCell addSubview:btn];
            }
    #endif
        } else if([[WFCCNetworkService sharedInstance].userId isEqualToString:self.userId]) {
            
        } else {
            self.addFriendCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
            for (UIView *subView in self.addFriendCell.subviews) {
                [subView removeFromSuperview];
            }
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 8, width - 40, 40)];
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
            }
        }
    }
    [self.tableView reloadData];
}

- (void)setupSendMessageCell:(CGFloat)width {
    self.sendMessageCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    for (UIView *subView in self.sendMessageCell.subviews) {
        [subView removeFromSuperview];
    }
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, width, 50)];
    [btn setImage:[WFCUImage imageNamed:@"message"] forState:UIControlStateNormal];
    btn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10);
    [btn setTitle:WFCString(@"SendMessage") forState:UIControlStateNormal];
    [btn setTitleColor:[WFCUConfigManager globalManager].textColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:16];
    [btn addTarget:self action:@selector(onSendMessageBtn:) forControlEvents:UIControlEventTouchDown];
    if (@available(iOS 14, *)) {
        [self.sendMessageCell.contentView addSubview:btn];
    } else {
        [self.sendMessageCell addSubview:btn];
    }
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


- (void)onSendMessageBtn:(id)sender {
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
        WFCUVideoViewController *videoVC = [[WFCUVideoViewController alloc] initWithTargets:@[ws.userInfo.userId] conversation:conversation audioOnly:YES];
        [[WFAVEngineKit sharedEngineKit] presentViewController:videoVC];
    }];
    
    UIAlertAction *actionVideo = [UIAlertAction actionWithTitle:WFCString(@"VideoCall") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        WFCCConversation *conversation = [WFCCConversation conversationWithType:Single_Type target:ws.userInfo.userId line:0];
        WFCUVideoViewController *videoVC = [[WFCUVideoViewController alloc] initWithTargets:@[ws.userInfo.userId] conversation:conversation audioOnly:NO];
        [[WFAVEngineKit sharedEngineKit] presentViewController:videoVC];
    }];
    
    //把action添加到actionSheet里
    [actionSheet addAction:actionVoice];
    [actionSheet addAction:actionVideo];
    [actionSheet addAction:actionCancel];
    
    
    //相当于之前的[actionSheet show];
    [self presentViewController:actionSheet animated:YES completion:nil];
#endif
}

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
        if (self.momentCell) {
            return 2;
        } else {
            return 1;
        }
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
