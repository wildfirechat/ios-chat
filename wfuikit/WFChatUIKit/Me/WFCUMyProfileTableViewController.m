//
//  WFCUProfileTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/22.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUMyProfileTableViewController.h"
#import "SDWebImage.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUMessageListViewController.h"
#import "MBProgressHUD.h"
#import "WFCUMyPortraitViewController.h"
#import "WFCUModifyMyProfileViewController.h"
#import "QrCodeHelper.h"
#import "WFCUConfigManager.h"


@interface WFCUMyProfileTableViewController () <UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic)UIImageView *portraitView;
@property (nonatomic, strong)UITableView *tableView;

@property (nonatomic, strong)NSMutableArray<UITableViewCell *> *cells1;
@property (nonatomic, strong)NSMutableArray<UITableViewCell *> *cells2;
@property (nonatomic, strong)WFCCUserInfo *userInfo;
@end

@implementation WFCUMyProfileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.tableHeaderView = nil;
    
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    
    self.title = WFCString(@"MyInformation");
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    WFCCUserInfo *userInfo = notification.userInfo[@"userInfo"];
    if ([[WFCCNetworkService sharedInstance].userId isEqualToString:userInfo.userId]) {
        [self loadData:NO];
    }
}

- (NSString *)getGenderString:(int)gender {
    if (gender == 0) {
        return @"";
    } else if(gender == 1) {
        return WFCString(@"Male");
    } else if(gender == 2) {
        return WFCString(@"Female");
    }
    
    return WFCString(@"Other");
}

- (void)loadData:(BOOL)refresh {
    self.cells1 = [[NSMutableArray alloc] init];
    self.cells2 = [[NSMutableArray alloc] init];
    self.userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:refresh];
    
    UITableViewCell *headerCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    for (UIView *subView in headerCell.subviews) {
        [subView removeFromSuperview];
    }
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    
    self.portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(width - 104, 6, 64, 64)];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onViewPortrait:)];
    [self.portraitView addGestureRecognizer:tap];
    self.portraitView.userInteractionEnabled = YES;
    
    
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[self.userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
    
    [headerCell addSubview:self.portraitView];
    headerCell.tag = -1;
    headerCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [self addLabel:WFCString(@"Portrait") onCell:headerCell isHeaderCell:YES isLeft:YES];
    [self.cells1 addObject:headerCell];

    UITableViewCell *cell = [self getAttrCell:WFCString(@"Nickname") rightText:self.userInfo.displayName mutable:YES];
    cell.tag = Modify_DisplayName;
    [self.cells1 addObject:cell];
    
    cell = [self getAttrCell:WFCString(@"QRCode") rightText:@"" mutable:YES];
    cell.tag = 1000;
    [self.cells1 addObject:cell];
    UIImage *qrcode = [UIImage imageNamed:@"qrcode"];
    
    UIImageView *qrview = [[UIImageView alloc] initWithFrame:CGRectMake(width - 56, 5, 30, 30)];
    qrview.image = qrcode;
    [cell addSubview:qrview];
    

//    cell = [self getAttrCell:@"账号" rightText:self.userInfo.name mutable:NO];
//    [self.cells1 addObject:cell];

    cell = [self getAttrCell:WFCString(@"Mobile") rightText:self.userInfo.mobile mutable:YES];
    cell.tag = Modify_Mobile;
    [self.cells2 addObject:cell];

    cell = [self getAttrCell:WFCString(@"Gender") rightText: [self getGenderString:self.userInfo.gender] mutable:YES];
    cell.tag = Modify_Gender;
    [self.cells2 addObject:cell];

    cell = [self getAttrCell:WFCString(@"Email") rightText:self.userInfo.email mutable:YES];
    cell.tag = Modify_Email;
    [self.cells2 addObject:cell];

    cell = [self getAttrCell:WFCString(@"Address") rightText:self.userInfo.address mutable:YES];
    cell.tag = Modify_Address;
    [self.cells2 addObject:cell];

    cell = [self getAttrCell:WFCString(@"Company") rightText:self.userInfo.company mutable:YES];
    cell.tag = Modify_Company;
    [self.cells2 addObject:cell];

    cell = [self getAttrCell:WFCString(@"SocialAccount") rightText:self.userInfo.social mutable:YES];
    cell.tag = Modify_Social;
    [self.cells2 addObject:cell];
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadData:YES];
}

