//
//  WFCUConferenceKickoffMemberContent.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2021/2/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUConferenceKickoffMemberContent.h"

@implementation WFCUConferenceKickoffMemberContent
-(WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    payload.contentType = [self.class getContentType];
    payload.content = self.conferenceId;
    
    return payload;
}

-(void)decode:(WFCCMessagePayload *)payload {
    self.conferenceId = payload.content;
}

+ (int)getContentType {
    return VOIP_CONTENT_CONFERENCE_KICKOFF_MEMBER;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_TRANSPARENT;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}
@end
