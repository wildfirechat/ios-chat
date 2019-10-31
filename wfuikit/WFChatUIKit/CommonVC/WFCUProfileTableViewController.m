//
//  WFCUProfileTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/22.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUProfileTableViewController.h"
#import "SDWebImage.h"
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

@interface WFCUProfileTableViewController () <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>
@property (strong, nonatomic)UIImageView *portraitView;
@property (strong, nonatomic)UILabel *aliasLabel;
@property (strong, nonatomic)UILabel *displayNameLabel;
@property (strong, nonatomic)UILabel *userNameLabel;
@property (strong, nonatomic)UITableViewCell *headerCell;


@property (strong, nonatomic)UILabel *mobileLabel;
@property (strong, nonatomic)UILabel *emailLabel;
@property (strong, nonatomic)UILabel *addressLabel;
@property (strong, nonatomic)UILabel *companyLabel;
@property (strong, nonatomic)UILabel *socialLabel;

@property (strong, nonatomic)UITableViewCell *sendMessageCell;
@property (strong, nonatomic)UITableViewCell *voipCallCell;
@property (strong, nonatomic)UITableViewCell *addFriendCell;

@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<UITableViewCell *> *cells;

@property (nonatomic, strong)WFCCUserInfo *userInfo;
@end

@implementation WFCUProfileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kUserInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([ws.userId isEqualToString:note.object]) {
            WFCCUserInfo *userInfo = note.userInfo[@"userInfo"];
            ws.userInfo = userInfo;
            [ws loadData];
            NSLog(@"reload user info %@", ws.userInfo.userId);
        }
    }];
    
    self.userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.userId refresh:YES];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"..." style:UIBarButtonItemStyleDone target:self action:@selector(onRightBtn:)];
    
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self loadData];
}

- (void)onRightBtn:(id)sender {
    NSString *title;
    UIActionSheet *actionSheet;
    if ([[WFCCIMService sharedWFCIMService] isMyFriend:self.userId]) {
        title = WFCString(@"DeleteFriend");
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:WFCString(@"Cancel") destructiveButtonTitle:title otherButtonTitles:WFCString(@"SetAlias"), nil];
    } else {
        title = WFCString(@"AddFriend");
        if ([[WFCCIMService sharedWFCIMService] isBlackListed:self.userId]) {
            title = WFCString(@"RemoveFromBlacklist");
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:WFCString(@"Cancel") destructiveButtonTitle:title otherButtonTitles:nil];
        } else {
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:WFCString(@"Cancel") destructiveButtonTitle:title otherButtonTitles:WFCString(@"Add2Blacklist"), nil];
        }
    }
    
    [actionSheet showInView:self.view];
}
- (void)loadData {
    self.cells = [[NSMutableArray alloc] init];
    
    self.headerCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    for (UIView *subView in self.headerCell.subviews) {
        [subView removeFromSuperview];
    }
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    
    self.portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 48, 48)];
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onViewPortrait:)];
    [self.portraitView addGestureRecognizer:tap];
    self.portraitView.userInteractionEnabled = YES;
    
    
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[self.userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
    
    NSString *alias = [[WFCCIMService sharedWFCIMService] getFriendAlias:self.userId];
    if (alias.length) {
        self.aliasLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 8, width - 64 - 8, 21)];
        self.aliasLabel.text = alias;
        self.displayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 32, width - 64 - 8, 21)];
        self.displayNameLabel.text = self.userInfo.displayName;
        
        self.userNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 53, width - 64 - 8, 11)];
        self.userNameLabel.text = [NSString stringWithFormat:@"野火ID:%@", self.userInfo.name];
        self.userNameLabel.font = [UIFont systemFontOfSize:12];
        self.userNameLabel.textColor = [UIColor grayColor];
    } else {
        self.aliasLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.displayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 20, width - 64 - 8, 21)];
        self.displayNameLabel.text = self.userInfo.displayName;
        
        self.userNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 42, width - 64 - 8, 21)];
        self.userNameLabel.text = [NSString stringWithFormat:@"野火ID:%@", self.userInfo.name];
        self.userNameLabel.font = [UIFont systemFontOfSize:12];
        self.userNameLabel.textColor = [UIColor grayColor];
    }
    
    self.userNameLabel.hidden = YES;
    
    [self.headerCell addSubview:self.portraitView];
    [self.headerCell addSubview:self.displayNameLabel];
    [self.headerCell addSubview:self.userNameLabel];
    [self.headerCell addSubview:self.aliasLabel];
    
    if ([[WFCCIMService sharedWFCIMService] isMyFriend:self.userId]) {
        if (self.userInfo.mobile.length > 0) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
            cell.textLabel.text = self.userInfo.mobile;
            [self.cells addObject:cell];
        }
        
        if (self.userInfo.email.length > 0) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
            cell.textLabel.text = self.userInfo.email;
            [self.cells addObject:cell];
        }
        
        if (self.userInfo.address.length) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
            cell.textLabel.text = self.userInfo.address;
            [self.cells addObject:cell];
        }
        
        if (self.userInfo.company.length) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
            cell.textLabel.text = self.userInfo.company;
            [self.cells addObject:cell];
        }
        
        if (self.userInfo.social.length) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
            cell.textLabel.text = self.userInfo.social;
            [self.cells addObject:cell];
        }
    }
    
    if ([[WFCCIMService sharedWFCIMService] isMyFriend:self.userId]) {
        self.sendMessageCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        for (UIView *subView in self.sendMessageCell.subviews) {
            [subView removeFromSuperview];
        }
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 8, width - 40, 40)];
        [btn setTitle:WFCString(@"SendMessage") forState:UIControlStateNormal];
        [btn setBackgroundColor:[UIColor greenColor]];
        [btn addTarget:self action:@selector(onSendMessageBtn:) forControlEvents:UIControlEventTouchDown];
        btn.layer.cornerRadius = 5.f;
        btn.layer.masksToBounds = YES;
        [self.sendMessageCell addSubview:btn];

