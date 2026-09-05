//
//  WFCUJoinGroupRequestViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/7.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUJoinGroupRequestViewController : UIViewController
@property (nonatomic, strong)NSString *groupId;
// 入口会话的 line（普通群=0，AI 群=2）；通过申请（加人）通知发到该 line
@property (nonatomic, assign)int line;
@end
