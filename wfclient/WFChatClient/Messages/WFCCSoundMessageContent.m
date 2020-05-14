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

@implementation WFCCSoundMessageContent
+ (instancetype)soundMessageContentForWav:(NSString *)wavPath duration:(long)duration {
    WFCCSoundMessageContent *soundMsg = [[WFCCSoundMessageContent alloc] init];
    soundMsg.duration = duration;
    
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
    
    NSString *amrPath = [[WFCCUtilities getDocumentPathWithComponent:@"/Vioce"] stringByAppendingPathComponent:[NSString stringWithFormat:@"img%lld.amr", recordTime]];
    
    encode_amr([wavPath UTF8String], [amrPath UTF8String]);
    
    soundMsg.localPath = amrPath;
    
    return soundMsg;
}

- (void)updateAmrData:(NSData *)voiceData {
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
    
    NSString *amrPath = [[WFCCUtilities getDocumentPathWithComponent:@"/Vioce"] stringByAppendingPathComponent:[NSString stringWithFormat:@"img%lld.amr", recordTime]];
    [voiceData writeToFile:amrPath atomically:YES];
    
    self.localPath = amrPath;
}
- (NSData *)getWavData {
    if ([@"mp3" isEqualToString:[self.localPath pathExtension]]) {
        return [NSData dataWithContentsOfFile:self.localPath];
    } else {
    NSMutableData *data = [[NSMutableData alloc] init];
    decode_amr([self.localPath UTF8String], data);
    
//    UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
//    NSString *amrPath = [[WFCCUtilities getDocumentPathWithComponent:@"/Vioce"] stringByAppendingPathComponent:[NSString stringWithFormat:@"img%lld.wav", recordTime]];
//    
//    [data writeToFile:amrPath atomically:YES];
    return data;
    }
}

- (WFCCMessagePayload *)encode {
    WFCCMediaMessagePayload *payload = [[WFCCMediaMessagePayload alloc] init];
    payload.extra = self.extra;
    payload.contentType = [self.class getContentType];
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
        
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[payload.content dataUsingEncoding:NSUTF8StringEncoding]
                                                                   options:kNilOptions
                                                                     error:nil];
        self.duration = [dictionary[@"duration"] longValue];
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
