//
//  WFCCChatroomInfo.h
//  WFChatClient
//
//  Created by heavyrain lee on 2018/8/24.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCChannelMenu.h"
#import "WFCCJsonSerializer.h"

@interface WFCCChannelInfo : WFCCJsonSerializer
@property(nonatomic, strong)NSString *channelId;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, strong)NSString *portrait;
@property(nonatomic, strong)NSString *owner;
@property(nonatomic, strong)NSString *desc;
@property(nonatomic, strong)NSString *extra;
@property(nonatomic, strong)NSString *secret;
@property(nonatomic, strong)NSString *callback;

//https://docs.wildfirechat.net/base_knowledge/channel.html##频道状态
@property(nonatomic, assign)int status;
@property(nonatomic, assign)long long updateDt;

@property(nonatomic, strong)NSArray<WFCCChannelMenu *> *menus;
@end
