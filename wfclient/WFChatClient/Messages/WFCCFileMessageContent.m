//
//  WFCCSoundMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCFileMessageContent.h"
#import "WFCCUtilities.h"
#import "WFCCIMService.h"
#import "Common.h"

@implementation WFCCFileMessageContent
+ (instancetype)fileMessageContentFromPath:(NSString *)filePath {
    WFCCFileMessageContent *fileMsg = [[WFCCFileMessageContent alloc] init];
    fileMsg.localPath = filePath;
    fileMsg.name = [filePath lastPathComponent];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    fileMsg.size = [fileAttributes fileSize];

    return fileMsg;
}

- (WFCCMessagePayload *)encode {
    WFCCMediaMessagePayload *payload = [[WFCCMediaMessagePayload alloc] init];
    payload.extra = self.extra;
    payload.contentType = [self.class getContentType];
    payload.searchableContent = [NSString stringWithFormat:@"[文件] %@", self.name];
    payload.content = [NSString stringWithFormat:@"%ld", (long)self.size];
    payload.mediaType = Media_Type_FILE;
    
    payload.remoteMediaUrl = self.remoteUrl;
    payload.localMediaPath = self.localPath;
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    if ([payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
        WFCCMediaMessagePayload *mediaPayload = (WFCCMediaMessagePayload *)payload;
        self.remoteUrl = mediaPayload.remoteMediaUrl;
        self.localPath = mediaPayload.localMediaPath;
        self.name = mediaPayload.searchableContent;
        self.size = [mediaPayload.content integerValue];
    }
}


+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_FILE;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}


+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return [NSString stringWithFormat:@"[文件]:%@", self.name];
}
@end
