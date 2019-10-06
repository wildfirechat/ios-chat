//
//  CreateGroupViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/14.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUCreateChannelViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"
#import "MBProgressHUD.h"
#import "SDWebImage.h"
#import "UIView+Toast.h"
#import "WFCUConfigManager.h"


@interface WFCUCreateChannelViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property(nonatomic, strong)UIImageView *portraitView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UITextField *nameField;

@property(nonatomic, strong)UILabel *descLabel;
@property(nonatomic, strong)UITextField *descField;

@property(nonatomic, strong)UILabel *openLabel;
@property(nonatomic, strong)UISwitch *openSwitch;

@property(nonatomic, strong)NSString *portraitUrl;

@end
#define PortraitWidth 80
@implementation WFCUCreateChannelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    
    CGRect bound = self.view.bounds;
    CGFloat portraitWidth = PortraitWidth;
    CGFloat top = 100;
    
    self.portraitView = [[UIImageView alloc] initWithFrame:CGRectMake((bound.size.width - portraitWidth)/2, top, portraitWidth, portraitWidth)];
    self.portraitView.image = [UIImage imageNamed:@"channel_default_portrait"];
    self.portraitView.userInteractionEnabled = YES;
    self.portraitView.layer.borderWidth = 0.5;
    self.portraitView.layer.borderColor = [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9].CGColor;
    self.portraitView.layer.cornerRadius = 3;
    self.portraitView.layer.masksToBounds = YES;
    UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSelectPortrait:)];
    [self.portraitView addGestureRecognizer:tap];
    
    [self.view addSubview:self.portraitView];
    
  

    CGFloat namePadding = 36;
    CGFloat labelWidth = 72;
    CGFloat labelFeildPadding = 4;
    top += portraitWidth;
    top += 40;
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(namePadding, top, labelWidth, 25)];
    self.nameLabel.text = WFCString(@"ChannelName");
    self.nameLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.nameLabel];
    
    
    self.nameField = [[UITextField alloc] initWithFrame:CGRectMake(namePadding + labelWidth + labelFeildPadding, top, bound.size.width - namePadding - labelWidth - labelFeildPadding - namePadding, 24)];
    [self.nameField setPlaceholder:WFCString(@"InputChannelNameHint")];
    [self.nameField setFont:[UIFont systemFontOfSize:14]];
    self.nameField.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:self.nameField];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(namePadding + labelWidth + labelFeildPadding, top + 24, bound.size.width - namePadding - labelWidth - labelFeildPadding - namePadding, 1)];
    [line setBackgroundColor:[UIColor grayColor]];
    [self.view addSubview:line];

    top += 25;
    top += 16;
    self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(namePadding, top, labelWidth, 25)];
    self.descLabel.text = WFCString(@"ChannelDescription");
    self.descLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.descLabel];
    
    
    self.descField = [[UITextField alloc] initWithFrame:CGRectMake(namePadding + labelWidth + labelFeildPadding, top, bound.size.width - namePadding - labelWidth - labelFeildPadding - namePadding, 24)];
    [self.descField setPlaceholder:WFCString(@"InputChannelDescHint")];
    [self.descField setFont:[UIFont systemFontOfSize:14]];
    self.descField.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:self.descField];
    
    line = [[UIView alloc] initWithFrame:CGRectMake(namePadding + labelWidth + labelFeildPadding, top + 24, bound.size.width - namePadding - labelWidth - labelFeildPadding - namePadding, 1)];
    [line setBackgroundColor:[UIColor grayColor]];
    [self.view addSubview:line];
    
    
    
    top += 25;
    top += 16;
    self.openLabel = [[UILabel alloc] initWithFrame:CGRectMake(namePadding, top, labelWidth, 25)];
    self.openLabel.text = WFCString(@"Public");
    self.openLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.openLabel];
    
    
    self.openSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(namePadding + labelWidth + labelFeildPadding, top, 60, 24)];
    self.openSwitch.on = YES;
    [self.view addSubview:self.openSwitch];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Create") style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onResetKeyBoard:)]];
}

- (void)onResetKeyBoard:(id)sender {
    [self.nameField resignFirstResponder];
    [self.descField resignFirstResponder];
}

