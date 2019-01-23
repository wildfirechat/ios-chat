//
//  WFCCNetworkStatus.h
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SCNetworkReachability.h>

@protocol WFCCNetworkStatusDelegate

-(void) ReachabilityChange:(UInt32)uiFlags;

@end

@interface WFCCNetworkStatus : NSObject {
	__unsafe_unretained id<WFCCNetworkStatusDelegate> m_delWFCNetworkStatus;
}

+ (WFCCNetworkStatus*)sharedInstance;

-(void) Start:(__unsafe_unretained id<WFCCNetworkStatusDelegate>)delWFCNetworkStatus;
-(void) Stop;
-(void) ChangeReach;
- (SCNetworkConnectionFlags)connFlags;
- (bool)isConnectionAvaible;
@end
