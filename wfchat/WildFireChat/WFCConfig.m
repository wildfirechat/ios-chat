//
//  Config.m
//  Wildfire Chat
//
//  Created by WF Chat on 2017/10/21.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCConfig.h"

//可以是IP，可以是域名，如果是域名的话只支持主域名或www域名或im或imtest的二级域名，其它二级域名不支持！
//例如：example.com或www.example.com或im.example.com或imtest.example.com是支持的；xx.example.com或xx.yy.example.com是不支持的。如果是专业版必须用域名。
NSString *IM_SERVER_HOST = @"wildfirechat.cn";


//正式商用时，建议用https，确保token安全
NSString *APP_SERVER_ADDRESS = @"http://wildfirechat.cn:8888";
//NSString *APP_SERVER_ADDRESS = @"https://app.wildfirechat.cn";

NSString *ICE_ADDRESS = @"turn:turn.wildfirechat.cn:3478";
NSString *ICE_USERNAME = @"wfchat";
NSString *ICE_PASSWORD = @"wfchat";