- (void)onSelectPortrait:(id)sender {
    __weak typeof(self)ws = self;
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:WFCString(@"ChangePortrait") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *actionCamera = [UIAlertAction actionWithTitle:WFCString(@"TakePhotos") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.allowsEditing = YES;
        picker.delegate = ws;
        if ([UIImagePickerController
             isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        } else {
            NSLog(@"无法连接相机");
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        [ws presentViewController:picker animated:YES completion:nil];
    }];
    
    UIAlertAction *actionAlubum = [UIAlertAction actionWithTitle:WFCString(@"Album") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.allowsEditing = YES;
        picker.delegate = ws;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [ws presentViewController:picker animated:YES completion:nil];
    }];
    
    //把action添加到actionSheet里
    [actionSheet addAction:actionCamera];
    [actionSheet addAction:actionAlubum];
    [actionSheet addAction:actionCancel];
    
    //相当于之前的[actionSheet show];
    [self presentViewController:actionSheet animated:YES completion:nil];
}


#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [UIApplication sharedApplication].statusBarHidden = NO;
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqual:@"public.image"]) {
        UIImage *originImage =
        [info objectForKey:UIImagePickerControllerEditedImage];
        //获取截取区域的图像
        UIImage *captureImage = [WFCUUtilities thumbnailWithImage:originImage maxSize:CGSizeMake(60, 60)];
        self.portraitView.image = captureImage;
        self.portraitView.hidden = NO;
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)uploadPortrait:(UIImage *)portraitImage {
    NSData *portraitData = UIImageJPEGRepresentation(portraitImage, 0.70);
    __weak typeof(self) ws = self;
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"PhotoUploading");
    [hud showAnimated:YES];
    
    [[WFCCIMService sharedWFCIMService] uploadMedia:nil mediaData:portraitData mediaType:Media_Type_PORTRAIT success:^(NSString *remoteUrl) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:NO];
            ws.portraitUrl = remoteUrl;
            NSString *name = ws.nameField.text;
            [ws createChannel:ws.portraitUrl];
        });
    }
                                           progress:^(long uploaded, long total) {
                                               
                                           }
                                              error:^(int error_code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:NO];
            hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = WFCString(@"UploadFailure");
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)getPortraitImage {
    return self.portraitView.image;
}
  
- (void)onDone:(id)sender {
    [self uploadPortrait:[self getPortraitImage]];
}
  
- (void)createChannel:(NSString *)portraitUrl {
    __weak typeof(self) ws = self;
    
    [[WFCCIMService sharedWFCIMService] createChannel:self.nameField.text portrait:portraitUrl status:self.openSwitch.on ? 0 : 1 desc:self.descField.text extra:nil success:^(WFCCChannelInfo *channelInfo) {
        NSLog(@"create channel done");
        WFCCTipNotificationContent *tip = [[WFCCTipNotificationContent alloc] init];
        tip.tip = WFCString(@"ChannelCreated");
        [[WFCCIMService sharedWFCIMService] send:[WFCCConversation conversationWithType:Channel_Type target:channelInfo.channelId line:0] content:tip success:^(long long messageUid, long long timestamp) {
            NSLog(@"send channel msg done");
        } error:^(int error_code) {
            NSLog(@"send channel msg failure");
        }];
        [ws.view makeToast:WFCString(@"ChannelCreateFailure")
                  duration:2
                  position:CSToastPositionCenter];
        [ws.navigationController popViewControllerAnimated:YES];
    } error:^(int error_code) {
        NSLog(@"create channel error%d", error_code);
    }];
    
}
- (void)modifyGroup:(NSString *)groupId portrait:(NSString *)portraitUrl {
  __weak typeof(self) ws = self;
    [[WFCCIMService sharedWFCIMService] modifyGroupInfo:groupId type:Modify_Group_Portrait newValue:portraitUrl notifyLines:@[@(0)] notifyContent:nil success:^{
      dispatch_async(dispatch_get_main_queue(), ^{
          [ws.navigationController popViewControllerAnimated:YES];
      });
  } error:^(int error_code) {
    
  }];
  
}
@end
