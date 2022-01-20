//
//  WFCCPTTSoundMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCPTTSoundMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"
#import "wav_amr.h"

@implementation WFCCPTTSoundMessageContent
+ (instancetype)soundMessageContentForWav:(NSString *)wavPath
                       destinationAmrPath:(NSString *)amrPath
                                 duration:(long)duration {
    WFCCPTTSoundMessageContent *soundMsg = [[WFCCPTTSoundMessageContent alloc] init];
    soundMsg.duration = duration;
    encode_amr([wavPath UTF8String], [amrPath UTF8String]);
    
    soundMsg.localPath = amrPath;
    
    return soundMsg;
}

+ (instancetype)soundMessageContentForAmr:(NSString *)amrPath
                                 duration:(long)duration {
    WFCCPTTSoundMessageContent *soundMsg = [[WFCCPTTSoundMessageContent alloc] init];
    soundMsg.duration = duration;
    soundMsg.localPath = amrPath;
    
    return soundMsg;
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
