//
//  ModifyMyProfileViewController.h
//  WildFireChat
//
//  Created by heavyrain.lee on 2018/5/20.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUModifyMyProfileViewController : UIViewController
@property(nonatomic, assign)NSInteger modifyType;
@property(nonatomic, copy)void (^onModified)(NSInteger modifyType, NSString *value);
@end
