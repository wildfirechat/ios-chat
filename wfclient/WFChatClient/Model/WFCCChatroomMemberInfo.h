//
//  WFCCChatroomInfo.h
//  WFChatClient
//
//  Created by heavyrain lee on 2018/8/24.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"

@interface WFCCChatroomMemberInfo : WFCCJsonSerializer
@property(nonatomic, assign)int memberCount;
@property(nonatomic, strong)NSArray<NSString *> *members;
@end
