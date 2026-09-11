//
//  app_callback.h
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#ifndef appcomm_callback_h
#define appcomm_callback_h

#import <app/app.h>
#import <app/app_logic.h>

#include <string>
#include <vector>

namespace mars {
    namespace app {


class AppCallBack : public Callback {
    
private:
    AppCallBack();
    ~AppCallBack() {}
    AppCallBack(AppCallBack&);
    AppCallBack& operator = (AppCallBack&);
    std::string filePath;
    AccountInfo info;
    
public:
    static AppCallBack* Instance();
    static void Release();
    
    int GetPushType();
    virtual std::string GetAppFilePath();
    
    virtual AccountInfo GetAccountInfo();
    
    virtual void SetAccountUserName(const std::string &userName);
    virtual void SetAccountLogoned(bool isLogoned);
    
    virtual unsigned int GetClientVersion();
    
    virtual DeviceInfo GetDeviceInfo();
    
    // 返回平台根证书（每项为一张证书或一整份 CA bundle 的原始字节，PEM/DER 均可）。
    // macOS 直接枚举系统锚点证书；iOS 无法枚举系统根证书，改为读取 App Bundle 内置的 CA 文件。
    virtual void GetRootCerts(std::vector<std::string>& _certs);
    
    // iOS/macOS 都能用 Security.framework 直接校验证书链（含系统根 + 用户信任的 CA + 域名）
    virtual bool CanVerifyServerCerts();
    virtual int VerifyServerCerts(const std::vector<std::string> &derChain, const std::string &host);
    
    bool isDBAlreadyCreated(const std::string &clientId);
    
private:
    static AppCallBack* instance_;
};
        
}}

#endif /* appcomm_callback_h */
