//
//  WFCCNetworkStatus.m
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCNetworkStatus.h"

#import <Foundation/Foundation.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <SystemConfiguration/SCNetworkReachability.h>
#import <netinet/in.h>

SCNetworkReachabilityRef g_Reach = nil;

static void ReachCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void* info)
{
    @autoreleasepool {
        [(__bridge id)info performSelector:@selector(ChangeReach)];
    }
}

@implementation WFCCNetworkStatus

static WFCCNetworkStatus * sharedSingleton = nil;

+ (WFCCNetworkStatus*)sharedInstance {
    @synchronized (self) {
        if (sharedSingleton == nil) {
            sharedSingleton = [[WFCCNetworkStatus alloc] init];
        }
    }
    
    return sharedSingleton;
}

-(void) Start:(__unsafe_unretained id<WFCCNetworkStatusDelegate>)delWFCNetworkStatus {
    
    m_delWFCNetworkStatus = delWFCNetworkStatus;
    
    if (g_Reach == nil) {
        struct sockaddr_in zeroAddress;
        bzero(&zeroAddress, sizeof(zeroAddress));
        zeroAddress.sin_len = sizeof(zeroAddress);
        zeroAddress.sin_family = AF_INET;
        g_Reach = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (struct sockaddr *)&zeroAddress);
    }

  
    SCNetworkReachabilityContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
    if(SCNetworkReachabilitySetCallback(g_Reach, ReachCallback, &context)) {
        if(!SCNetworkReachabilityScheduleWithRunLoop(g_Reach, CFRunLoopGetCurrent(), kCFRunLoopCommonModes)) {

            SCNetworkReachabilitySetCallback(g_Reach, NULL, NULL);
            return;
        }
    }
    

    
}

-(void) Stop {
    if(g_Reach != nil) {
        SCNetworkReachabilitySetCallback(g_Reach, NULL, NULL);
        SCNetworkReachabilityUnscheduleFromRunLoop(g_Reach, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFRelease(g_Reach);
        g_Reach = nil;
    }

    m_delWFCNetworkStatus = nil;
}

- (bool)isConnectionAvaible {
    SCNetworkConnectionFlags connFlags = [self connFlags];
    return (connFlags & kSCNetworkFlagsReachable) || (connFlags & kSCNetworkFlagsConnectionRequired);
}

- (SCNetworkConnectionFlags)connFlags {
    SCNetworkConnectionFlags connFlags;
    
    
    if(g_Reach == nil || !SCNetworkReachabilityGetFlags(g_Reach, &connFlags)) {
        return 0;
    }
    return connFlags;
}

-(void) ChangeReach {
    
    SCNetworkConnectionFlags connFlags = [self connFlags];
   
    if(m_delWFCNetworkStatus != nil) {
        [m_delWFCNetworkStatus ReachabilityChange:connFlags];
    }


}

@end
