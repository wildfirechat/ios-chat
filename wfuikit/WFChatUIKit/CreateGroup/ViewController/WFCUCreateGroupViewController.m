//
//  CreateGroupViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/14.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUCreateGroupViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"
#import "MBProgressHUD.h"
#import "SDWebImage.h"
#import "UIView+Toast.h"
#import "WFCUConfigManager.h"


@interface WFCUCreateGroupViewController () <UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate>
@property(nonatomic, strong)UIImageView *portraitView;
@property(nonatomic, strong)UITextField *nameField;
@property(nonatomic, strong)NSString *portraitUrl;

@property(nonatomic, strong)UIButton *resetBtn;
@property(nonatomic, strong)UISwitch *qqSwitch;
@property(nonatomic, strong)UIView *combineHeadView;
@end
#define PortraitWidth 120
@implementation WFCUCreateGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    
    CGRect bound = self.view.bounds;
    CGFloat portraitWidth = PortraitWidth;
    self.portraitView = [[UIImageView alloc] initWithFrame:CGRectMake((bound.size.width - portraitWidth)/2, 100, portraitWidth, portraitWidth)];
    self.portraitView.image = [UIImage imageNamed:@"group_default_portrait"];
    self.portraitView.userInteractionEnabled = YES;
    UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSelectPortrait:)];
    [self.portraitView addGestureRecognizer:tap];
    
    self.combineHeadView = [[UIView alloc] initWithFrame:CGRectMake((bound.size.width - portraitWidth)/2, 100, portraitWidth, portraitWidth)];
    [self.combineHeadView addGestureRecognizer:tap];
    
    [self.combineHeadView setBackgroundColor:[UIColor grayColor]];
    
    self.portraitView.hidden = YES;
    
    [self.view addSubview:self.combineHeadView];
    [self.view addSubview:self.portraitView];
    
  

  if(self.isModifyPortrait) {
    CGFloat btnWidth = 60;
    self.resetBtn = [[UIButton alloc] initWithFrame:CGRectMake((bound.size.width - btnWidth)/2, 80 + portraitWidth + 60, btnWidth, 40)];
    [self.resetBtn setTitle:@"重置" forState:UIControlStateNormal];
    [self.resetBtn addTarget:self action:@selector(onResetPortrait:) forControlEvents:UIControlEventTouchUpInside];
    [self.resetBtn setBackgroundColor:[UIColor greenColor]];
      self.resetBtn.layer.cornerRadius = 4.f;
      self.resetBtn.layer.masksToBounds = YES;
    [self.view addSubview:self.resetBtn];
  } else {
    CGFloat namePadding = 60;
    self.nameField = [[UITextField alloc] initWithFrame:CGRectMake(namePadding, 80 + portraitWidth + 60, bound.size.width - namePadding - namePadding, 24)];
    [self.nameField setPlaceholder:WFCString(@"InputGropNameHint")];
    [self.nameField setFont:[UIFont systemFontOfSize:21]];
    self.nameField.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.nameField];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(namePadding, 80 + portraitWidth + 60 + 24, bound.size.width - namePadding - namePadding, 2)];
    [line setBackgroundColor:[UIColor grayColor]];
    [self.view addSubview:line];
  }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Done") style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onResetKeyBoard:)]];
  
  if (!_isModifyPortrait) {
    [self loadCombineView];
  } else {
    UIImageView *portraitView = [[UIImageView alloc] initWithFrame:self.combineHeadView.bounds];
    WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.groupId refresh:NO];
    [portraitView sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    [self.combineHeadView addSubview:portraitView];
  }
}

