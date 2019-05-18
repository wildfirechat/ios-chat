//
//  CreateGroupViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/14.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUCreateGroupViewController : UIViewController
@property(nonatomic, strong)NSMutableArray<NSString *> *memberIds;
@property(nonatomic, assign)BOOL isModifyPortrait;
@property(nonatomic, strong)NSString *groupId;
@property(nonatomic, strong)void (^onSuccess)(NSString *groupId);
@end
