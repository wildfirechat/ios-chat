//
//  WFCCSoundMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCSoundMessageContent.h"
#import "WFCCUtilities.h"
#import "wav_amr.h"
#import "WFCCIMService.h"
#import "Common.h"
#import "WFCCDictionary.h"

@implementation WFCCSoundMessageContent
+ (instancetype)soundMessageContentForWav:(NSString *)wavPath
                       destinationAmrPath:(NSString *)amrPath
                                 duration:(long)duration {
    WFCCSoundMessageContent *soundMsg = [[WFCCSoundMessageContent alloc] init];
    soundMsg.duration = duration;
    encode_amr([wavPath UTF8String], [amrPath UTF8String]);
    
    soundMsg.localPath = amrPath;
    
    return soundMsg;
}

+ (instancetype)soundMessageContentForAmr:(NSString *)amrPath
                                 duration:(long)duration {
    WFCCSoundMessageContent *soundMsg = [[WFCCSoundMessageContent alloc] init];
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
    WFCCMediaMessagePayload *payload = (WFCCMediaMessagePayload *)[super encode];
    payload.searchableContent = @"[声音]";
    payload.mediaType = Media_Type_VOICE;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@(_duration) forKey:@"duration"];
    payload.content = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil] encoding:NSUTF8StringEncoding];
    
    payload.remoteMediaUrl = self.remoteUrl;
    payload.localMediaPath = self.localPath;
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    if ([payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
        WFCCMediaMessagePayload *mediaPayload = (WFCCMediaMessagePayload *)payload;
        self.remoteUrl = mediaPayload.remoteMediaUrl;
        self.localPath = mediaPayload.localMediaPath;
        
        NSError *__error = nil;
        WFCCDictionary *dictionary = [WFCCDictionary fromString:payload.content error:&__error];
        if (!__error) {
            self.duration = [dictionary[@"duration"] longValue];
        }
    }
}


+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_SOUND;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}


+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return @"[声音]";
}
@end
