//
//  WFCCMediaMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/6.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMediaMessageContent.h"
#import "WFCCUtilities.h"
#import "Common.h"


@implementation WFCCMediaMessageContent
- (NSString *)localPath {
    _localPath = [WFCCUtilities getSendBoxFilePath:_localPath];
    return _localPath;
}
@end
