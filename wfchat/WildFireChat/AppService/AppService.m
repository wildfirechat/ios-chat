//
//  AppService.m
//  WildFireChat
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "AppService.h"
#import <WFChatClient/WFCChatClient.h>
#import "AFNetworking.h"
#import "WFCConfig.h"
#import "PCSessionViewController.h"
#import <WFChatUIKit/WFChatUIKit.h>
#import "SharePredefine.h"
#import <WebKit/WebKit.h>

static AppService *sharedSingleton = nil;

#define WFC_APPSERVER_COOKIES @"WFC_APPSERVER_COOKIES"
#define WFC_APPSERVER_AUTH_TOKEN  @"WFC_APPSERVER_AUTH_TOKEN"

#define AUTHORIZATION_HEADER @"authToken"

@implementation AppService 
+ (AppService *)sharedAppService {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[AppService alloc] init];
            }
        }
    }

    return sharedSingleton;
}

- (void)loginWithMobile:(NSString *)mobile verifyCode:(NSString *)verifyCode success:(void(^)(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    int platform = [WFCCNetworkService sharedInstance].isPad?Platform_iPad:Platform_iOS;
    [self post:@"/login" data:@{@"mobile":mobile, @"code":verifyCode, @"clientId":[[WFCCNetworkService sharedInstance] getClientId], @"platform":@(platform)} isLogin:YES success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSString *userId = dict[@"result"][@"userId"];
            NSString *token = dict[@"result"][@"token"];
            BOOL newUser = [dict[@"result"][@"register"] boolValue];
            NSString *resetCode = dict[@"result"][@"resetCode"];
            if([resetCode isKindOfClass:[NSNull class]]) {
                resetCode = nil;
            }
            if(successBlock) successBlock(userId, token, newUser, resetCode);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}

- (void)loginWithMobile:(NSString *)mobile password:(NSString *)password success:(void(^)(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    int platform = Platform_iOS;
    //如果使用pad端类型，这里平台改成pad类型，另外app_callback.mm文件中把平台也改成ipad，请搜索"iPad"
    //if(当前设备是iPad)
    //platform = Platform_iPad
    [self post:@"/login_pwd" data:@{@"mobile":mobile, @"password":password, @"clientId":[[WFCCNetworkService sharedInstance] getClientId], @"platform":@(platform)} isLogin:YES success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSString *userId = dict[@"result"][@"userId"];
            NSString *token = dict[@"result"][@"token"];
            BOOL newUser = [dict[@"result"][@"register"] boolValue];
            NSString *resetCode = dict[@"result"][@"resetCode"];
            if([resetCode isKindOfClass:[NSNull class]]) {
                resetCode = nil;
            }
            if(successBlock) successBlock(userId, token, newUser, resetCode);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}

- (void)resetPassword:(NSString *)mobile code:(NSString *)code newPassword:(NSString *)newPassword success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    NSDictionary *data;
    if (mobile.length) {
        data = @{@"mobile":mobile, @"resetCode":code, @"newPassword":newPassword};
    } else {
        data = @{@"resetCode":code, @"newPassword":newPassword};
    }
    [self post:@"/reset_pwd" data:data isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}

- (void)changePassword:(NSString *)oldPassword newPassword:(NSString *)newPassword success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/change_pwd" data:@{@"oldPassword":oldPassword, @"newPassword":newPassword} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}

- (void)sendLoginCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock {
    
    [self post:@"/send_code" data:@{@"mobile":phoneNumber} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock(@"error");
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(error.localizedDescription);
    }];
}

- (void)sendResetCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock {
    NSDictionary *data = @{};
    if (phoneNumber.length) {
        data = @{@"mobile":phoneNumber};
    }
    [self post:@"/send_reset_code" data:data isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock(@"error");
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(error.localizedDescription);
    }];
}

- (void)sendDestroyAccountCode:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/send_destroy_code" data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], @"error");
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)destroyAccount:(NSString *)code success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/destroy" data:@{@"code":code} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], @"error");
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)pcScaned:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = [NSString stringWithFormat:@"/scan_pc/%@", sessionId];
    [self post:path data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], @"Network error");
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)pcConfirmLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/confirm_pc";
    NSDictionary *param = @{@"token":sessionId, @"user_id":[WFCCNetworkService sharedInstance].userId, @"quick_login":@(1)};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], @"Network error");
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)pcCancelLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/cancel_pc";
    NSDictionary *param = @{@"token":sessionId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], @"Network error");
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getGroupAnnouncement:(NSString *)groupId
                     success:(void(^)(WFCUGroupAnnouncement *))successBlock
                      error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"wfc_group_an_%@", groupId]];
    
        WFCUGroupAnnouncement *an = [[WFCUGroupAnnouncement alloc] init];
        an.data = data;
        an.groupId = groupId;
        
        successBlock(an);
    }
    
    NSString *path = @"/get_group_announcement";
    NSDictionary *param = @{@"groupId":groupId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0 || [dict[@"code"] intValue] == 12) {
            WFCUGroupAnnouncement *an = [[WFCUGroupAnnouncement alloc] init];
            an.groupId = groupId;
            if ([dict[@"code"] intValue] == 0) {
                an.author = dict[@"result"][@"author"];
                an.text = dict[@"result"][@"text"];
                an.timestamp = [dict[@"result"][@"timestamp"] longValue];
            }
            
            [[NSUserDefaults standardUserDefaults] setValue:an.data forKey:[NSString stringWithFormat:@"wfc_group_an_%@", groupId]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if(successBlock) successBlock(an);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)updateGroup:(NSString *)groupId
       announcement:(NSString *)announcement
            success:(void(^)(long timestamp))successBlock
              error:(void(^)(int error_code))errorBlock {
    
    NSString *path = @"/put_group_announcement";
    NSDictionary *param = @{@"groupId":groupId, @"author":[WFCCNetworkService sharedInstance].userId, @"text":announcement};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            WFCUGroupAnnouncement *an = [[WFCUGroupAnnouncement alloc] init];
            an.groupId = groupId;
            an.author = [WFCCNetworkService sharedInstance].userId;
            an.text = announcement;
            an.timestamp = [dict[@"result"][@"timestamp"] longValue];
            
            
            [[NSUserDefaults standardUserDefaults] setValue:an.data forKey:[NSString stringWithFormat:@"wfc_group_an_%@", groupId]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if(successBlock) successBlock(an.timestamp);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)getGroupMembersForPortrait:(NSString *)groupId
                           success:(void(^)(NSArray<NSDictionary<NSString *, NSString *> *> *groupMembers))successBlock
                             error:(void(^)(int error_code))errorBlock {
    NSString *path = @"/group/members_for_portrait";
    [self post:path data:@{@"groupId":groupId} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if([dict[@"result"] isKindOfClass:NSArray.class]) {
                NSArray *arr = (NSArray *)dict[@"result"];
                if(successBlock) successBlock(arr);
            }
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)post:(NSString *)path data:(id)data isLogin:(BOOL)isLogin success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSError * _Nonnull error))errorBlock {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    
    //在调用其他接口时需要把cookie传给后台，也就是设置cookie的过程
    NSString *authToken = [self getAppServiceAuthToken];
    if(authToken.length) {
        [manager.requestSerializer setValue:authToken forHTTPHeaderField:AUTHORIZATION_HEADER];
    } else {
        NSData *cookiesdata = [self getAppServiceCookies];//url和登录时传的url 是同一个
        if([cookiesdata length]) {
            NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
            NSHTTPCookie *cookie;
            for (cookie in cookies) {
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
            }
        }
    }
    
    [manager POST:[APP_SERVER_ADDRESS stringByAppendingPathComponent:path]
       parameters:data
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if(isLogin) { //鉴权信息
                NSString *appToken;
                if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *r = (NSHTTPURLResponse *)task.response;
                    appToken = [r allHeaderFields][AUTHORIZATION_HEADER];
                }

                if(appToken.length) {
                    [[NSUserDefaults standardUserDefaults] setObject:appToken forKey:WFC_APPSERVER_AUTH_TOKEN];
                } else {
                    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: [NSURL URLWithString:APP_SERVER_ADDRESS]];
                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
                    [[NSUserDefaults standardUserDefaults] setObject:data forKey:WFC_APPSERVER_COOKIES];
                }
            }
        
            NSDictionary *dict = responseObject;
            dispatch_async(dispatch_get_main_queue(), ^{
              successBlock(dict);
            });
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                errorBlock(error);
            });
          }];
}

