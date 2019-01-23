//
//  SelectFileViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUSelectFileViewController : UIViewController
@property(nonatomic, copy)void (^selectResult)(NSArray *selectedFiles);
@end
