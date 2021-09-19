//
//  WFCLoginViewController.h
//  Wildfire Chat
//
//  Created by WF Chat on 2017/7/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCLoginViewController : UIViewController
//如果是因为多端登录被踢，提示原因。注意错误码kConnectionStatusKickedoff是IM服务2021.9.15之后的版本才支持，并且打开服务器端开关server.client_support_kickoff_event
@property(nonatomic, assign)BOOL isKickedOff;
@end
