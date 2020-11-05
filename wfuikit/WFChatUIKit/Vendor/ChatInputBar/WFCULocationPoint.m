//
//  LocationPoint.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCULocationPoint.h"

@implementation WFCULocationPoint
- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate andTitle:(NSString *)title{
    self = [super init];
    if (self) {
        _coordinate = coordinate;
        _title      = title;
    }
    return self;
}




@end