- (void)uploadLogs:(void(^)(void))successBlock error:(void(^)(NSString *errorMsg))errorBlock {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray<NSString *> *logFiles = [[WFCCNetworkService getLogFilesPath]  mutableCopy];
        
        NSMutableArray *uploadedFiles = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"mars_uploaded_files"] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj1 compare:obj2];
        }] mutableCopy];
        
        //日志文件列表需要删除掉已上传记录，避免重复上传。
        //但需要上传最后一条已经上传日志，因为那个日志文件可能在上传之后继续写入了，所以需要继续上传
        if (uploadedFiles.count) {
            [uploadedFiles removeLastObject];
        } else {
            uploadedFiles = [[NSMutableArray alloc] init];
        }
        for (NSString *file in [logFiles copy]) {
            NSString *name = [file componentsSeparatedByString:@"/"].lastObject;
            if ([uploadedFiles containsObject:name]) {
                [logFiles removeObject:file];
            }
        }
        
        
        __block NSString *errorMsg = nil;
        
        for (NSString *logFile in logFiles) {
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
            
            NSString *url = [APP_SERVER_ADDRESS stringByAppendingFormat:@"/logs/%@/upload", [WFCCNetworkService sharedInstance].userId];
            
             dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            __block BOOL success = NO;

            [manager POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                NSData *logData = [NSData dataWithContentsOfFile:logFile];
                if (!logData.length) {
                    logData = [@"empty" dataUsingEncoding:NSUTF8StringEncoding];
                }
                
                NSString *fileName = [[NSURL URLWithString:logFile] lastPathComponent];
                [formData appendPartWithFileData:logData name:@"file" fileName:fileName mimeType:@"application/octet-stream"];
            } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                if ([responseObject isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *dict = (NSDictionary *)responseObject;
                    if([dict[@"code"] intValue] == 0) {
                        NSLog(@"上传成功");
                        success = YES;
                        NSString *name = [logFile componentsSeparatedByString:@"/"].lastObject;
                        [uploadedFiles removeObject:name];
                        [uploadedFiles addObject:name];
                        [[NSUserDefaults standardUserDefaults] setObject:uploadedFiles forKey:@"mars_uploaded_files"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                }
                if (!success) {
                    errorMsg = @"服务器响应错误";
                }
                dispatch_semaphore_signal(sema);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"上传失败：%@", error);
                dispatch_semaphore_signal(sema);
                errorMsg = error.localizedFailureReason;
            }];
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            
            if (!success) {
                errorBlock(errorMsg);
                return;
            }
        }
        
        successBlock();
    });
    
}


