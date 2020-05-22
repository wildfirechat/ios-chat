//
//  WFCCConversation.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCReadReport.h"

@implementation WFCCReadReport
+(instancetype)readed:(WFCCConversation *)conversation
               userId:(NSString *)userId
            timestamp:(long long)timestamp {
    WFCCReadReport *d = [[WFCCReadReport alloc] init];
    d.conversation = conversation;
    d.userId = userId;
    d.timestamp = timestamp;
    return d;;
}
@end
