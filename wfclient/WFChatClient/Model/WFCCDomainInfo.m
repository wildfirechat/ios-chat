//
//  WFCCDomainInfo.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCDomainInfo.h"

@implementation WFCCDomainInfo

- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"domainId"] = self.domainId;

    if(self.name.length)
        dict[@"name"] = self.name;

    if(self.desc.length)
        dict[@"desc"] = self.desc;

    if(self.email.length)
        dict[@"email"] = self.email;
    
    if(self.tel.length)
        dict[@"tel"] = self.tel;
    
    if(self.address.length)
        dict[@"address"] = self.address;

    if(self.extra.length)
        dict[@"extra"] = self.extra;

    [self setDict:dict key:@"updateDt" longlongValue:self.updateDt];
    
    return dict;
}
@end
