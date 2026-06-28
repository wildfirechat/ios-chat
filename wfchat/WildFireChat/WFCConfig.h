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

// 双网媒体地址前缀，用于头像/媒体类消息中的 URL 转换。
// 只在双网环境下配置，不需要双网时保持为 nil。
extern NSString *MAIN_MEDIA_URL_PREFIX;
extern NSString *BACKUP_MEDIA_URL_PREFIX;

extern NSString *APP_SERVER_ADDRESS;
extern NSString *APP_SERVER_BACKUP_ADDRESS;
extern NSString *ORG_SERVER_ADDRESS;
extern NSString *ORG_SERVER_BACKUP_ADDRESS;
extern NSString *COLLECTION_SERVER_ADDRESS;
extern NSString *COLLECTION_SERVER_BACKUP_ADDRESS;
extern NSString *POLL_SERVER_ADDRESS;
extern NSString *POLL_SERVER_BACKUP_ADDRESS;
extern NSString *PAN_SERVER_ADDRESS;
extern NSString *PAN_SERVER_BACKUP_ADDRESS;
extern NSString *ARCHIVE_SERVER_ADDRESS;
extern NSString *ARCHIVE_SERVER_BACKUP_ADDRESS;


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
extern NSString *WORK_PLATFORM_BACKUP_URL;

//语音转文字服务
extern NSString *ASR_SERVICE_URL;
extern NSString *ASR_SERVICE_BACKUP_URL;

//有2种登录方式，手机号码+验证码登录 和 手机号码+密码登录。
//这个开关是否优先密码登录
extern BOOL Prefer_Password_Login;

//发送日志命令，当发送此文本消息时，会把协议栈日志发送到当前会话中，为空时关闭此功能。
extern NSString *Send_Log_Command;

//是否开启水印
extern BOOL ENABLE_WATER_MARKER;

//是否开启滑动验证。如果关闭，需要在应用服务同步关闭。
extern BOOL ENABLE_SLIDE_VERIFY;

//AI机器人ID，可以在单聊或者群里@ 
extern NSString *AI_ROBOT;

//拨号机器人ID，点击该机器人会话进入拨号界面
extern NSString *DIALIN_ROBOT_ID;

//AI语音记录助手ID，在和该助手单聊中点击通话记录可查看语音记录
extern NSString *AI_MINUTES_ROBOT_ID;

//语音记录查看页面地址
extern NSString *MINUTES_URL;
extern NSString *MINUTES_BACKUP_URL;

#pragma mark - 双网地址选择辅助函数

/**
 * 根据当前网络状态在主营和备选地址之间选择。
 * 当 IM 已连接时，使用 connectedToMainNetwork 判断；
 * 未连接或未配置备选地址时，返回主网地址。
 */
NSString *WFCSelectServer(NSString *main, NSString *backup);

NSString *WFCGetAppServerAddress(void);
NSString *WFCGetOrgServerAddress(void);
NSString *WFCGetCollectionServerAddress(void);
NSString *WFCGetPollServerAddress(void);
NSString *WFCGetPanServerAddress(void);
NSString *WFCGetArchiveServerAddress(void);
NSString *WFCGetWorkPlatformUrl(void);
NSString *WFCGetAsrServiceUrl(void);
NSString *WFCGetMinutesUrl(void);

#endif /* Config_h */
