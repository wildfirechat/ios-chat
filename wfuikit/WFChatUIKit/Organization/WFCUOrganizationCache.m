//
//  WFCUOrganizationCache.m
//  WFChatUIKit
//
//  Created by Rain on 2022/12/25.
//  Copyright © 2022 WildfireChat. All rights reserved.
//

#import "WFCUOrganizationCache.h"
#import "WFCUEmployee.h"
#import "WFCUOrganization.h"
#import "WFCUOrgRelationship.h"
#import "WFCUOrganizationEx.h"
#import "WFCUConfigManager.h"
#import "WFCUEmployeeEx.h"
#import <WFChatClient/WFCChatClient.h>

NSString *kRootOrganizationUpdated = @"kRootOrganizationUpdated";
NSString *kMyOrganizationUpdated = @"kMyOrganizationUpdated";
NSString *kOrganizationUpdated = @"kOrganizationUpdated";
NSString *kOrganizationExUpdated = @"kOrganizationExUpdated";
NSString *kEmployeeUpdated = @"kEmployeeUpdated";
NSString *kEmployeeExUpdated = @"kEmployeeExUpdated";
NSString *kOrgRelationUpdated = @"kOrgRelationUpdated";

static WFCUOrganizationCache *sharedSingleton = nil;

@interface WFCUOrganizationCache ()
@property(nonatomic, strong)NSMutableDictionary<NSString *, WFCUEmployee *> *employeeDict;
@property(nonatomic, strong)NSMutableDictionary<NSString *, WFCUEmployeeEx *> *employeeExDict;
@property(nonatomic, strong)NSMutableDictionary<NSNumber *, WFCUOrganization *> *organizationDict;
@property(nonatomic, strong)NSMutableDictionary<NSNumber *, WFCUOrganizationEx *> *organizationExDict;
@property(nonatomic, strong)NSMutableDictionary<NSString *, NSArray<WFCUOrgRelationship *> *> *relationshipDict;
@end

@implementation WFCUOrganizationCache
+ (WFCUOrganizationCache *)sharedCache {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[WFCUOrganizationCache alloc] init];
                sharedSingleton.employeeDict = [[NSMutableDictionary alloc] init];
                sharedSingleton.employeeExDict = [[NSMutableDictionary alloc] init];
                sharedSingleton.organizationDict = [[NSMutableDictionary alloc] init];
                sharedSingleton.organizationExDict = [[NSMutableDictionary alloc] init];
                sharedSingleton.relationshipDict = [[NSMutableDictionary alloc] init];
                [sharedSingleton restoreMyOrganizationInfos];
            }
        }
    }

    return sharedSingleton;
}

- (void)restoreMyOrganizationInfos {
    //restore bottomOrganizationIds, rootOrganizationIds, rootOrganization
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    NSArray *arrBottoms = [[NSUserDefaults standardUserDefaults] objectForKey:@"WFC_bottomOrganizationIds"];
    if([arrBottoms isKindOfClass:[NSArray class]]) {
        [arr addObjectsFromArray:arrBottoms];
        self.bottomOrganizationIds = arrBottoms;
    }
    
    NSArray *arrRoots = [[NSUserDefaults standardUserDefaults] objectForKey:@"WFC_rootOrganizationIds"];
    if([arrRoots isKindOfClass:[NSArray class]]) {
        [arr addObjectsFromArray:arrRoots];
        self.rootOrganizationIds = arrRoots;
    }
    
    [arr enumerateObjectsUsingBlock:^(NSNumber *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"WFC_organization_%ld", [obj integerValue]]];
        if([dict isKindOfClass:[NSDictionary class]]) {
            WFCUOrganization *org = [WFCUOrganization fromDict:dict];
            if(org.organizationId) {
                self.organizationDict[@(org.organizationId)] = org;
            }
        }
    }];
}

- (void)clearCaches {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"WFC_bottomOrganizationIds"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"WFC_rootOrganizationIds"];
    self.bottomOrganizationIds = nil;
    self.rootOrganizationIds = nil;
}

