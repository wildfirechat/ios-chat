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

@interface CreateBarCodeViewController ()
@property (nonatomic, strong)UIImageView *logoView;
@property (nonatomic, strong)UILabel *nameLabel;
@property (nonatomic, strong) UIImageView* logoImgView;

@property (nonatomic, strong) UIView *qrView;
@property (nonatomic, strong) UIImageView* qrImgView;
@end

@implementation CreateBarCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.view.backgroundColor = [UIColor colorWithRed:239/255.f green:239/255.f blue:239/255.f alpha:1.0f];
    
    
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake( (CGRectGetWidth(self.view.frame)-CGRectGetWidth(self.view.frame)*5/6)/2, 100, CGRectGetWidth(self.view.frame)*5/6, CGRectGetWidth(self.view.frame)*5/6+60)];
    [self.view addSubview:view];
    view.backgroundColor = [UIColor whiteColor];
    view.layer.shadowOffset = CGSizeMake(0, 2);
    view.layer.shadowRadius = 2;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOpacity = 0.5;
    self.qrView = view;
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(72, 15, self.qrView.bounds.size.width - 72 - 16, 22)];
    self.nameLabel.text = self.labelStr;
    [self.qrView addSubview:self.nameLabel];
    
    __weak typeof(self)ws = self;
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        CGSize logoSize=CGSizeMake(50, 50);
        UIImage *logo = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:ws.logoUrl]]];
        dispatch_async(dispatch_get_main_queue(), ^{
            ws.logoImgView = [ws roundCornerWithImage:logo size:logoSize];
            ws.logoImgView.bounds = CGRectMake(0, 0, logoSize.width, logoSize.height);
            ws.logoImgView.center = CGPointMake(40, 40);
            [ws.qrView addSubview:ws.logoImgView];
        });
    });
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
    _qrImgView.image = [LBXScanNative createQRWithString:self.str QRSize:_qrImgView.bounds.size];
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


@end