- (void)loadCombineView {
    NSMutableArray *users = [[NSMutableArray alloc] init];
    if (![self.memberIds containsObject:[WFCCNetworkService sharedInstance].userId]) {
        WFCCUserInfo *user = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
        [users addObject:user];
    }
  
  for (UIView *subView in self.combineHeadView.subviews) {
    [subView removeFromSuperview];
  }
    
    for (NSString *userId in self.memberIds) {
        WFCCUserInfo *user = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
        if (user != nil) {
            [users addObject:user];
        }
        if (users.count >= 9) {
            break;
        }
    }
    
    CGFloat padding = 5;
    
    int numPerRow = 3;
    
    if (users.count <= 4) {
        numPerRow = 2;
    }
        int row = (int)(users.count - 1) / numPerRow + 1;
        int column = numPerRow;
        int firstCol = (int)(users.count - (row - 1)*column);
    
    CGFloat width = (PortraitWidth - padding) / numPerRow - padding;
    
        CGFloat Y = (PortraitWidth - (row * (width + padding) + padding))/2;
        for (int i = 0; i < row; i++) {
            int c = column;
            if (i == 0) {
                c = firstCol;
            }
            CGFloat X = (PortraitWidth - (c * (width + padding) + padding))/2;
            for (int j = 0; j < c; j++) {
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(X + j *(width + padding) + padding, Y + i * (width + padding) + padding, width, width)];
                int index;
                if (i == 0) {
                    index = j;
                } else {
                    index = j + (i-1)*column + firstCol;
                }
                WFCCUserInfo *user = [users objectAtIndex:index];
                [imageView sd_setImageWithURL:[NSURL URLWithString:[user.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
                [self.combineHeadView addSubview:imageView];
            }
        }
    
}

- (void)onResetKeyBoard:(id)sender {
    [self.nameField resignFirstResponder];
}

- (void)onSelectPortrait:(id)sender {
    UIActionSheet *actionSheet =
    [[UIActionSheet alloc] initWithTitle:WFCString(@"ChangePortrait")
                                delegate:self
                       cancelButtonTitle:WFCString(@"Cancel")
                  destructiveButtonTitle:WFCString(@"TakePhotos")
                       otherButtonTitles:WFCString(@"Album"), nil];
    [actionSheet showInView:self.view];
}

#pragma mark -  UIActionSheetDelegate <NSObject>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.allowsEditing = YES;
        picker.delegate = self;
        if ([UIImagePickerController
             isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        } else {
            NSLog(@"无法连接相机");
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        [self presentViewController:picker animated:YES completion:nil];
        
    } else if (buttonIndex == 1) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.allowsEditing = YES;
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:picker animated:YES completion:nil];
    }
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
        self.combineHeadView.hidden = YES;
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)uploadPortrait:(UIImage *)portraitImage createGroup:(BOOL)createGroup {
    NSData *portraitData = UIImageJPEGRepresentation(portraitImage, 0.70);
    __weak typeof(self) ws = self;
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"PhotoUploading");
    [hud showAnimated:YES];
    
    [[WFCCIMService sharedWFCIMService] uploadMedia:nil mediaData:portraitData mediaType:Media_Type_PORTRAIT success:^(NSString *remoteUrl) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:NO];
          if (createGroup) {
            ws.portraitUrl = remoteUrl;
              NSString *name = ws.nameField.text;
              if (name.length == 0) {
                  WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[self.memberIds objectAtIndex:0]  refresh:NO];
                  if (userInfo.displayName.length > 0) {
                      name = [name stringByAppendingString:userInfo.displayName];
                  }
                  for (int i = 1; i < 8 && i < self.memberIds.count; i++) {
                      userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[self.memberIds objectAtIndex:i]  refresh:NO];
                      if (userInfo.displayName.length > 0) {
                          if (name.length + userInfo.displayName.length + 1 > 16) {
                              name = [name stringByAppendingString:WFCString(@"Etc")];
                              break;
                          }
                          name = [name stringByAppendingFormat:@",%@", userInfo.displayName];
                      }
                  }
                  if (name.length == 0) {
                      name = WFCString(@"GroupChat");
                  }
              }
            [ws createGroup:name portrait:ws.portraitUrl members:ws.memberIds];
          } else {
            [ws modifyGroup:ws.groupId portrait:remoteUrl];
          }
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
    if (self.portraitView.hidden == NO) {
        return self.portraitView.image;
    } else {
        UIGraphicsBeginImageContextWithOptions(self.combineHeadView.frame.size, NO, 2.0);
        [self.combineHeadView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image;
    }
}
  
- (void)onDone:(id)sender {
  if (self.isModifyPortrait) {
    [self uploadPortrait:[self getPortraitImage] createGroup:NO];
  } else {
    [self uploadPortrait:[self getPortraitImage] createGroup:YES];
  }
}
  
- (void)onResetPortrait:(id)sender {
  [self loadCombineView];
}
  
- (void)createGroup:(NSString *)groupName portrait:(NSString *)portraitUrl members:(NSArray<NSString *> *)memberIds {
    __weak typeof(self) ws = self;
    [[WFCCIMService sharedWFCIMService] createGroup:nil name:groupName portrait:portraitUrl type:GroupType_Restricted members:memberIds notifyLines:@[@(0)] notifyContent:nil success:^(NSString *groupId) {
        NSLog(@"create group success");
        if (ws.onSuccess) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ws.onSuccess(groupId);
            });
        }
    } error:^(int error_code) {
        NSLog(@"create group failure");
        [ws.view makeToast:WFCString(@"CreateGroupFailure")
                    duration:2
                    position:CSToastPositionCenter];

    }];
    
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)modifyGroup:(NSString *)groupId portrait:(NSString *)portraitUrl {
  __weak typeof(self) ws = self;
    [[WFCCIMService sharedWFCIMService] modifyGroupInfo:groupId type:Modify_Group_Portrait newValue:portraitUrl notifyLines:@[@(0)] notifyContent:nil success:^{
      dispatch_async(dispatch_get_main_queue(), ^{
          [ws.navigationController popViewControllerAnimated:YES];
          if (ws.onSuccess) {
              dispatch_async(dispatch_get_main_queue(), ^{
                  ws.onSuccess(groupId);
              });
          }
      });
  } error:^(int error_code) {
    
  }];
  
}
@end
