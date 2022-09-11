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

NSString *kMuteStateChanged = @"kMuteStateChanged";

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
                    [self.delegate onChangeModeRequest:changeModelCnt.isAudience];
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

- (NSString *)linkFromConferenceId:(NSString *)conferenceId password:(NSString *)password {
    if(password.length) {
        return [NSString stringWithFormat:@"wfzoom://conference?id=%@&pwd=%@", conferenceId, password];
    } else {
        return [NSString stringWithFormat:@"wfzoom://conference?id=%@", conferenceId];
    }
}
@end
#endif
