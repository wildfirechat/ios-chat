//
//  CreateBarCodeViewController.h
//  LBXScanDemo
//
//  Created by lbxia on 2017/1/5.
//  Copyright © 2017年 lbx. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreateBarCodeViewController : UIViewController
@property (nonatomic, assign)int qrType;
@property (nonatomic, strong)NSString *target;
@property (nonatomic, strong)NSString *conferenceUrl;
@property (nonatomic, strong)NSString *conferenceTitle;
@end
