//
//  WFCCImageMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/2.
//  Copyright © 2017年 wildfire chat. All rights reserved.
//

#import "WFCCStickerMessageContent.h"
#import "WFCCNetworkService.h"
#import "WFCCIMService.h"
#import "WFCCUtilities.h"
#import "Common.h"


@implementation WFCCStickerMessageContent
+ (instancetype)contentFrom:(NSString *)stickerPath {
    WFCCStickerMessageContent *content = [[WFCCStickerMessageContent alloc] init];
    content.localPath = stickerPath;
    content.size = [UIImage imageWithContentsOfFile:stickerPath].size;
    return content;
}

- (WFCCMessagePayload *)encode {
    WFCCMediaMessagePayload *payload = [[WFCCMediaMessagePayload alloc] init];
    payload.extra = self.extra;
    payload.contentType = [self.class getContentType];
    payload.searchableContent = @"[动态表情]";
    payload.mediaType = Media_Type_STICKER;
    payload.remoteMediaUrl = self.remoteUrl;
    payload.localMediaPath = self.localPath;
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:@(self.size.width) forKey:@"x"];
    [dataDict setObject:@(self.size.height) forKey:@"y"];
    
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                            options:kNilOptions
                                                              error:nil];
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    if ([payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
        WFCCMediaMessagePayload *mediaPayload = (WFCCMediaMessagePayload *)payload;
        self.remoteUrl = mediaPayload.remoteMediaUrl;
        self.localPath = mediaPayload.localMediaPath;
    }
    
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.size = CGSizeMake([dictionary[@"x"] floatValue], [dictionary[@"y"] floatValue]);
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_STICKER;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}




+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return @"[动态表情]";
}
@end
