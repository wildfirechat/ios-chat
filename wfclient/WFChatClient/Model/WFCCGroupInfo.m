//
//  WFCCGroupInfo.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCGroupInfo.h"

@implementation WFCCGroupInfo
- (NSString *)displayName {
    return self.remark.length?self.remark:self.name;
}
@end
