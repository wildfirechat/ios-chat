//
//  OrgService.m
//  WildFireChat
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "OrgService.h"
#import <WFChatClient/WFCChatClient.h>
#import "AFNetworking.h"
#import "WFCConfig.h"
#import <WFChatUIKit/WFChatUIKit.h>
#import <WebKit/WebKit.h>

static OrgService *sharedSingleton = nil;

#define WFC_ORGSERVER_AUTH_TOKEN  @"WFC_ORGSERVER_AUTH_TOKEN"
#define AUTHORIZATION_HEADER @"authToken"

@interface OrgService ()
@property(nonatomic, assign)BOOL isServiceAvailable;
@end

@implementation OrgService
+ (OrgService *)sharedOrgService {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[OrgService alloc] init];
            }
        }
    }

    return sharedSingleton;
}

- (void)login:(void(^)(void))successBlock error:(void(^)(int errCode))errorBlock {
    [[WFCCIMService sharedWFCIMService] getAuthCode:@"admin" type:2 host:IM_SERVER_HOST success:^(NSString *authCode) {
        [self post:@"/api/user_login" data:@{@"authCode":authCode} isLogin:YES success:^(NSDictionary *dict) {
            if([dict[@"code"] intValue] == 0) {
                self.isServiceAvailable = YES;
                if(successBlock) successBlock();
            } else {
                if(errorBlock) errorBlock([dict[@"code"] intValue]);
            }
        } error:^(NSError * _Nonnull error) {
            if(errorBlock) errorBlock(-1);
        }];
    } error:^(int error_code) {
        if(errorBlock) errorBlock(error_code);
    }];
}