- (void)getMyPrivateConferenceId:(void(^)(NSString *conferenceId))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/conference/get_my_id" data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            NSString *conferenceId = dict[@"result"];
            successBlock(conferenceId);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)createConference:(WFZConferenceInfo *)conferenceInfo success:(void(^)(NSString *conferenceId))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/conference/create" data:[conferenceInfo toDictionary] isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            NSString *conferenceId = dict[@"result"];
            conferenceInfo.conferenceId = conferenceId;
            successBlock(conferenceId);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)updateConference:(WFZConferenceInfo *)conferenceInfo success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/conference/put_info" data:[conferenceInfo toDictionary] isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)recordConference:(NSString *)conferenceId record:(BOOL)record success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/recording/%@", conferenceId] data:@{@"recording":@(record)} isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)focusConference:(NSString *)conferenceId userId:(NSString *)focusUserId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/focus/%@", conferenceId] data:@{@"userId":(focusUserId?focusUserId:@"")} isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)queryConferenceInfo:(NSString *)conferenceId password:(NSString *)password success:(void(^)(WFZConferenceInfo *conferenceInfo))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSDictionary *data;
    if(password.length) {
        data = @{@"conferenceId":conferenceId, @"password":password};
    } else {
        data = @{@"conferenceId":conferenceId};
    }
    
    [self post:@"/conference/info" data:data isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            WFZConferenceInfo *info = [WFZConferenceInfo fromDictionary:dict[@"result"]];
            successBlock(info);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)destroyConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/destroy/%@", conferenceId] data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kCONFERENCE_DESTROYED object:nil];
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)favConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/fav/%@", conferenceId] data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)unfavConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/unfav/%@", conferenceId] data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)isFavConference:(NSString *)conferenceId success:(void(^)(BOOL isFav))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/is_fav/%@", conferenceId] data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock(YES);
        } else if(code == 16) {
            successBlock(NO);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getFavConferences:(void(^)(NSArray<WFZConferenceInfo *> *))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/conference/fav_conferences" data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            NSArray<NSDictionary *> *ls = dict[@"result"];
            NSMutableArray *output = [[NSMutableArray alloc] init];
            [ls enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [output addObject:[WFZConferenceInfo fromDictionary:obj]];
            }];
            successBlock(output);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)changeName:(NSString *)newName success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/change_name" data:@{@"newName":newName} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errmsg;
            if ([dict[@"code"] intValue] == 17) {
                errmsg = @"用户名已经存在";
            } else {
                errmsg = @"网络错误";
            }
            if(errorBlock) errorBlock([dict[@"code"] intValue], errmsg);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)showPCSessionViewController:(UIViewController *)baseController pcClient:(WFCCPCOnlineInfo *)clientInfo {
    PCSessionViewController *vc = [[PCSessionViewController alloc] init];
    vc.pcClientInfo = clientInfo;
    vc.hidesBottomBarWhenPushed = YES;
    [baseController.navigationController pushViewController:vc animated:YES];
}

