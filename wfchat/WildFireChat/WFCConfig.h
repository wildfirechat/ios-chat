//
//  Config.h
//  Wildfire Chat
//
//  Created by WF Chat on 2017/10/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#ifndef Config_h
#define Config_h
#import <Foundation/Foundation.h>

extern NSString *IM_SERVER_HOST;

extern NSString *APP_SERVER_ADDRESS;

extern NSString *ICE_ADDRESS;
extern NSString *ICE_USERNAME;
extern NSString *ICE_PASSWORD;

//用户协议和隐私政策，上线前请替换成您自己的内容
extern NSString *USER_PRIVACY_URL;
extern NSString *USER_AGREEMENT_URL;

//文件传输助手用户ID，服务器有个默认文件助手的机器人，如果修改它的ID，需要客户端和服务器数据库同步修改
extern NSString *FILE_TRANSFER_ID;
#endif /* Config_h */
