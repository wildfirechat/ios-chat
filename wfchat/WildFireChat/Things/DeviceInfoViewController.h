//
//  DeviceInfoViewController.h
//  WildFireChat
//
//  Created by Tom Lee on 2020/5/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Device.h"

NS_ASSUME_NONNULL_BEGIN

@interface DeviceInfoViewController : UIViewController
@property(nonatomic, strong)Device *device;
@end

NS_ASSUME_NONNULL_END
