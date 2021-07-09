//
//  Config.m
//  Wildfire Chat
//
//  Created by WF Chat on 2017/10/21.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCConfig.h"

//域名，注意不能带http头，也不能带端口。
NSString *IM_SERVER_HOST = @"wildfirechat.net";


// App Server默认使用的是8888端口，替换为自己部署的服务时需要注意端口别填错了，使用http访问appserver时，需要确保appserver的配置文件中的wfc.all_client_support_ssl参数为false
// 正式商用时，建议用https，确保token安全，可以使用nginx反向代理添加对ssl的支持。需要确保appserver的配置文件中的wfc.all_client_support_ssl参数为true
// 如果您使用web-chat，由于最新chrome浏览器的策略，只有使用https才能带上cookie访问appserver的接口，所以就必须使
// wfc.all_client_support_ssl为tue，所以客户端也必须使用https的应用服务地址

//NSString *APP_SERVER_ADDRESS = @"http://wildfirechat.net:8888";
NSString *APP_SERVER_ADDRESS = @"https://app.wildfirechat.net";

// Turn服务配置，用户音视频通话功能，详情参考 https://docs.wildfirechat.net/webrtc/
// 我们提供的服务仅供用户测试和体验，上线时请切换成你们自己的服务。
NSString *ICE_ADDRESS = @"turn:turn.wildfirechat.net:3478";
NSString *ICE_USERNAME = @"wfchat";
NSString *ICE_PASSWORD = @"wfchat";

//用户协议和隐私政策，上线前请替换成您自己的内容
NSString *USER_PRIVACY_URL = @"https://wildfirechat.net/wildfirechat_user_privacy.html";
NSString *USER_AGREEMENT_URL = @"https://wildfirechat.net/wildfirechat_user_agreement.html";

NSString *FILE_TRANSFER_ID = @"wfc_file_transfer";