- (UITableViewCell *)getAttrCell:(NSString *)leftText rightText:(NSString *)rightText mutable:(BOOL)mutable {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
//    for (UIView *subView in cell.subviews) {
//        [subView removeFromSuperview];
//    }
    if (!mutable) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.tag = -1;
    [self addLabel:leftText onCell:cell isHeaderCell:NO isLeft:YES];
//    if (rightText.length == 0) {
//        rightText = @"未填写";
//    }
    [self addLabel:rightText onCell:cell isHeaderCell:NO isLeft:NO];
    return cell;
}

- (void)addLabel:(NSString *)titleStr onCell:(UITableViewCell *)cell isHeaderCell:(BOOL)isHeaderCell isLeft:(BOOL)left {
    UILabel *title ;
    if (isHeaderCell) {
        title = [[UILabel alloc] initWithFrame:CGRectMake(8, 4, 68, 68)];
    } else {
        if (left) {
            title = [[UILabel alloc] initWithFrame:CGRectMake(8, 2, 72, 36)];
        } else {
            CGFloat width = [UIScreen mainScreen].bounds.size.width;
            title = [[UILabel alloc] initWithFrame:CGRectMake(88, 2, width - 108 - 28, 36)];
        }
    }
    
    [title setFont:[UIFont systemFontOfSize:16]];
    [title setText:titleStr];
    if (left) {
        [title setTextAlignment:NSTextAlignmentLeft];
        title.tag = 1;
    } else {
        [title setTextAlignment:NSTextAlignmentRight];
        title.tag = 2;
    }
    
    [cell addSubview:title];
}

- (void)onViewPortrait:(id)sender {
    WFCUMyPortraitViewController *pvc = [[WFCUMyPortraitViewController alloc] init];
    pvc.userId = self.userInfo.userId;
    [self.navigationController pushViewController:pvc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDataSource<NSObject>
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.cells1.count;
    }
    return self.cells2.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return self.cells1[indexPath.row];
    }
    return self.cells2[indexPath.row];
}

- (void)showMyQrCode {
    if (gQrCodeDelegate) {
        [gQrCodeDelegate showQrCodeViewController:self.navigationController type:QRType_User target:[WFCCNetworkService sharedInstance].userId];
    }
}
#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *vc;
    if (indexPath.row == 0 && indexPath.section == 0) {
        WFCUMyPortraitViewController *pvc = [[WFCUMyPortraitViewController alloc] init];
        pvc.userId = [WFCCNetworkService sharedInstance].userId;
        [self.navigationController pushViewController:pvc animated:YES];
    } else {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell.tag == 1000) {
            [self showMyQrCode];
            return;
        }
        if (cell.tag < 0) {
            return;
        }
        
        if (cell.tag == Modify_Gender) {
            [self sexAlterView];
            return;
        }
        
        WFCUModifyMyProfileViewController *mpvc = [[WFCUModifyMyProfileViewController alloc] init];
        mpvc.modifyType = cell.tag;
        __weak typeof(self)ws = self;
        mpvc.onModified = ^(NSInteger modifyType, NSString *value) {
            NSArray *cells =ws.cells2;
            if (indexPath.section == 0) {
                cells = ws.cells1;
            }
            for (UITableViewCell *cell in cells) {
                if (cell.tag == modifyType) {
                    for (UIView *view in cell.subviews) {
                        if (view.tag == 2) {
                            UILabel *label = (UILabel *)view;
                            label.text = value;
                        }
                    }
                }
            }
        };
        [self.navigationController pushViewController:mpvc animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0 && indexPath.section == 0) {
        return 76;
    } else {
        return 40 ;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @" ";
}

- (void)updateGender:(int)gender {
    __weak typeof(self) ws = self;
    
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Updating");
    [hud showAnimated:YES];
    
    [[WFCCIMService sharedWFCIMService] modifyMyInfo:@{@(Modify_Gender):[NSString stringWithFormat:@"%d", gender]} success:^{
        [hud hideAnimated:NO];
        for (UITableViewCell *cell in ws.cells2) {
            if (cell.tag == Modify_Gender) {
                for (UIView *v in cell.subviews) {
                    if ([v isKindOfClass:[UILabel class]] && v.tag == 2) {
                        UILabel *label = (UILabel *)v;
                        label.text = [ws getGenderString:gender];
                        break;
                    }
                }
                break;
            }
        }
    } error:^(int error_code) {
        [hud hideAnimated:NO];
        
        hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = WFCString(@"UpdateFailure");
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
    }];
}

- (void)sexAlterView{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Male") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self updateGender:1];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Female") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        [self updateGender:2];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Other") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        [self updateGender:3];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
