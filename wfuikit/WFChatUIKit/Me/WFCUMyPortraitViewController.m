//
//  MyPortraitViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/6.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUMyPortraitViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDWebImage.h"
#import "MBProgressHUD.h"
#import "WFCUUtilities.h"
#import "SDPhotoBrowser.h"

@interface WFCUMyPortraitViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, SDPhotoBrowserDelegate>
  @property (strong, nonatomic)UIImageView *portraitView;
@property (nonatomic, strong)UIImage *image;
@property (nonatomic, strong)WFCCUserInfo *userInfo;
@end

@implementation WFCUMyPortraitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor blackColor]];
  
    self.portraitView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.portraitView];
    
    if ([[WFCCNetworkService sharedInstance].userId isEqualToString:self.userId]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Modify") style:UIBarButtonItemStyleDone target:self action:@selector(onModify:)];
    }
    
  self.userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.userId refresh:NO];
    __weak typeof(self)ws = self;
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[self.userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ws.image = image;
        });
    }];
    
    UITapGestureRecognizer* doubleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFullScreen:)];
    doubleRecognizer.numberOfTapsRequired = 2;
    [self.portraitView addGestureRecognizer:doubleRecognizer];
    self.portraitView.userInteractionEnabled = YES;
}

- (void)showFullScreen:(id)sender {
    SDPhotoBrowser *browser = [[SDPhotoBrowser alloc] init];
    browser.sourceImagesContainerView = self.view;
    browser.imageCount = 1;
    browser.currentImageIndex = 0;
    browser.delegate = self;
    [browser show]; // 展示图片浏览器
}

- (void)setImage:(UIImage *)image {
    _image = image;
    if (_image.size.width) {
        CGRect containerRect = self.view.bounds;
        if (containerRect.size.width / containerRect.size.height < image.size.width / image.size.height) {
            self.portraitView.frame = CGRectMake(0, (containerRect.size.height - image.size.height * containerRect.size.width/image.size.width)/2, containerRect.size.width, image.size.height * containerRect.size.width/image.size.width);
        } else {
            self.portraitView.frame = CGRectMake((containerRect.size.width - image.size.width * containerRect.size.height/image.size.height)/2, 0, image.size.width * containerRect.size.height/image.size.height, containerRect.size.height);
        }
        
    }
}

- (void)onModify:(id)sender {
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
  
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
  [UIApplication sharedApplication].statusBarHidden = NO;
  NSData *data = nil;
  NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
  
  if ([mediaType isEqual:@"public.image"]) {
    UIImage *originImage =
    [info objectForKey:UIImagePickerControllerEditedImage];
    //获取截取区域的图像
    UIImage *captureImage = [WFCUUtilities thumbnailWithImage:originImage maxSize:CGSizeMake(600, 600)];
    data = UIImageJPEGRepresentation(captureImage, 0.00001);
  }
  
  UIImage *previousImage = self.portraitView.image;
  __weak typeof(self) ws = self;
  __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  hud.label.text = WFCString(@"Updating");
  [hud showAnimated:YES];
  
    [[WFCCIMService sharedWFCIMService] uploadMedia:nil mediaData:data mediaType:Media_Type_PORTRAIT
                                          success:^(NSString *remoteUrl) {
    [[WFCCIMService sharedWFCIMService] modifyMyInfo:@{@(Modify_Portrait):remoteUrl} success:^{
      dispatch_async(dispatch_get_main_queue(), ^{
        [ws.portraitView sd_setImageWithURL:[NSURL URLWithString:[remoteUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:previousImage];

          [hud hideAnimated:YES];
          MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
          hud.mode = MBProgressHUDModeText;
          hud.label.text = WFCString(@"UpdateDone");
          hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
          [hud hideAnimated:YES afterDelay:1.f];
          
      });
    } error:^(int error_code) {
      dispatch_async(dispatch_get_main_queue(), ^{
          [hud hideAnimated:YES];
          MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
          hud.mode = MBProgressHUDModeText;
          hud.label.text = WFCString(@"UpdateFailure");
          hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
          [hud hideAnimated:YES afterDelay:1.f];
      });
    }];
  }
                                         progress:^(long uploaded, long total) {
      
  }
                                            error:^(int error_code) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [hud hideAnimated:NO];
      [ws showHud:WFCString(@"UpdateFailure")];
    });
  }];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}
  
  - (void)showHud:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Set the text mode to show only text.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    // Move to bottm center.
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    [hud hideAnimated:YES afterDelay:1.f];
  }

#pragma mark - SDPhotoBrowserDelegate
- (UIImage *)photoBrowser:(SDPhotoBrowser *)browser placeholderImageForIndex:(NSInteger)index {
    return [UIImage imageNamed:@"PersonalChat"];
}

- (NSURL *)photoBrowser:(SDPhotoBrowser *)browser highQualityImageURLForIndex:(NSInteger)index {
    return [NSURL URLWithString:[self.userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (void)photoBrowserDidDismiss:(SDPhotoBrowser *)browser {
}
@end
