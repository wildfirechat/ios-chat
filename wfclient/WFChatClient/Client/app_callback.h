//
//  app_callback.h
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#ifndef appcomm_callback_h
#define appcomm_callback_h

#import <mars/app/app.h>
#import <mars/app/app_logic.h>

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
    
private:
    static AppCallBack* instance_;
};
        
}}

#endif /* appcomm_callback_h */
