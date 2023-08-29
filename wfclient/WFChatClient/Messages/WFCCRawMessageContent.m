//
//  WFCCRawMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCRawMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"
#import <UIKit/UIKit.h>
#import "WFCCUtilities.h"


@implementation WFCCRawMessageContent
- (WFCCMessagePayload *)encode {
    if(self.payload.contentType == MESSAGE_CONTENT_TYPE_IMAGE && !self.payload.binaryContent.length) {
        if([self.payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
            WFCCMediaMessagePayload *mediaPayload = (WFCCMediaMessagePayload *)self.payload;
            if(mediaPayload.localMediaPath.length) {
                UIImage *image = [UIImage imageWithContentsOfFile:mediaPayload.localMediaPath];
                if(image) {
                    UIImage *thumbnail = [WFCCUtilities generateThumbnail:image withWidth:120 withHeight:120];
                    self.payload.binaryContent = UIImageJPEGRepresentation(thumbnail, 0.45);
                }
            }
        }
    }
    return self.payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    self.payload = payload;
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_UNKNOWN;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_NOT_PERSIST;
}

+ (instancetype)contentOfPayload:(WFCCMessagePayload *)payload {
    if(!payload)
        return nil;
    
    WFCCRawMessageContent *raw = [[WFCCRawMessageContent alloc] init];
    raw.payload = payload;
    raw.extra = payload.extra;
    return raw;
}

- (NSString *)digest:(WFCCMessage *)message {
  return nil;
}
@end