#if WFCU_SUPPORT_VOIP
        self.voipCallCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        for (UIView *subView in self.voipCallCell.subviews) {
            [subView removeFromSuperview];
        }
        btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 8, width - 40, 40)];
        [btn setTitle:WFCString(@"VOIPCall") forState:UIControlStateNormal];
        [btn setBackgroundColor:[UIColor blueColor]];
        [btn addTarget:self action:@selector(onVoipCallBtn:) forControlEvents:UIControlEventTouchDown];
        btn.layer.cornerRadius = 5.f;
        btn.layer.masksToBounds = YES;
        [self.voipCallCell addSubview:btn];
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
        [self.addFriendCell addSubview:btn];
        
    }
    [self.tableView reloadData];
}

- (void)onViewPortrait:(id)sender {
    WFCUMyPortraitViewController *pvc = [[WFCUMyPortraitViewController alloc] init];
    pvc.userId = self.userId;
    [self.navigationController pushViewController:pvc animated:YES];
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
        WFCUVideoViewController *videoVC = [[WFCUVideoViewController alloc] initWithTarget:ws.userInfo.userId conversation:conversation audioOnly:YES];
        [[WFAVEngineKit sharedEngineKit] presentViewController:videoVC];
    }];
    
    UIAlertAction *actionVideo = [UIAlertAction actionWithTitle:WFCString(@"VideoCall") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        WFCCConversation *conversation = [WFCCConversation conversationWithType:Single_Type target:ws.userInfo.userId line:0];
        WFCUVideoViewController *videoVC = [[WFCUVideoViewController alloc] initWithTarget:ws.userInfo.userId conversation:conversation audioOnly:NO];
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
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource<NSObject>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if(section == 1) {
        return self.cells.count;
    } else {
        if (self.sendMessageCell) {
            return 2;
        } else {
            return 1;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return self.headerCell;
    } else if (indexPath.section == 1) {
        return self.cells[indexPath.row];
    } else {
        if (self.sendMessageCell) {
            if (indexPath.row == 0) {
                return self.sendMessageCell;
            } else {
                return self.voipCallCell;
            }
        } else {
            return self.addFriendCell;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.sendMessageCell || self.voipCallCell || self.addFriendCell) {
        return 3;
    } else {
        return 2;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @" ";
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 64;
    } else if(indexPath.section == 1) {
        return 48;
    } else {
        return 56;
    }
}

#pragma mark -  UIActionSheetDelegate <NSObject>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[WFCCIMService sharedWFCIMService] isMyFriend:self.userId]) {
        //0, 删除好友，1 添加备注
        if(buttonIndex == 0) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.label.text = @"处理中...";
            [hud showAnimated:YES];
            [[WFCCIMService sharedWFCIMService] deleteFriend:self.userId success:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];
                    
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    hud.mode = MBProgressHUDModeText;
                    hud.label.text = @"处理成功";
                    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                    [hud hideAnimated:YES afterDelay:1.f];
                });
            } error:^(int error_code) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];
                    
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    hud.mode = MBProgressHUDModeText;
                    hud.label.text = @"处理失败";
                    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                    [hud hideAnimated:YES afterDelay:1.f];
                });
            }];
        } else if(buttonIndex == 1) {
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
    } else {
        if ([[WFCCIMService sharedWFCIMService] isBlackListed:self.userId]) {
            //0 取消屏蔽
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.label.text = @"处理中...";
            [hud showAnimated:YES];
            if (buttonIndex == 0) {
                [[WFCCIMService sharedWFCIMService] setBlackList:self.userId isBlackListed:NO success:^{
                    [hud hideAnimated:YES];
                    
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    hud.mode = MBProgressHUDModeText;
                    hud.label.text = @"处理成功";
                    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                    [hud hideAnimated:YES afterDelay:1.f];
                } error:^(int error_code) {
                    [hud hideAnimated:YES];
                    
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    hud.mode = MBProgressHUDModeText;
                    hud.label.text = @"处理失败";
                    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                    [hud hideAnimated:YES afterDelay:1.f];
                }];
            }
        } else {
            //0，添加好友；1 屏蔽用户
            if (buttonIndex == 0) {
                    WFCUVerifyRequestViewController *vc = [[WFCUVerifyRequestViewController alloc] init];
                    vc.userId = self.userId;
                    [self.navigationController pushViewController:vc animated:YES];
            } else if(buttonIndex == 1) {
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.label.text = @"处理中...";
                [hud showAnimated:YES];
                [[WFCCIMService sharedWFCIMService] setBlackList:self.userId isBlackListed:YES success:^{
                    [hud hideAnimated:YES];
                    
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    hud.mode = MBProgressHUDModeText;
                    hud.label.text = @"处理成功";
                    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                    [hud hideAnimated:YES afterDelay:1.f];
                } error:^(int error_code) {
                    [hud hideAnimated:YES];
                    
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    hud.mode = MBProgressHUDModeText;
                    hud.label.text = @"处理失败";
                    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                    [hud hideAnimated:YES afterDelay:1.f];
                }];
            }
        }
    }
    
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
