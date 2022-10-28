//
//  WFCUProfileMoreTableViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/22.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFCUEnum.h"

@interface WFCUProfileMoreTableViewController : UIViewController
@property (nonatomic, strong)NSString *userId;
@property (nonatomic, strong)NSArray<NSString *> *commonGroupIds;
@end
