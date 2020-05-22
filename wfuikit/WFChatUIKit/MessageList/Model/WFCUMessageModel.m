//
//  MessageModel.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUMessageModel.h"

@implementation WFCUMessageModel
+ (instancetype)modelOf:(WFCCMessage *)message showName:(BOOL)showName showTime:(BOOL)showTime {
  WFCUMessageModel *model = [[WFCUMessageModel alloc] init];
  model.message = message;
  model.showNameLabel = showName;
  model.showTimeLabel = showTime;
  return model;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.deliveryRate = -1;
        self.readRate = -1;
    }
    return self;
}
@end