- (void)loadMyOrganizationInfos {
    [[WFCUConfigManager globalManager].orgServiceProvider getRelationship:[WFCCNetworkService sharedInstance].userId  success:^(NSArray<WFCUOrgRelationship *> * _Nonnull relationships) {
        self.relationshipDict[[WFCCNetworkService sharedInstance].userId] = relationships;
        NSMutableArray<NSNumber *> *bottomIds = [[NSMutableArray alloc] init];
        [relationships enumerateObjectsUsingBlock:^(WFCUOrgRelationship * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(obj.bottom) [bottomIds addObject:@(obj.organizationId)];
        }];

        self.bottomOrganizationIds = bottomIds;
        [[NSUserDefaults standardUserDefaults] setObject:self.bottomOrganizationIds forKey:@"WFC_bottomOrganizationIds"];

        if(bottomIds.count) {
            [[WFCUConfigManager globalManager].orgServiceProvider getOrganizations:bottomIds success:^(NSArray<WFCUOrganization *> * _Nonnull organizations) {
                [organizations enumerateObjectsUsingBlock:^(WFCUOrganization * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    self.organizationDict[@(obj.organizationId)] = obj;
                    [[NSUserDefaults standardUserDefaults] setObject:[obj toDict] forKey:[NSString stringWithFormat:@"WFC_organization_%ld", obj.organizationId]];
                }];
            } error:^(int error_code) {

            }];
            [[NSNotificationCenter defaultCenter] postNotificationName:kMyOrganizationUpdated object:nil];
        }
    } error:^(int error_code) {

    }];

    [[WFCUConfigManager globalManager].orgServiceProvider getRootOrganization:^(NSArray<WFCUOrganization *> * _Nonnull organizations) {
        NSMutableArray<NSNumber *> *orgIds = [[NSMutableArray alloc] init];
        [organizations enumerateObjectsUsingBlock:^(WFCUOrganization * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [orgIds addObject:@(obj.organizationId)];
            self.organizationDict[@(obj.organizationId)] = obj;
            [[NSUserDefaults standardUserDefaults] setObject:[obj toDict] forKey:[NSString stringWithFormat:@"WFC_organization_%ld", obj.organizationId]];
        }];
        self.rootOrganizationIds = orgIds;
        [[NSUserDefaults standardUserDefaults] setObject:self.rootOrganizationIds forKey:@"WFC_rootOrganizationIds"];

        [[NSNotificationCenter defaultCenter] postNotificationName:kRootOrganizationUpdated object:nil];
    } error:^(int error_code) {

    }];
}

- (void)getRelationship:(NSString *)employeeId
                refresh:(BOOL)refresh
                success:(void(^)(NSString *employeeId, NSArray<WFCUOrgRelationship *> *rss))successBlock
                  error:(void(^)(int error_code))errorBlock {
    NSArray<WFCUOrgRelationship *> * rs = self.relationshipDict[employeeId];
    if(!rs) {
        refresh = YES;
    } else {
        if(successBlock) successBlock(employeeId, rs);
    }
    
    if(refresh) {
        [[WFCUConfigManager globalManager].orgServiceProvider getRelationship:employeeId success:^(NSArray<WFCUOrgRelationship *> * _Nonnull arr) {
            self.relationshipDict[employeeId] = arr;
            [[NSNotificationCenter defaultCenter] postNotificationName:kOrgRelationUpdated object:employeeId userInfo:@{@"relationships":arr}];
            if(successBlock) successBlock(employeeId, arr);
        } error:^(int error_code) {
            if(errorBlock) errorBlock(error_code);
        }];
    }
}

- (NSArray<WFCUOrgRelationship *> *)getRelationship:(NSString *)employeeId refresh:(BOOL)refresh {
    NSArray<WFCUOrgRelationship *> * rs = self.relationshipDict[employeeId];
    if(!rs) {
        refresh = YES;
    }
    if(refresh) {
        [[WFCUConfigManager globalManager].orgServiceProvider getRelationship:employeeId success:^(NSArray<WFCUOrgRelationship *> * _Nonnull arr) {
            self.relationshipDict[employeeId] = arr;
            [[NSNotificationCenter defaultCenter] postNotificationName:kOrgRelationUpdated object:employeeId userInfo:@{@"relationships":arr}];
        } error:^(int error_code) {
            
        }];
    }
    return rs;
}

- (WFCUEmployee *)getEmployee:(NSString *)employeeId refresh:(BOOL)refresh {
    WFCUEmployee *employee = self.employeeDict[employeeId];
    if(!employee) {
        refresh = YES;
    }
    
    if(refresh) {
        [[WFCUConfigManager globalManager].orgServiceProvider getEmployee:employeeId success:^(WFCUEmployee * _Nonnull employee) {
            self.employeeDict[employeeId] = employee;
            [[NSNotificationCenter defaultCenter] postNotificationName:kEmployeeUpdated object:employeeId userInfo:@{@"employee":employee}];
        } error:^(int error_code) {
            
        }];
    }
    return employee;
}

