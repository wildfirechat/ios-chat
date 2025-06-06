//
//  WFCCMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/15.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"
#import "WFCCMediaMessageContent.h"
#import "Common.h"
#import "WFCCDictionary.h"

@implementation WFCCMessagePayload
- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"type"] = @(self.contentType);
    if(self.searchableContent.length) {
        dict[@"searchableContent"] = self.searchableContent;
    }
    if(self.pushContent.length) {
        dict[@"pushContent"] = self.pushContent;
    }
    
    if(self.pushData.length) {
        dict[@"pushData"] = self.pushData;
    }
    
    if(self.content.length) {
        dict[@"content"] = self.content;
    }
    
    if(self.binaryContent.length) {
        dict[@"binaryContent"] = [self.binaryContent base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    }
    
    if(self.localContent.length) {
        dict[@"localContent"] = self.localContent;
    }
    
    if(self.mentionedType) {
        dict[@"mentionedType"] = @(self.mentionedType);
    }
    
    if(self.mentionedTargets.count) {
        dict[@"mentionedTargets"] = self.mentionedTargets;
    }

    if(self.extra.length) {
        dict[@"extra"] = self.extra;
    }
    
    if(self.notLoaded) {
        dict[@"notLoaded"] = @(YES);
    }

    return dict;
}
@end

@implementation WFCCMediaMessagePayload
-(id)toJsonObj {
    NSMutableDictionary *dict = [super toJsonObj];
    dict[@"mediaType"] = @(self.mediaType);
    if(self.remoteMediaUrl.length) {
        dict[@"remoteMediaUrl"] = self.remoteMediaUrl;
    }
    if(self.localMediaPath.length) {
        dict[@"localMediaPath"] = self.localMediaPath;
    }
    return dict;
}
@end

@implementation WFCCMessageContent
+ (void)load {
    
}
- (WFCCMessagePayload *)encode {
    if([self isKindOfClass:[WFCCMediaMessageContent class]]) {
        WFCCMediaMessagePayload *payload = [[WFCCMediaMessagePayload alloc] init];
        WFCCMediaMessageContent *mediaContent = (WFCCMediaMessageContent *)self;
        payload.extra = self.extra;
        payload.contentType = [self.class getContentType];
        payload.localMediaPath = mediaContent.localPath;
        payload.remoteMediaUrl = mediaContent.remoteUrl;
        return payload;
    } else {
        WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
        payload.extra = self.extra;
        payload.contentType = [self.class getContentType];
        return payload;
    }
}

- (void)decode:(WFCCMessagePayload *)payload {
    self.extra = payload.extra;
    self.notLoaded = payload.notLoaded;
}

+ (int)getContentType {
    return 0;
}
+ (int)getContentFlags {
    return 0;
}
- (NSString *)digest:(WFCCMessage *)message {
  return @"Unimplement digest function";
}

- (NSArray *)getArray:(WFCCDictionary *)dict ofKey:(NSString *)key {
    NSObject *obj = dict[key];
    if([obj isKindOfClass:NSArray.class]) {
        return (NSArray *)obj;
    }

    return nil;
}
@end
