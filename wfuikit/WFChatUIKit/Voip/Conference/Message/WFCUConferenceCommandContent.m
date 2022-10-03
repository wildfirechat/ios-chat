//
//  WFCUConferenceCommandContent.m
//  WFChatUIKit
//
//  Created by Heavyrain on 2022/10/02.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import "WFCUConferenceCommandContent.h"

@implementation WFCUConferenceCommandContent
+ (instancetype)commandOfType:(WFCUConferenceCommandType)type conference:(NSString *)conferenceId {
    WFCUConferenceCommandContent *command = [[WFCUConferenceCommandContent alloc] init];
    command.type = type;
    command.conferenceId = conferenceId;
    return command;
}

-(WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.content = self.conferenceId;
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:@(self.type) forKey:@"t"];
    if (self.boolValue) {
        [dataDict setObject:@(YES) forKey:@"b"];
    }
    if (self.targetUserId.length) {
        [dataDict setObject:self.targetUserId forKey:@"u"];
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
            self.type = [dictionary[@"t"] integerValue];
            self.boolValue = [dictionary[@"b"] boolValue];
            self.targetUserId = dictionary[@"u"];
        }
}

+ (int)getContentType {
    return VOIP_CONTENT_CONFERENCE_COMMAND;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_TRANSPARENT;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}
@end
