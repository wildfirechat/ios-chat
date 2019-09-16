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
    content.thumbnail = [WFCCUtilities generateThumbnail:image withWidth:120 withHeight:120];
    
    return content;
}

- (WFCCMessagePayload *)encode {
    WFCCMediaMessagePayload *payload = [[WFCCMediaMessagePayload alloc] init];
    payload.extra = self.extra;
    payload.contentType = [self.class getContentType];
    payload.searchableContent = @"[图片]";
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.thumbParameter.length && self.size.width > 0) {
        [dataDict setValue:self.thumbParameter forKey:@"tp"];
        [dataDict setValue:@(self.size.width) forKey:@"w"];
        [dataDict setValue:@(self.size.height) forKey:@"h"];
    } else if (![[WFCCIMService sharedWFCIMService] imageThumbPara]) {
        dataDict = nil;
        payload.binaryContent = UIImageJPEGRepresentation(self.thumbnail, 0.45);
    } else {
        UIImage *image = [UIImage imageWithContentsOfFile:self.localPath];
        if (image) {
            [dataDict setValue:[[WFCCIMService sharedWFCIMService] imageThumbPara] forKey:@"tp"];
            [dataDict setValue:@(image.size.width) forKey:@"w"];
            [dataDict setValue:@(image.size.height) forKey:@"h"];
        } else {
            payload.binaryContent = UIImageJPEGRepresentation(self.thumbnail, 0.45);
            dataDict = nil;
        }
    }
    
    if (dataDict) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict
                                                       options:kNilOptions
                                                         error:nil];
        payload.content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    payload.mediaType = Media_Type_IMAGE;
    payload.remoteMediaUrl = self.remoteUrl;
    payload.localMediaPath = self.localPath;
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
            NSError *__error = nil;
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[payload.content dataUsingEncoding:NSUTF8StringEncoding]
                                                                       options:kNilOptions
                                                                         error:&__error];
            if (!__error) {
                NSString *str1 = dictionary[@"w"];
                NSString *str2 = dictionary[@"h"];
                self.thumbParameter = dictionary[@"tp"];
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
