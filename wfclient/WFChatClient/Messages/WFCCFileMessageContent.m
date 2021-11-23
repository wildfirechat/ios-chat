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

//需要兼容android发送的文件，android发送文件Name以"[文件] "开头
const static NSString *FILE_NAME_PREFIX = @"[文件] ";
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
    WFCCMediaMessagePayload *payload = (WFCCMediaMessagePayload *)[super encode];
    payload.searchableContent = self.name;
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
        if([self.name rangeOfString:FILE_NAME_PREFIX].location == 0) {
            self.name = [self.name substringFromIndex:FILE_NAME_PREFIX.length];
        }
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
    return [NSString stringWithFormat:@"[文件]%@", self.name];
}
@end
