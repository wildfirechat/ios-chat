//
//  WFCUConferenceManager.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2021/2/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#if WFCU_SUPPORT_VOIP
#import "WFCUConferenceManager.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUConferenceChangeModelContent.h"
#import "WFZConferenceInfo.h"
#import "WFCUConferenceHistory.h"

NSString *kMuteStateChanged = @"kMuteStateChanged";

@interface WFCUConferenceManager ()
@end

static WFCUConferenceManager *sharedSingleton = nil;
@implementation WFCUConferenceManager
+ (WFCUConferenceManager *)sharedInstance {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[WFCUConferenceManager alloc] init];
                [[NSNotificationCenter defaultCenter] addObserver:sharedSingleton selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];
            }
        }
    }

    return sharedSingleton;
}

- (void)muteAudio:(BOOL)mute {
    if(mute) {
        if(![WFAVEngineKit sharedEngineKit].currentSession.isAudience && [WFAVEngineKit sharedEngineKit].currentSession.isVideoMuted) {
            [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:YES];
        }
        [[WFAVEngineKit sharedEngineKit].currentSession muteAudio:mute];
    } else {
        [[WFAVEngineKit sharedEngineKit].currentSession muteAudio:mute];
        
        if([WFAVEngineKit sharedEngineKit].currentSession.isAudience) {
            [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:NO];
        }
    }
    [self notifyMuteStateChanged];
}

- (void)muteVideo:(BOOL)mute {
    if(mute) {
        if(![WFAVEngineKit sharedEngineKit].currentSession.isAudience && [WFAVEngineKit sharedEngineKit].currentSession.isAudioMuted) {
            [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:YES];
        }
        [[WFAVEngineKit sharedEngineKit].currentSession muteVideo:mute];
    } else {
        [[WFAVEngineKit sharedEngineKit].currentSession muteVideo:mute];
        
        if([WFAVEngineKit sharedEngineKit].currentSession.isAudience) {
            [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:NO];
        }
    }
    [self notifyMuteStateChanged];
}

- (void)muteAudioVideo:(BOOL)mute {
    if(mute) {
        if(![WFAVEngineKit sharedEngineKit].currentSession.isAudience) {
            [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:YES];
        }
        [[WFAVEngineKit sharedEngineKit].currentSession muteVideo:mute];
        [[WFAVEngineKit sharedEngineKit].currentSession muteAudio:mute];
    } else {
        [[WFAVEngineKit sharedEngineKit].currentSession muteVideo:mute];
        [[WFAVEngineKit sharedEngineKit].currentSession muteAudio:mute];
        
        if([WFAVEngineKit sharedEngineKit].currentSession.isAudience) {
            [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:NO];
        }
    }
    [self notifyMuteStateChanged];
}

- (void)enableAudioDisableVideo {
    [[WFAVEngineKit sharedEngineKit].currentSession muteVideo:YES];
    [[WFAVEngineKit sharedEngineKit].currentSession muteAudio:NO];
    if([WFAVEngineKit sharedEngineKit].currentSession.isAudience) {
        [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:NO];
    }
    [self notifyMuteStateChanged];
}

- (void)notifyMuteStateChanged {
    [[NSNotificationCenter defaultCenter] postNotificationName:kMuteStateChanged object:nil];
}

- (void)onReceiveMessages:(NSNotification *)notification {
    NSArray<WFCCMessage *> *messages = notification.object;
    if([WFAVEngineKit sharedEngineKit].currentSession.state == kWFAVEngineStateConnected && [WFAVEngineKit sharedEngineKit].currentSession.isConference) {
        for (WFCCMessage *msg in messages) {
            if([msg.content isKindOfClass:[WFCUConferenceChangeModelContent class]]) {
                WFCUConferenceChangeModelContent *changeModelCnt = (WFCUConferenceChangeModelContent *)msg.content;
                if([changeModelCnt.conferenceId isEqualToString:[WFAVEngineKit sharedEngineKit].currentSession.callId]) {
                    if(changeModelCnt.isAudience) {
                        [self.delegate onChangeModeRequest:YES];
                        [[WFAVEngineKit sharedEngineKit].currentSession muteAudio:YES];
                        [[WFAVEngineKit sharedEngineKit].currentSession muteVideo:YES];
                    } else {
                        [[WFAVEngineKit sharedEngineKit].currentSession muteAudio:NO];
                        [[WFAVEngineKit sharedEngineKit].currentSession muteVideo:YES];
                        [self.delegate onChangeModeRequest:NO];
                    }
                }
            }
        }
    }
}

- (void)request:(NSString *)userId changeModel:(BOOL)isAudience inConference:(NSString *)conferenceId {
    WFCUConferenceChangeModelContent *cnt = [[WFCUConferenceChangeModelContent alloc] init];
    cnt.conferenceId = conferenceId;
    cnt.isAudience = isAudience;
    WFCCConversation *conv = [WFCCConversation conversationWithType:Single_Type target:userId line:0];
    [[WFCCIMService sharedWFCIMService] send:conv content:cnt success:^(long long messageUid, long long timestamp) {
            
        } error:^(int error_code) {
            
        }];
}

- (void)addHistory:(WFZConferenceInfo *)info duration:(int)duration {
    WFCUConferenceHistory *history = [[WFCUConferenceHistory alloc] init];
    history.conferenceInfo = info;
    history.timestamp = [[[NSDate alloc] init] timeIntervalSince1970];
    history.duration = duration;
    NSMutableArray<WFCUConferenceHistory *> *conferenceHistorys = [[self getConferenceHistoryList] mutableCopy];
    for (WFCUConferenceHistory *his in conferenceHistorys) {
        if([his.conferenceInfo.conferenceId isEqualToString:info.conferenceId]) {
            history.duration += his.duration;
            [conferenceHistorys removeObject:his];
            break;
        }
    }
    [conferenceHistorys insertObject:history atIndex:0];
    NSMutableArray *dictArray = [NSMutableArray new];
    [conferenceHistorys enumerateObjectsUsingBlock:^(WFCUConferenceHistory * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [dictArray addObject:[obj toDictionary]];
    }];
    
    if(dictArray.count > 500) {
        dictArray = [[dictArray subarrayWithRange:NSMakeRange(0, 500)] mutableCopy];
    }
    [[NSUserDefaults standardUserDefaults] setObject:dictArray forKey:@"WFC_CONFERENCE_HISTORY"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray<WFCUConferenceHistory *> *)getConferenceHistoryList {
    NSObject *o = [[NSUserDefaults standardUserDefaults] objectForKey:@"WFC_CONFERENCE_HISTORY"];
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    
    if([o isKindOfClass:NSArray.class]) {
        NSArray<NSDictionary *> *arr = (NSArray<NSDictionary *> *)o;
        [arr enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [ret addObject:[WFCUConferenceHistory fromDictionary:obj]];
        }];
    }
    return ret;
}

//链接格式 @"wildfirechat://conference/conferenceid?password=123456";
//如果修改，需要对应修改appdelegate里的openUrl的地址
- (NSString *)linkFromConferenceId:(NSString *)conferenceId password:(NSString *)password {
    if(password.length) {
        return [NSString stringWithFormat:@"wildfirechat://conference/%@?pwd=%@", conferenceId, password];
    } else {
        return [NSString stringWithFormat:@"wildfirechat://conference/%@", conferenceId];
    }
}
@end
#endif
