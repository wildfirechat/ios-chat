//
//  WFCCUserOnlineState.h
//  WFChatClient
//
//  Created by heavyrain on 2022/2/17.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"

NS_ASSUME_NONNULL_BEGIN

/*
 int Platform_UNSET = 0;
 int Platform_iOS = 1;
 int Platform_Android = 2;
 int Platform_Windows = 3;
 int Platform_OSX = 4;
 int Platform_WEB = 5;
 int Platform_WX = 6;
 int Platform_LINUX = 7;
 int Platform_iPad = 8;
 int Platform_APad = 9;
 */
@interface WFCCClientState : WFCCJsonSerializer
@property(nonatomic, assign)int platform;
@property(nonatomic, assign)int state; //设备的在线状态，0是在线，1是有session但不在线，其它不在线。
@property(nonatomic, assign)long long lastSeen; //最后可见
@end

@interface WFCCUserCustomState : WFCCJsonSerializer
@property(nonatomic, assign)int state; //0，未设置，1 忙碌，2 离开（主动设置），3 离开（长时间不操作），4 隐身，其它可以自主扩展。
@property(nonatomic, strong)NSString *text;
@end

@interface WFCCUserOnlineState : WFCCJsonSerializer
@property(nonatomic, strong)NSString *userId;
@property(nonatomic, strong)WFCCUserCustomState *customState;
@property(nonatomic, strong)NSArray<WFCCClientState *> *clientStates;
@end

NS_ASSUME_NONNULL_END
