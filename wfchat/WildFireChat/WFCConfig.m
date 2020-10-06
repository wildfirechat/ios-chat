//
//  Config.m
//  Wildfire Chat
//
//  Created by WF Chat on 2017/10/21.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCConfig.h"

//可以是IP，可以是域名，如果是域名的话只支持主域名或www域名或im或imtest的二级域名，其它二级域名不支持！
//例如：example.com或www.example.com或im.example.com或imtest.example.com是支持的；xx.example.com或xx.yy.example.com是不支持的。如果是专业版必须用域名，社区版建议也用域名。
NSString *IM_SERVER_HOST = @"wildfirechat.cn";


// App Server默认使用的是8888端口，替换为自己部署的服务时需要注意端口别填错了，使用http访问appserver时，需要确保appserver的配置文件中的wfc.all_client_support_ssl参数为false
// 正式商用时，建议用https，确保token安全，可以使用nginx反向代理添加对ssl的支持。需要确保appserver的配置文件中的wfc.all_client_support_ssl参数为true
// 如果您使用web-chat，由于最新chrome浏览器的策略，只有使用https才能带上cookie访问appserver的接口，所以就必须使
// wfc.all_client_support_ssl为tue，所以客户端也必须使用https的应用服务地址

//NSString *APP_SERVER_ADDRESS = @"http://wildfirechat.cn:8888";
NSString *APP_SERVER_ADDRESS = @"https://app.wildfirechat.cn";

NSString *ICE_ADDRESS = @"turn:turn.wildfirechat.cn:3478";
NSString *ICE_USERNAME = @"wfchat";
NSString *ICE_PASSWORD = @"wfchat";

//用户协议和隐私政策，上线前请替换成您自己的内容
NSString *USER_PRIVACY_URL = @"https://www.wildfirechat.cn/wildfirechat_user_privacy.html";
NSString *USER_AGREEMENT_URL = @"https://www.wildfirechat.cn/wildfirechat_user_agreement.html";

NSString *FILE_TRANSFER_ID = @"wfc_file_transfer";
