//
//  GeneralModifyViewController.h
//  WildFireChat
//
//  Created by heavyrain lee on 24/12/2017.
//  Copyright © 2017 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUGeneralModifyViewController : UIViewController
@property (nonatomic, strong)NSString *defaultValue;
@property (nonatomic, strong)NSString *titleText;
@property (nonatomic, assign)BOOL canEmpty;
@property (nonatomic, strong)void (^tryModify)(NSString *newValue, void (^result)(BOOL success));
@property (nonatomic, assign)BOOL noProgress;
@end
