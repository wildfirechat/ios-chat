//
//  WFCUDomainTableViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/13.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUDomainTableViewController : UITableViewController
@property (nonatomic, assign)BOOL isPresent;
@property (nonatomic, strong)void (^onSelect)(NSString *domainId);

@end
