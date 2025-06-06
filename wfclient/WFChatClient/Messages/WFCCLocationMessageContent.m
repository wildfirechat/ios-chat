//
//  WFCCTextMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCLocationMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"
#import "WFCCUtilities.h"
#import "WFCCDictionary.h"

@implementation WFCCLocationMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.searchableContent = self.title;
    payload.binaryContent = UIImageJPEGRepresentation(self.thumbnail, 0.67);
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:@(self.coordinate.latitude) forKey:@"lat"];
    [dataDict setObject:@(self.coordinate.longitude) forKey:@"long"];
    payload.content = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dataDict
                                                                                     options:kNilOptions
                                                                                       error:nil] encoding:NSUTF8StringEncoding];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    self.title = payload.searchableContent;
    self.thumbnail = [UIImage imageWithData:payload.binaryContent];
    
    NSError *__error = nil;
    WFCCDictionary *dictionary = [WFCCDictionary fromString:payload.content error:&__error];
    if (!__error) {
        double latitude = [dictionary[@"lat"] doubleValue];
        double longitude = [dictionary[@"long"] doubleValue];
        self.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    }

}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_LOCATION;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}


+ (instancetype)contentWith:(CLLocationCoordinate2D) coordinate title:(NSString *)title thumbnail:(UIImage *)thumbnail {
    WFCCLocationMessageContent *content = [[WFCCLocationMessageContent alloc] init];
    content.coordinate = coordinate;
    content.title = title;
    content.thumbnail = [WFCCUtilities generateThumbnail:thumbnail withWidth:180 withHeight:120];;
    return content;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
  return @"[位置]";
}
@end