- (WFCUEmployeeEx *)getEmployeeEx:(NSString *)employeeId refresh:(BOOL)refresh {
    WFCUEmployeeEx *ex = self.employeeExDict[employeeId];
    if(!ex) {
        refresh = YES;
        ex = [[WFCUEmployeeEx alloc] init];
        ex.employeeId = employeeId;
        ex.employee = self.employeeDict[employeeId];
        ex.relationships = self.relationshipDict[employeeId];
    }
    
    if(refresh) {
        [[WFCUConfigManager globalManager].orgServiceProvider getEmployeeEx:employeeId success:^(WFCUEmployeeEx * _Nonnull employeeEx) {
            self.employeeExDict[employeeId] = employeeEx;
            self.employeeDict[employeeId] = employeeEx.employee;
            self.relationshipDict[employeeId] = employeeEx.relationships;
            [[NSNotificationCenter defaultCenter] postNotificationName:kEmployeeExUpdated object:employeeId userInfo:@{@"employee":employeeEx.employee, @"relationships":employeeEx.relationships}];
        } error:^(int error_code) {
            
        }];
    }
    
    return ex;
}

- (WFCUOrganization *)getOrganization:(NSInteger)orgnaizationId refresh:(BOOL)refresh {
    WFCUOrganization *org = self.organizationDict[@(orgnaizationId)];
    if(!org) {
        refresh = YES;
    }
    if(refresh) {
        [[WFCUConfigManager globalManager].orgServiceProvider getOrganizations:@[@(orgnaizationId)] success:^(NSArray<WFCUOrganization *> * _Nonnull organizations) {
            [organizations enumerateObjectsUsingBlock:^(WFCUOrganization * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                self.organizationDict[@(obj.organizationId)] = obj;
            }];
            [[NSNotificationCenter defaultCenter] postNotificationName:kOrganizationUpdated object:@(orgnaizationId) userInfo:@{@"organization":organizations.firstObject}];
        } error:^(int error_code) {
            
        }];
    }
    return org;
}

- (void)getOrganizationEx:(NSInteger)organizationId
                  refresh:(BOOL)refresh
                  success:(void(^)(NSInteger organizationId, WFCUOrganizationEx *ex))successBlock
                    error:(void(^)(int error_code))errorBlock {
    WFCUOrganizationEx *ex = self.organizationExDict[@(organizationId)];
    if(!ex) {
        refresh = YES;
    } else {
        if(successBlock) successBlock(organizationId, ex);
    }
    
    if(refresh) {
        [[WFCUConfigManager globalManager].orgServiceProvider getOrganizationEx:organizationId success:^(WFCUOrganizationEx *newEx) {
            [newEx.subOrganizations enumerateObjectsUsingBlock:^(WFCUOrganization * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                self.organizationDict[@(obj.organizationId)] = obj;
            }];
            
            [newEx.employees enumerateObjectsUsingBlock:^(WFCUEmployee * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                self.employeeDict[obj.employeeId] = obj;
            }];
            self.organizationExDict[@(organizationId)] = newEx;
            [[NSNotificationCenter defaultCenter] postNotificationName:kOrganizationExUpdated object:@(organizationId)];
            if(successBlock) successBlock(organizationId, newEx);
        } error:^(int error_code) {
            if(errorBlock) errorBlock(error_code);
        }];
    }
}

- (WFCUOrganizationEx *)getOrganizationEx:(NSInteger)organizationId refresh:(BOOL)refresh {
    WFCUOrganizationEx *ex = self.organizationExDict[@(organizationId)];
    if(!ex) {
        ex = [[WFCUOrganizationEx alloc] init];
        ex.organizationId = organizationId;
        ex.organization = [self getOrganization:organizationId refresh:NO];
        refresh = YES;
    }
    
    if(refresh) {
        [[WFCUConfigManager globalManager].orgServiceProvider getOrganizationEx:organizationId success:^(WFCUOrganizationEx *newEx) {
            [newEx.subOrganizations enumerateObjectsUsingBlock:^(WFCUOrganization * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                self.organizationDict[@(obj.organizationId)] = obj;
            }];
            
            [newEx.employees enumerateObjectsUsingBlock:^(WFCUEmployee * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                self.employeeDict[obj.employeeId] = obj;
            }];
            self.organizationExDict[@(organizationId)] = newEx;
            [[NSNotificationCenter defaultCenter] postNotificationName:kOrganizationExUpdated object:@(organizationId)];
        } error:^(int error_code) {
            
        }];
    }
    
    return ex;
}
@end
