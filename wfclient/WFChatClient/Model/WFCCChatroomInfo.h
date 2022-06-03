//
//  WFCCChatroomInfo.h
//  WFChatClient
//
//  Created by heavyrain lee on 2018/8/24.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"

@interface WFCCChatroomInfo : WFCCJsonSerializer
@property(nonatomic, strong)NSString *chatroomId;
@property(nonatomic, strong)NSString *title;
@property(nonatomic, strong)NSString *desc;
@property(nonatomic, strong)NSString *portrait;
@property(nonatomic, strong)NSString *extra;

//0 normal; 1 not started; 2 end
@property(nonatomic, assign)int state;
@property(nonatomic, assign)int memberCount;
@property(nonatomic, assign)long long createDt;
@property(nonatomic, assign)long long updateDt;
@end
