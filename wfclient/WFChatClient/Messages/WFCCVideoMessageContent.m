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
#import <AVFoundation/AVFoundation.h>
#import "WFCCDictionary.h"

@implementation WFCCVideoMessageContent
+ (instancetype)contentPath:(NSString *)localPath thumbnail:(UIImage *)image {
    WFCCVideoMessageContent *content = [[WFCCVideoMessageContent alloc] init];
    content.localPath = localPath;
    content.thumbnail = [WFCCUtilities imageWithRightOrientation:image];
    
    NSURL *videoUrl = [NSURL URLWithString:localPath];
    AVURLAsset *avUrl = [AVURLAsset assetWithURL:videoUrl];
    CMTime time = [avUrl duration];
    content.duration = ceil(time.value/time.timescale);

    return content;
}
- (WFCCMessagePayload *)encode {
    WFCCMediaMessagePayload *payload = (WFCCMediaMessagePayload *)[super encode];
    payload.searchableContent = @"[视频]";
    payload.binaryContent = UIImageJPEGRepresentation(self.thumbnail, 0.45);
    payload.mediaType = Media_Type_VIDEO;
    payload.remoteMediaUrl = self.remoteUrl;
    payload.localMediaPath = self.localPath;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@(_duration) forKey:@"duration"];
    [dict setObject:@(_duration) forKey:@"d"];
    payload.content = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil] encoding:NSUTF8StringEncoding];
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    if ([payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
        WFCCMediaMessagePayload *mediaPayload = (WFCCMediaMessagePayload *)payload;
        self.thumbnail = [UIImage imageWithData:payload.binaryContent];
        self.remoteUrl = mediaPayload.remoteMediaUrl;
        self.localPath = mediaPayload.localMediaPath;
        
        NSError *__error = nil;
        WFCCDictionary *dictionary = [WFCCDictionary fromString:payload.content error:&__error];
        if (!__error) {
            self.duration = [dictionary[@"duration"] longValue];
            if(self.duration == 0) {
                self.duration = [dictionary[@"d"] longValue];
            }
        }
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
