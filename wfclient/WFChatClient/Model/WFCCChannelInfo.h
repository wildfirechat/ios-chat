//
//  WFCCChatroomInfo.h
//  WFChatClient
//
//  Created by heavyrain lee on 2018/8/24.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WFCCChannelInfo : NSObject
@property(nonatomic, strong)NSString *channelId;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, strong)NSString *portrait;
@property(nonatomic, strong)NSString *owner;
@property(nonatomic, strong)NSString *desc;
@property(nonatomic, strong)NSString *extra;
@property(nonatomic, strong)NSString *secret;
@property(nonatomic, strong)NSString *callback;

//0 public; 1 private; 2 destoryed
@property(nonatomic, assign)int status;
@property(nonatomic, assign)long long updateDt;
@end
