//
//  WFCUConferenceChangeModelContent.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2021/2/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUConferenceChangeModelContent.h"

@implementation WFCUConferenceChangeModelContent
-(WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    payload.contentType = [self.class getContentType];
    payload.content = self.conferenceId;
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.isAudience) {
        [dataDict setObject:@(YES) forKey:@"a"];
    }
    
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                            options:kNilOptions
                                                              error:nil];
    
    return payload;
}
-(void)decode:(WFCCMessagePayload *)payload {
    self.conferenceId = payload.content;
    
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.isAudience = [dictionary[@"a"] boolValue];
    }
}

+ (int)getContentType {
    return VOIP_CONTENT_CONFERENCE_CHANGE_MODE;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_TRANSPARENT;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}
@end
