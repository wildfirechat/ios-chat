//
//  app_callback.mm
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#include "app_callback.h"

#import <UIKit/UIKit.h>
#import "WFCCUtilities.h"
#import "sys/utsname.h"
#import "WFCCNetworkService.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

namespace mars {
    namespace app {

AppCallBack* AppCallBack::instance_ = NULL;

AppCallBack* AppCallBack::Instance() {
    if(instance_ == NULL) {
        instance_ = new AppCallBack();
    }
    
    return instance_;
}

void AppCallBack::Release() {
    delete instance_;
    instance_ = NULL;
}
        
    AppCallBack::AppCallBack() {
        
        
    }

        
        void AppCallBack::SetAccountUserName(const std::string &userName) {
            info.username = userName;
            
            NSString *path = [WFCCUtilities getDocumentPathWithComponent:[NSString stringWithUTF8String:info.username.c_str()]];
            filePath = [path UTF8String];
        }
        
        bool AppCallBack::isDBAlreadyCreated(const std::string &clientId) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                 NSUserDomainMask, YES);
            NSString *documentDirectory = [paths objectAtIndex:0];
            NSFileManager *myFileManager = [NSFileManager defaultManager];
            NSString *cid = [NSString stringWithUTF8String:clientId.c_str()];
            BOOL isDir = NO;
            BOOL isExist = NO;
            for (NSString *path in [myFileManager contentsOfDirectoryAtPath:documentDirectory error:nil]) {
                        
                NSString *dbPath = [[[documentDirectory stringByAppendingPathComponent:path] stringByAppendingPathComponent:cid] stringByAppendingPathComponent:@"data"];;
                        
                isExist = [myFileManager fileExistsAtPath:dbPath isDirectory:&isDir];
                if(isExist && !isDir) {
                    return true;
                }
            }
            return false;
        }
    
        void AppCallBack::SetAccountLogoned(bool isLogoned) {
            info.is_logoned = isLogoned;
        }
        
// return your app path
std::string AppCallBack::GetAppFilePath(){
    return filePath;
}
        
AccountInfo AppCallBack::GetAccountInfo() {
    return info;
}

unsigned int AppCallBack::GetClientVersion() {
    
    return 0;
}

static BOOL PSPDFIsDevelopmentBuild() {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    static BOOL isDevelopment = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // There is no provisioning profile in AppStore Apps.
        NSData *data = [NSData dataWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"embedded" ofType:@"mobileprovision"]];
        if (data) {
            const char *bytes = (const char *)[data bytes];
            NSMutableString *profile = [[NSMutableString alloc] initWithCapacity:data.length];
            for (NSUInteger i = 0; i < data.length; i++) {
                [profile appendFormat:@"%c", bytes[i]];
            }
            // Look for debug value, if detected we're a development build.
            NSString *cleared = [[profile componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] componentsJoinedByString:@""];
            isDevelopment = [cleared rangeOfString:@"<key>get-task-allow</key><true/>"].length > 0;
        }
    });
    return isDevelopment;
#endif
}
        
int AppCallBack::GetPushType() {
    return PSPDFIsDevelopmentBuild() ? 1 : 0;
}
        
DeviceInfo AppCallBack::GetDeviceInfo() {
    DeviceInfo info;
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    
    info.clientid = [[[WFCCNetworkService sharedInstance] getClientId] UTF8String];
    info.platform = [WFCCNetworkService sharedInstance].isPad?PlatformType_iPad:PlatformType_iOS;    
    info.packagename = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"] UTF8String];
    info.pushtype = mars::app::AppCallBack::Instance()->GetPushType();
    info.device = [deviceString UTF8String];
    info.deviceversion = [[UIDevice currentDevice].systemVersion UTF8String];
    info.phonename = [[UIDevice currentDevice].name UTF8String];
    
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *currentLanguage = [languages objectAtIndex:0];
    info.language = [currentLanguage UTF8String];
    
    CTTelephonyNetworkInfo *nwinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = nwinfo.subscriberCellularProvider;
    info.carriername = carrier.carrierName ? [carrier.carrierName UTF8String] : "";
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if (appVersion) {
        info.appversion = [appVersion UTF8String];
    }
    
    info.sdkversion = [SDKVERSION UTF8String];
    
    return info;
}

}}
