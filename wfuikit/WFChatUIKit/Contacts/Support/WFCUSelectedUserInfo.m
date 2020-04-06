//
//  WFCSelectedUserInfo.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import "WFCUSelectedUserInfo.h"

@implementation WFCUSelectedUserInfo
- (instancetype)init {
    self = [super init];
    if (self) {
        self.selectedStatus = Unchecked;
    }
    return self;
}
@end
