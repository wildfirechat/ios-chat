//
//  WFCCPttVoiceMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCPttVoiceMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCPttVoiceMessageContent
+ (instancetype)soundMessageContentForWav:(NSString *)wavPath
                       destinationAmrPath:(NSString *)amrPath
                                 duration:(long)duration {
    return [super soundMessageContentForWav:wavPath destinationAmrPath:amrPath duration:duration];
}

+ (instancetype)soundMessageContentForAmr:(NSString *)amrPath
                                 duration:(long)duration {
    return [super soundMessageContentForAmr:amrPath duration:duration];
}

- (NSData *)getWavData {
    if (!self.localPath) {
        return nil;
    } else {
        return [[WFCCIMService sharedWFCIMService] getWavData:self.localPath];
    }
}

- (WFCCMessagePayload *)encode {
    return [super encode];
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
}


+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_PTT_VOICE;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}


+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return @"[对讲语音]";
}
@end