- (void)addDevice:(NSString *)name
         deviceId:(NSString *)deviceId
            owner:(NSArray<NSString *> *)owners
          success:(void(^)(Device *device))successBlock
            error:(void(^)(int error_code))errorBlock {
    NSString *path = @"/things/add_device";
    
    NSDictionary *extraDict = @{@"name":name};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extraDict options:0 error:0];
    NSString *dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSDictionary *param = @{@"deviceId":deviceId, @"owners":owners, @"extra":dataStr};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            Device *device = [[Device alloc] init];
            device.deviceId = dict[@"deviceId"];
            device.name = name;
            device.token = dict[@"token"];
            device.secret = dict[@"secret"];
            device.owners = owners;
            if(successBlock) successBlock(device);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)getMyDevices:(void(^)(NSArray<Device *> *devices))successBlock
               error:(void(^)(int error_code))errorBlock {
    NSString *path = @"/things/list_device";
    [self post:path data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if ([dict[@"result"] isKindOfClass:[NSArray class]]) {
                NSMutableArray *output = [[NSMutableArray alloc] init];
                NSArray<NSDictionary *> *ds = (NSArray *)dict[@"result"];
                for (NSDictionary *d in ds) {
                    Device *device = [[Device alloc] init];
                    device.deviceId = [d objectForKey:@"deviceId"];
                    device.secret = [d objectForKey:@"secret"];
                    device.token = [d objectForKey:@"token"];
                    device.owners = [d objectForKey:@"owners"];
                    
                    NSString *extra = d[@"extra"];
                    if (extra.length) {
                        NSData *jsonData = [extra dataUsingEncoding:NSUTF8StringEncoding];
                        NSError *err;
                        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                            options:NSJSONReadingMutableContainers
                                                                              error:&err];
                        if(!err) {
                            device.name = dic[@"name"];
                        }
                    }
                    [output addObject:device];
                }
                if(successBlock) successBlock(output);
            } else {
                if(errorBlock) errorBlock(-1);
            }
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)delDevice:(NSString *)deviceId
          success:(void(^)(Device *device))successBlock
            error:(void(^)(int error_code))errorBlock {
    NSString *path = @"/things/del_device";
    NSDictionary *param = @{@"deviceId":deviceId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock(nil);
        } else {
            errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)getFavoriteItems:(int )startId
                   count:(int)count
                 success:(void(^)(NSArray<WFCUFavoriteItem *> *items, BOOL hasMore))successBlock
                   error:(void(^)(int error_code))errorBlock {
    NSString *path = @"/fav/list";
    NSDictionary *param = @{@"id":@(startId), @"count":@(count)};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *result = dict[@"result"];
            BOOL hasMore = [result[@"hasMore"] boolValue];
            NSArray<NSDictionary *> *arrs = (NSArray *)result[@"items"];
            NSMutableArray<WFCUFavoriteItem *> *output = [[NSMutableArray alloc] init];
            for (NSDictionary *d in arrs) {
                WFCUFavoriteItem *item = [[WFCUFavoriteItem alloc] init];
                item.conversation = [WFCCConversation conversationWithType:[d[@"convType"] intValue] target:d[@"convTarget"] line:[d[@"convLine"] intValue]];
                item.favId = [d[@"id"] intValue];
                if(![d[@"messageUid"] isEqual:[NSNull null]])
                    item.messageUid = [d[@"messageUid"] longLongValue];
                item.timestamp = [d[@"timestamp"] longLongValue];
                if(!d[@"url"] && ![d[@"url"] isEqual:[NSNull null]]) {
                    item.url = d[@"url"];
                    if (item.url.length && [WFCCNetworkService sharedInstance].urlRedirector) {
                        item.url = [[WFCCNetworkService sharedInstance].urlRedirector redirect:item.url];
                    }
                }
                
                item.favType = [d[@"type"] intValue];
                item.title = d[@"title"];
                item.data = d[@"data"];
                item.origin = d[@"origin"];
                item.thumbUrl = d[@"thumbUrl"];
                item.sender = d[@"sender"];
                
                [output addObject:item];
            }
            if(successBlock) successBlock(output, hasMore);
        } else {
            errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)addFavoriteItem:(WFCUFavoriteItem *)item
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    NSString *path = @"/fav/add";
    NSDictionary *param = @{@"type":@(item.favType),
                            @"messageUid":@(item.messageUid),
                            @"convType":@(item.conversation.type),
                            @"convLine":@(item.conversation.line),
                            @"convTarget":item.conversation.target?item.conversation.target:@"",
                            @"origin":item.origin?item.origin:@"",
                            @"sender":item.sender?item.sender:@"",
                            @"title":item.title?item.title:@"",
                            @"url":item.url?item.url:@"",
                            @"thumbUrl":item.thumbUrl?item.thumbUrl:@"",
                            @"data":item.data?item.data:@""
    };
    
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)removeFavoriteItem:(int)favId
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock {
    NSString *path = [NSString stringWithFormat:@"/fav/del/%d", favId];
    
    [self post:path data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

static inline BOOL isHTTPURL(NSString *str) {
    if (str.length == 0) return NO;
    
    NSString *s = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *low = [s lowercaseString];
    if (![low hasPrefix:@"http://"] && ![low hasPrefix:@"https://"] && ![low hasPrefix:@"ftp://"]) return NO;
    
    NSError *e = nil;
    NSDataDetector *d = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&e];
    NSTextCheckingResult *m = [d firstMatchInString:s options:0 range:NSMakeRange(0, s.length)];
    
    return m && m.range.location == 0 && m.range.length == s.length;
}

- (NSString *)userDefaultPortrait:(WFCCUserInfo *)userInfo {
    if(isHTTPURL(userInfo.portrait)) {
        return userInfo.portrait;
    } else {
        return [APP_SERVER_ADDRESS stringByAppendingFormat:@"/avatar?name=%@", userInfo.displayName];
    }
}

- (NSString *)groupDefaultPortrait:(WFCCGroupInfo *)groupInfo memberInfos:(NSArray<WFCCUserInfo *> *)memberInfos {
    if(groupInfo.portrait.length) {
        return groupInfo.portrait;
    }
    
    NSMutableArray *reqMembers = [[NSMutableArray alloc] init];
    [memberInfos enumerateObjectsUsingBlock:^(WFCCUserInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(isHTTPURL(obj.portrait) && [obj.portrait rangeOfString:APP_SERVER_ADDRESS].location == NSNotFound) {
            [reqMembers addObject:@{@"avatarUrl" : obj.portrait}];
        } else {
            [reqMembers addObject:@{@"name" : obj.displayName}];
        }
    }];
    NSDictionary *request = @{@"members" : reqMembers};
    NSError * err;
    NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:request options:0 error:&err];

    return [APP_SERVER_ADDRESS stringByAppendingFormat:@"/avatar/group?request=%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
}

- (NSData *)getAppServiceCookies {
    return [[NSUserDefaults standardUserDefaults] objectForKey:WFC_APPSERVER_COOKIES];
}

- (NSString *)getAppServiceAuthToken {
    return [[NSUserDefaults standardUserDefaults] objectForKey:WFC_APPSERVER_AUTH_TOKEN];
}

- (void)clearAppServiceAuthInfos {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WFC_APPSERVER_COOKIES];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WFC_APPSERVER_AUTH_TOKEN];
    
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WFC_SHARE_APP_GROUP_ID];//此处id要与开发者中心创建时一致
        
    [sharedDefaults removeObjectForKey:WFC_SHARE_APPSERVICE_AUTH_TOKEN];
    NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] cookies];
    [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] deleteCookie:obj];
    }];
    

    [[WKWebsiteDataStore defaultDataStore] fetchDataRecordsOfTypes:[WKWebsiteDataStore allWebsiteDataTypes] completionHandler:^(NSArray * __nonnull records) {
        for (WKWebsiteDataRecord *record in records) {
            [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:record.dataTypes forDataRecords:@[record] completionHandler:^{}];
        }
    }];
}

@end
