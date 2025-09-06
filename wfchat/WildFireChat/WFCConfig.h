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
extern NSString *ORG_SERVER_ADDRESS;


extern NSString *ICE_ADDRESS;
extern NSString *ICE_USERNAME;
extern NSString *ICE_PASSWORD;

//用户协议和隐私政策，上线前请替换成您自己的内容
extern NSString *USER_PRIVACY_URL;
extern NSString *USER_AGREEMENT_URL;

//文件传输助手用户ID，服务器有个默认文件助手的机器人，如果修改它的ID，需要客户端和服务器数据库同步修改
extern NSString *FILE_TRANSFER_ID;

//如果想要关掉工作台，把WORK_PLATFORM_URL设置为nil就可以了
extern NSString *WORK_PLATFORM_URL;

//语音转文字服务
extern NSString *ASR_SERVICE_URL;

//有2种登录方式，手机号码+验证码登录 和 手机号码+密码登录。
//这个开关是否优先密码登录
extern BOOL Prefer_Password_Login;

//发送日志命令，当发送此文本消息时，会把协议栈日志发送到当前会话中，为空时关闭此功能。
extern NSString *Send_Log_Command;

//是否开启水印
extern BOOL ENABLE_WATER_MARKER;

//AI机器人ID
extern NSString *AI_ROBOT;
#endif /* Config_h */
