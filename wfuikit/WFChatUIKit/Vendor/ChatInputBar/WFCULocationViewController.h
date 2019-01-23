//
//  LocationViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class WFCULocationPoint;

@protocol LocationViewControllerDelegate <NSObject>
- (void)onSendLocation:(WFCULocationPoint *)locationPoint;
@end

@interface WFCULocationViewController : UIViewController<MKMapViewDelegate>

//选择地理位置
- (instancetype)initWithDelegate:(id<LocationViewControllerDelegate>)delegate;

//显示地理位置
- (instancetype)initWithLocationPoint:(WFCULocationPoint *)locationPoint;


@end
