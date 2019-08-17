//
//  WFCCImageMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/2.
//  Copyright © 2017年 wildfire chat. All rights reserved.
//

#import "WFCCImageMessageContent.h"
#import "WFCCNetworkService.h"
#import "WFCCIMService.h"
#import "WFCCUtilities.h"
#import "Common.h"

@interface WFCCImageMessageContent ()
@property (nonatomic, assign)CGSize size;
@end

@implementation WFCCImageMessageContent
+ (instancetype)contentFrom:(UIImage *)image {
    WFCCImageMessageContent *content = [[WFCCImageMessageContent alloc] init];
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
    
    NSString *path = [[WFCCUtilities getDocumentPathWithComponent:@"/IMG"] stringByAppendingPathComponent:[NSString stringWithFormat:@"img%lld.jpg", recordTime]];
    
    image = [WFCCUtilities generateThumbnail:image withWidth:1024 withHeight:1024];
    NSData *imgData = UIImageJPEGRepresentation(image, 0.85);
    
    [imgData writeToFile:path atomically:YES];
    
    content.localPath = path;
    content.size = image.size;
    if (![[WFCCIMService sharedWFCIMService] imageThumbPara]) {
        content.thumbnail = [WFCCUtilities generateThumbnail:image withWidth:120 withHeight:120];
    }
    
    return content;
}
- (WFCCMessagePayload *)encode {
    WFCCMediaMessagePayload *payload = [[WFCCMediaMessagePayload alloc] init];
    payload.extra = self.extra;
    payload.contentType = [self.class getContentType];
    payload.searchableContent = @"[图片]";
    if (![[WFCCIMService sharedWFCIMService] imageThumbPara]) {
        payload.binaryContent = UIImageJPEGRepresentation(self.thumbnail, 0.45);
    }
    
    payload.mediaType = Media_Type_IMAGE;
    payload.remoteMediaUrl = self.remoteUrl;
    payload.localMediaPath = self.localPath;
    payload.content = [NSString stringWithFormat:@"%dx%d", (int)self.size.width, (int)self.size.height];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    if ([payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
        WFCCMediaMessagePayload *mediaPayload = (WFCCMediaMessagePayload *)payload;
        if ([payload.binaryContent length]) {
            self.thumbnail = [UIImage imageWithData:payload.binaryContent];
        }
        self.remoteUrl = mediaPayload.remoteMediaUrl;
        self.localPath = mediaPayload.localMediaPath;
        if (mediaPayload.content.length) {
            NSRange range = [mediaPayload.content rangeOfString:@"x"];
            if (range.location != NSNotFound) {
                NSString *str1 = [mediaPayload.content substringToIndex:range.location];
                NSString *str2 = [mediaPayload.content substringFromIndex:range.location+1];
                self.size = CGSizeMake([str1 intValue], [str2 intValue]);
            }
        }
    }
}

- (UIImage *)thumbnail {
    if (!_thumbnail && self.localPath.length) {
        UIImage *image = [UIImage imageWithContentsOfFile:self.localPath];
        _thumbnail = [WFCCUtilities generateThumbnail:image withWidth:120 withHeight:120];
    }
    return _thumbnail;
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_IMAGE;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}




+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return @"[图片]";
}
@end
