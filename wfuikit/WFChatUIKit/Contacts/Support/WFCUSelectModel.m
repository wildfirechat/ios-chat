//
//  WFCSelectedUserInfo.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUSelectModel.h"
#import "WFCUOrganization.h"
#import "WFCUEmployee.h"


@implementation WFCUSelectModel
- (instancetype)init {
    self = [super init];
    if (self) {
        self.selectedStatus = Unchecked;
    }
    return self;
}
@end
