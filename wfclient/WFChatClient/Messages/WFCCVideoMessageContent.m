//
//  WFCCVideoMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/2.
//  Copyright © 2017年 wildfire chat. All rights reserved.
//

#import "WFCCVideoMessageContent.h"
#import "WFCCNetworkService.h"
#import "WFCCIMService.h"
#import "WFCCUtilities.h"
#import "Common.h"


@implementation WFCCVideoMessageContent
+ (instancetype)contentPath:(NSString *)localPath thumbnail:(UIImage *)image {
    WFCCVideoMessageContent *content = [[WFCCVideoMessageContent alloc] init];
    content.localPath = localPath;
    content.thumbnail = [WFCCUtilities imageWithRightOrientation:image];
    
    return content;
}
- (WFCCMessagePayload *)encode {
    WFCCMediaMessagePayload *payload = [[WFCCMediaMessagePayload alloc] init];
    payload.extra = self.extra;
    payload.contentType = [self.class getContentType];
    payload.searchableContent = @"[视频]";
    payload.binaryContent = UIImageJPEGRepresentation(self.thumbnail, 0.45);
    payload.mediaType = Media_Type_VIDEO;
    payload.remoteMediaUrl = self.remoteUrl;
    payload.localMediaPath = self.localPath;
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    if ([payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
        WFCCMediaMessagePayload *mediaPayload = (WFCCMediaMessagePayload *)payload;
        self.thumbnail = [UIImage imageWithData:payload.binaryContent];
        self.remoteUrl = mediaPayload.remoteMediaUrl;
        self.localPath = mediaPayload.localMediaPath;
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_VIDEO;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}




+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return @"[视频]";
}
@end
