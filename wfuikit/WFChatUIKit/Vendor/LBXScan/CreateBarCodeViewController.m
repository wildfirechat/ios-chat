//
//  CreateBarCodeViewController.m
//  LBXScanDemo
//
//  Created by lbxia on 2017/1/5.
//  Copyright © 2017年 lbx. All rights reserved.
//

#import "CreateBarCodeViewController.h"
#import "LBXAlertAction.h"
#import "LBXScanNative.h"
#import "UIImageView+CornerRadius.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>


@interface CreateBarCodeViewController ()
@property (nonatomic, strong)UIImageView *logoView;
@property (nonatomic, strong)UILabel *nameLabel;
@property (nonatomic, strong) UIImageView* logoImgView;

@property (nonatomic, strong) UIView *qrView;
@property (nonatomic, strong) UIImageView* qrImgView;

@property (nonatomic, strong)NSString *qrStr;
@property (nonatomic, strong)NSString *qrLogo;
@property (nonatomic, strong)NSString *labelStr;

@property (nonatomic, strong)WFCCUserInfo *userInfo;
@property (nonatomic, strong)WFCCGroupInfo *groupInfo;

@property (nonatomic, strong)UIActivityIndicatorView *indicatorView;
@end

@implementation CreateBarCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"..." style:UIBarButtonItemStyleDone target:self action:@selector(onRightBtn:)];
    
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    __weak typeof(self) ws = self;
    if (self.qrType == QRType_User) {
        self.qrStr = [NSString stringWithFormat:@"wildfirechat://user/%@", self.target];
//        self.qrStr = [NSString stringWithFormat:@"wildfirechat://user/%@?from=%@", self.target, [WFCCNetworkService sharedInstance].userId];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];

        self.userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
    } else if(self.qrType == QRType_Group) {
        self.qrStr = [NSString stringWithFormat:@"wildfirechat://group/%@", self.target];
//        self.qrStr = [NSString stringWithFormat:@"wildfirechat://group/%@?from=%@", self.target, [WFCCNetworkService sharedInstance].userId];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
        
        self.groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.target refresh:NO];
    } else if(self.qrType == QRType_Conference) {
        self.qrStr = self.conferenceUrl;
        self.labelStr = self.conferenceTitle;
    }
}


- (void)saveImage:(UIImage *)image {
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] init];
    indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    indicator.center = self.view.center;
    _indicatorView = indicator;
    [[UIApplication sharedApplication].keyWindow addSubview:indicator];
    [indicator startAnimating];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
{
    [_indicatorView removeFromSuperview];
    
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.90f];
    label.layer.cornerRadius = 5;
    label.clipsToBounds = YES;
    label.bounds = CGRectMake(0, 0, 150, 30);
    label.center = self.view.center;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:17];
    [[UIApplication sharedApplication].keyWindow addSubview:label];
    [[UIApplication sharedApplication].keyWindow bringSubviewToFront:label];
    if (error) {
        label.text = WFCString(@"SaveFailure");
    } else {
        label.text = WFCString(@"SaveSuccess");
    }
    [label performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.0];
}


- (void)onRightBtn:(id)sender {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *actionSave = [UIAlertAction actionWithTitle:@"保存二维码" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        UIGraphicsBeginImageContext(self.qrView.bounds.size);
        [self.qrView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self saveImage:image];
    }];
    
    [actionSheet addAction:actionSave];
    [actionSheet addAction:actionCancel];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)setUserInfo:(WFCCUserInfo *)userInfo {
    _userInfo = userInfo;
    self.qrLogo = userInfo.portrait;
    if (userInfo.displayName.length) {
        self.labelStr = userInfo.displayName;
    } else {
        self.labelStr = @"用户";
    }
}

