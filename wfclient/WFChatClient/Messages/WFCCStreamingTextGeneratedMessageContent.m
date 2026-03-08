//
//  WFCCStreamingTextGeneratedMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCStreamingTextGeneratedMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"
#import "WFCCUtilities.h"


@implementation WFCCStreamingTextGeneratedMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.searchableContent = self.text;
    payload.content = self.streamId;
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    self.text = payload.searchableContent;
    self.streamId = payload.content;
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_STREAMING_TEXT_GENERATED;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    // 将 Markdown 转换为纯文本用于显示摘要
    return [WFCCUtilities plainTextFromMarkdown:self.text];
}
@end