- (void)getRelationship:(NSString *)employeeId
                success:(void(^)(NSArray<WFCUOrgRelationship *> *))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [self post:@"/api/relationship/employee" data:@{@"employeeId":employeeId} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSMutableArray *result = [[NSMutableArray alloc] init];
            NSArray *arr = dict[@"result"];
            [arr enumerateObjectsUsingBlock:^(NSDictionary  *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                WFCUOrgRelationship *rs = [self relationshipFromDict:obj];
                [result addObject:rs];
            }];
            if(successBlock) successBlock(result);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (WFCUOrganization *)organizationFromDict:(NSDictionary *)obj {
    WFCUOrganization *org = [[WFCUOrganization alloc] init];
    org.organizationId = [obj[@"id"] intValue];
    org.parentId = [obj[@"parentId"] intValue];
    org.managerId = obj[@"managerId"];
    org.name = obj[@"name"];
    org.desc = obj[@"desc"];
    org.portraitUrl = obj[@"portraitUrl"];
    org.tel = obj[@"tel"];
    org.office = obj[@"office"];
    org.groupId = obj[@"groupId"];
    org.memberCount = [obj[@"memberCount"] intValue];
    org.sort = [obj[@"sort"] intValue];
    org.updateDt = [obj[@"updateDt"] longLongValue];
    org.createDt = [obj[@"createDt"] longLongValue];
    return org;
}

- (WFCUEmployee *)employeeFromDict:(NSDictionary *)obj {
    WFCUEmployee *emp = [[WFCUEmployee alloc] init];
    emp.employeeId = obj[@"employeeId"];
    emp.organizationId = [obj[@""] intValue];
    emp.name = obj[@"name"];
    emp.title = obj[@"title"];
    emp.level = [obj[@"level"] intValue];
    emp.mobile = obj[@"mobile"];
    emp.email = obj[@"email"];
    emp.ext = obj[@"ext"];
    emp.office = obj[@"office"];
    emp.city = obj[@"city"];
    emp.portraitUrl = obj[@"portraitUrl"];
    emp.jobNumber = obj[@"jobNumber"];
    emp.joinTime = obj[@"joinTime"];
    emp.type = [obj[@"type"] intValue];
    emp.gender = [obj[@"gender"] intValue];
    emp.sort = [obj[@"sort"] intValue];
    emp.createDt = [obj[@"createDt"] longLongValue];
    emp.updateDt = [obj[@"updateDt"] longLongValue];
    return emp;
}

- (WFCUOrgRelationship *)relationshipFromDict:(NSDictionary *)obj {
    WFCUOrgRelationship *rs = [[WFCUOrgRelationship alloc] init];
    rs.employeeId = obj[@"employeeId"];
    rs.organizationId = [obj[@"organizationId"] intValue];
    rs.depth = [obj[@"depth"] intValue];
    rs.bottom = [obj[@"bottom"] boolValue];
    rs.parentOrganizationId = [obj[@"parentOrganizationId"] intValue];
    return rs;
}

- (void)getRootOrganization:(void(^)(NSArray<WFCUOrganization *> *))successBlock
                      error:(void(^)(int error_code))errorBlock {
    [self post:@"/api/organization/root" data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSMutableArray *result = [[NSMutableArray alloc] init];
            NSArray *arr = dict[@"result"];
            [arr enumerateObjectsUsingBlock:^(NSDictionary  *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                WFCUOrganization *org = [self organizationFromDict:obj];
                [result addObject:org];
            }];
            if(successBlock) successBlock(result);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)getOrganizationEx:(NSInteger)organizationId
                success:(void(^)(WFCUOrganizationEx *ex))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [self post:@"/api/organization/query_ex" data:@{@"id":@(organizationId)} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *d = dict[@"result"];
            WFCUOrganization *org = [self organizationFromDict:d[@"organization"]];
            
            NSMutableArray *subOrgs = [[NSMutableArray alloc] init];
            if(d[@"subOrganizations"]) {
                NSArray *arr = d[@"subOrganizations"];
                [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    WFCUOrganization *org = [self organizationFromDict:obj];
                    [subOrgs addObject:org];
                }];
            }
            
            NSMutableArray *employees = [[NSMutableArray alloc] init];
            if(d[@"employees"]) {
                NSArray *arr = d[@"employees"];
                [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    WFCUEmployee *emp = [self employeeFromDict:obj];
                    [employees addObject:emp];
                }];
            }
            WFCUOrganizationEx *ex = [[WFCUOrganizationEx alloc] init];
            ex.organizationId = organizationId;
            ex.organization = org;
            ex.subOrganizations = subOrgs;
            ex.employees = employees;
            if(successBlock) successBlock(ex);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)getOrganizations:(NSArray<NSNumber *> *)organizationIds
                 success:(void(^)(NSArray<WFCUOrganization *> *organizations))successBlock
                   error:(void(^)(int error_code))errorBlock {
    [self post:@"/api/organization/query_list" data:@{@"ids":organizationIds} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *arr = dict[@"result"];
            NSMutableArray *orgs = [[NSMutableArray alloc] init];
            [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                WFCUOrganization *org = [self organizationFromDict:obj];
                [orgs addObject:org];
            }];
            if(successBlock) successBlock(orgs);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)getBatchOrgEmployees:(NSArray<NSNumber *> *)orgIds
                success:(void(^)(NSArray<NSString *> *employeeIds))successBlock
                       error:(void(^)(int error_code))errorBlock {
    [self post:@"/api/organization/batch_employees" data:@{@"ids":orgIds} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *arr = dict[@"result"];
            if(successBlock) successBlock(arr);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)getOrgEmployees:(NSInteger)orgId
                success:(void(^)(NSArray<NSString *> *employeeIds))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [self post:@"/api/organization/employees" data:@{@"id":@(orgId)} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *arr = dict[@"result"];
            if(successBlock) successBlock(arr);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)getEmployee:(NSString *)employeeId
                 success:(void(^)(WFCUEmployee *employee))successBlock
              error:(void(^)(int error_code))errorBlock {
    [self post:@"/api/employee/query" data:@{@"employeeId":employeeId} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *emp = dict[@"result"];
            WFCUEmployee *employee = [self employeeFromDict:emp];
            if(successBlock) successBlock(employee);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}


- (void)getEmployeeEx:(NSString *)employeeId
              success:(void(^)(WFCUEmployeeEx *employeeEx))successBlock
                error:(void(^)(int error_code))errorBlock {
    [self post:@"/api/employee/query_ex" data:@{@"employeeId":employeeId} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *exDict = dict[@"result"];
            WFCUEmployee *employee = [self employeeFromDict:exDict[@"employee"]];
            NSArray *arr = exDict[@"relationships"];
            NSMutableArray *result = [[NSMutableArray alloc] init];
            [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                WFCUOrgRelationship *rs = [self relationshipFromDict:obj];
                [result addObject:rs];
            }];
            WFCUEmployeeEx *empEx = [[WFCUEmployeeEx alloc] init];
            empEx.employeeId = employeeId;
            empEx.employee = employee;
            empEx.relationships = result;
            
            if(successBlock) successBlock(empEx);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)searchEmployee:(NSInteger)organizationId
               keyword:(NSString *)keyword
               success:(void(^)(NSArray<WFCUEmployee *> *employees))successBlock
                 error:(void(^)(int error_code))errorBlock {
    [self post:@"/api/employee/search" data:@{@"keyword":keyword, @"organizationId":@(organizationId), @"count":@(50), @"page":@(0)} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *exDict = dict[@"result"];
            int totalPages = [exDict[@"totalPages"] intValue];
            int totalCount = [exDict[@"totalCount"] intValue];
            int currentPage = [exDict[@"currentPage"] intValue];
            NSArray<NSDictionary *> *arr = exDict[@"contents"];
            NSMutableArray *result = [[NSMutableArray alloc] init];
            [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                WFCUEmployee *rs = [self employeeFromDict:obj];
                [result addObject:rs];
            }];
            
            if(successBlock) successBlock(result);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)post:(NSString *)path data:(id)data isLogin:(BOOL)isLogin success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSError * _Nonnull error))errorBlock {
    if(!isLogin && !self.isServiceAvailable) {
        NSLog(@"组织通讯录服务不可用，请确保先登录再使用组织通讯录");
        errorBlock([NSError errorWithDomain:@"" code:401 userInfo:@{NSLocalizedDescriptionKey:@"未登录"}]);
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    
    //在调用其他接口时需要把token传给后台，也就是设置token的过程
    NSString *authToken = [self getOrgServiceAuthToken];
    if(authToken.length) {
        [manager.requestSerializer setValue:authToken forHTTPHeaderField:AUTHORIZATION_HEADER];
    }
    
    [manager POST:[ORG_SERVER_ADDRESS stringByAppendingPathComponent:path]
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
                    [[NSUserDefaults standardUserDefaults] setObject:appToken forKey:WFC_ORGSERVER_AUTH_TOKEN];
                }
            }
        
            NSDictionary *dict = responseObject;
            if([dict[@"code"] intValue] > 0) {
                NSLog(@"API request failure:%@", dict[@"message"]);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
              successBlock(dict);
            });
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"Http request failure:%@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                errorBlock(error);
            });
          }];
}

- (NSString *)getOrgServiceAuthToken {
    return [[NSUserDefaults standardUserDefaults] objectForKey:WFC_ORGSERVER_AUTH_TOKEN];
}

- (void)clearOrgServiceAuthInfos {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WFC_ORGSERVER_AUTH_TOKEN];
    
    //remove kit org cache
    [[WFCUOrganizationCache sharedCache] clearCaches];
}

@end