- (void)setGroupInfo:(WFCCGroupInfo *)groupInfo {
    _groupInfo = groupInfo;
    
    if (groupInfo.portrait.length) {
        self.qrLogo = groupInfo.portrait;
    } else {
        NSString *filePath = [WFCCUtilities getGroupGridPortrait:groupInfo.target width:50 generateIfNotExist:YES defaultUserPortrait:^UIImage *(NSString *userId) {
            return [UIImage imageNamed:@"PersonalChat"];
        }];
        self.qrLogo = filePath;
    }
    
    if (groupInfo.displayName.length) {
        self.labelStr = groupInfo.displayName;
    } else {
        self.labelStr = @"群组";
    }
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (WFCCUserInfo *userInfo in userInfoList) {
        if ([self.target isEqualToString:userInfo.userId]) {
            self.userInfo = userInfo;
            break;
        }
    }
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    for (WFCCGroupInfo *groupInfo in groupInfoList) {
        if ([self.target isEqualToString:groupInfo.target]) {
            self.groupInfo = groupInfo;
            break;
        }
    }
}

- (void)setQrLogo:(NSString *)qrLogo {
    _qrLogo = qrLogo;
    __weak typeof(self)ws = self;
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        CGSize logoSize=CGSizeMake(50, 50);
        UIImage *logo;
        if ([NSURL URLWithString:qrLogo].baseURL) {
            logo = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:ws.qrLogo]]];
        } else {
            logo = [UIImage imageWithContentsOfFile:qrLogo];
        }
        if (!logo) {
            logo = [UIImage imageNamed:@"group_default_portrait"];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            ws.logoImgView = [ws roundCornerWithImage:logo size:logoSize];
            ws.logoImgView.bounds = CGRectMake(0, 0, logoSize.width, logoSize.height);
            ws.logoImgView.center = CGPointMake(40, 40);
            [ws.qrView addSubview:ws.logoImgView];
        });
    });
}

- (void)setLabelStr:(NSString *)labelStr {
    _labelStr = labelStr;
    self.nameLabel.text = labelStr;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(72, 28, self.qrView.bounds.size.width - 72 - 16, 22)];
        [self.qrView addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (UIView *)qrView {
    if (!_qrView) {
        UIView *view = [[UIView alloc]initWithFrame:CGRectMake( (CGRectGetWidth(self.view.frame)-CGRectGetWidth(self.view.frame)*5/6)/2, 100, CGRectGetWidth(self.view.frame)*5/6, CGRectGetWidth(self.view.frame)*5/6+60)];
        [self.view addSubview:view];
        view.backgroundColor = [UIColor whiteColor];
        view.layer.shadowOffset = CGSizeMake(0, 2);
        view.layer.shadowRadius = 2;
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOpacity = 0.5;
        _qrView = view;
    }
    return _qrView;
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.qrImgView = [[UIImageView alloc]init];
    _qrImgView.bounds = CGRectMake(0, 0, CGRectGetWidth(self.qrView.frame)-12, CGRectGetWidth(self.qrView.frame)-12);
    _qrImgView.center = CGPointMake(CGRectGetWidth(self.qrView.frame)/2, CGRectGetHeight(self.qrView.frame)/2+30);
    [self.qrView addSubview:_qrImgView];
    
    [self createQR_logo];
}

- (void)createQR_logo
{
    _qrView.hidden = NO;
    _qrImgView.image = [LBXScanNative createQRWithString:self.qrStr QRSize:_qrImgView.bounds.size];
}

- (UIImageView*)roundCornerWithImage:(UIImage*)logoImg size:(CGSize)size
{
    //logo圆角
    UIImageView *backImage = [[UIImageView alloc] initWithCornerRadiusAdvance:6.0f rectCornerType:UIRectCornerAllCorners];
    backImage.frame = CGRectMake(0, 0, size.width, size.height);
    backImage.backgroundColor = [UIColor whiteColor];
    
    UIImageView *logImage = [[UIImageView alloc] initWithCornerRadiusAdvance:6.0f rectCornerType:UIRectCornerAllCorners];
    logImage.image =logoImg;
    CGFloat diff  =2;
    logImage.frame = CGRectMake(diff, diff, size.width - 2 * diff, size.height - 2 * diff);
    
    [backImage addSubview:logImage];
    
    return backImage;
}

- (void)showError:(NSString*)str
{
    [LBXAlertAction showAlertWithTitle:@"提示" msg:str buttonsStatement:@[@"知道了"] chooseBlock:nil];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
