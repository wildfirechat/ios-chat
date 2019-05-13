//
//  WFCCMessage.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessage.h"
#import "Common.h"


@implementation WFCCMessage
- (NSString *)digest {
    return [self.content digest:self];
}
@end
