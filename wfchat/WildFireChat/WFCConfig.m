//
//  Config.m
//  Wildfire Chat
//
//  Created by WF Chat on 2017/10/21.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCConfig.h"

//IM服务HOST，域名或者IP，注意不能带http头，也不能带端口。
//NSString *IM_SERVER_HOST = @"192.168.1.81";
//NSString *IM_SERVER_HOST = @"2409:8a00:32c0:1ee0:702d:f0c0:2e1b:4d10"; //ipv6地址，不能带[]和端口
NSString *IM_SERVER_HOST = @"wildfirechat.net";


// App Server默认使用的是8888端口，替换为自己部署的服务时需要注意端口别填错了，使用http访问appserver时，需要确保appserver的配置文件中的wfc.all_client_support_ssl参数为false
// 正式商用时，建议用https，确保token安全，可以使用nginx反向代理添加对ssl的支持。需要确保appserver的配置文件中的wfc.all_client_support_ssl参数为true
// 如果您使用web-chat，由于最新chrome浏览器的策略，只有使用https才能带上cookie访问appserver的接口，所以就必须使
// wfc.all_client_support_ssl为tue，所以客户端也必须使用https的应用服务地址

//NSString *APP_SERVER_ADDRESS = @"http://wildfirechat.net:8888";
//NSString *APP_SERVER_ADDRESS = @"http://[2409:8a00:32c0:1ee0:702d:f0c0:2e1b:4d10]:8888"; //ipv6地址要用这种方式
NSString *APP_SERVER_ADDRESS = @"https://app.wildfirechat.net";

//组织通讯录服务地址，如果没有部署，可以设置为nil。如果需要组织通讯录功能，请部署组织通讯录服务，然后这里填上组织通讯录服务地址。请注意不能写应用服务地址。
//组织通讯录服务开源在 https://gitee.com/wfchat/organization-platform
NSString *ORG_SERVER_ADDRESS = @"https://org.wildfirechat.cn";

// Turn服务配置，用户音视频通话功能，详情参考 https://docs.wildfirechat.net/webrtc/
// 我们提供的服务能力有限，总体带宽仅3Mbps，只能用于用户测试和体验，为了保证测试可用，我们会不定期的更改密码。
// 上线时请一定要切换成你们自己的服务。可以购买腾讯云或者阿里云的轻量服务器，价格很便宜，可以避免影响到您的用户体验。
NSString *ICE_ADDRESS = @"turn:turn.wildfirechat.net:3478";
NSString *ICE_USERNAME = @"wfchat";
NSString *ICE_PASSWORD = @"wfchat123";

//用户协议和隐私政策，上线前请替换成您自己的内容
NSString *USER_PRIVACY_URL = @"https://wildfirechat.net/wildfirechat_user_privacy.html";
NSString *USER_AGREEMENT_URL = @"https://wildfirechat.net/wildfirechat_user_agreement.html";

NSString *FILE_TRANSFER_ID = @"wfc_file_transfer";

//如果想要关掉工作台，把WORK_PLATFORM_URL设置为nil就可以了。工作平台项目地址：https://gitee.com/wfchat/open-platform
//NSString *WORK_PLATFORM_URL = nil;
NSString *WORK_PLATFORM_URL = @"https://open.wildfirechat.cn/work.html";

//语音转文字服务地址。关于语音转文字信息请参考：https://gitee.com/wfchat/asr-api 。
//野火提供的测试服务会记录语音文件和转换后的文字，上线会有可能泄密风险。因此请确保务必上线时购买部署自己的语音转文字服务，或者设置为nil。
//NSString *ASR_SERVICE_URL = nil;
NSString *ASR_SERVICE_URL = @"https://app.wildfirechat.net/asr/api/recognize";

//有2种登录方式，手机号码+验证码登录 和 手机号码+密码登录。
//这个开关是否优先密码登录
BOOL Prefer_Password_Login = YES;

//发送日志命令，当发送此文本消息时，会把协议栈日志发送到当前会话中，为空时关闭此功能。
NSString *Send_Log_Command = @"*#marslog#";

//是否开启水印
BOOL ENABLE_WATER_MARKER = YES;

NSString *AI_ROBOT = @"FireRobot";
