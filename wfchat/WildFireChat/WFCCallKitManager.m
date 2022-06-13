//
//  WFCCallKitManager.m
//  WildFireChat
//
//  Created by Rain on 2022/4/25.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import "WFCCallKitManager.h"
#import <CallKit/CallKit.h>
#import <UIKit/UIKit.h>
#import <WFChatUIKit/WFChatUIKit.h>

@interface WFCCallKitManager ()
@property(nonatomic, strong) CXProvider *provider;
@property(nonatomic, strong) CXCallController *callController;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSUUID *> *callUUIDDict;
@end

@implementation WFCCallKitManager

- (instancetype)init {
    self = [super init];
    if(self) {
#if USE_CALL_KIT
        self.callUUIDDict = [[NSMutableDictionary alloc] init];
        static CXProviderConfiguration* configInternal = nil;
        configInternal = [[CXProviderConfiguration alloc] initWithLocalizedName:@"野火"];
        configInternal.supportsVideo = true;
        configInternal.maximumCallsPerCallGroup = 1;
        configInternal.maximumCallGroups = 1;
        configInternal.supportedHandleTypes = [[NSSet alloc] initWithObjects:[NSNumber numberWithInt:CXHandleTypeGeneric],[NSNumber numberWithInt:CXHandleTypePhoneNumber], nil];
        UIImage* iconMaskImage = [UIImage imageNamed:@"file_icon"];
        configInternal.iconTemplateImageData = UIImagePNGRepresentation(iconMaskImage);
        
        self.provider = [[CXProvider alloc] initWithConfiguration: configInternal];
        [self.provider setDelegate:self queue:nil];
        self.callController = [[CXCallController alloc] initWithQueue:dispatch_get_main_queue()];
#endif
    }
    return self;
}

- (void)didReceiveCall:(WFAVCallSession *)session {
    if(self.callUUIDDict[session.callId]) {
        session.callUUID = self.callUUIDDict[session.callId];
    } else {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:session.initiator refresh:NO];
        NSUUID *currentCall = [NSUUID UUID];
        session.callUUID = currentCall;
        [self reportIncomingCallWithTitle:userInfo.displayName Sid:session.initiator audioOnly:session.audioOnly callId:session.callId uuid:currentCall];
    }
    
}
- (void)didCallEnded:(WFAVCallEndReason)reason duration:(int)callDuration {
    if([WFAVEngineKit sharedEngineKit].currentSession.callUUID) {
        CXEndCallAction *endAction = [[CXEndCallAction alloc] initWithCallUUID:[WFAVEngineKit sharedEngineKit].currentSession.callUUID];
        CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endAction];
        [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
            NSLog(@"end call");
        }];
    }
}
- (void)didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
                                  forType:(NSString *)type {
    NSLog(@"didReceiveIncomingPushWithPayload");
    NSDictionary *wfc = payload.dictionaryPayload[@"wfc"];
    if(wfc) {
        NSString *sender = wfc[@"sender"];
        NSString *pushData = wfc[@"pushData"];
        NSDictionary *pd = [NSJSONSerialization JSONObjectWithData:[pushData dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
        BOOL audioOnly = [pd[@"audioOnly"] boolValue];
        NSString *callId = pd[@"callId"];
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:sender refresh:NO];
        [self reportIncomingCallWithTitle:userInfo.displayName Sid:sender audioOnly:audioOnly callId:callId];
    }
}

- (void)reportIncomingCallWithTitle:(NSString *)title Sid:(NSString *)sid audioOnly:(BOOL)audioOnly callId:(NSString *)callId {
    NSUUID *currentCall = [NSUUID UUID];
    [self reportIncomingCallWithTitle:title Sid:sid audioOnly:audioOnly callId:callId uuid:currentCall];
}

- (void)reportIncomingCallWithTitle:(NSString *)title Sid:(NSString *)sid audioOnly:(BOOL)audioOnly callId:(NSString *)callId uuid:(NSUUID *)uuid {
    CXCallUpdate* update = [[CXCallUpdate alloc] init];
    update.supportsDTMF = false;
    update.supportsHolding = false;
    update.supportsGrouping = false;
    update.supportsUngrouping = false;
    update.hasVideo = !audioOnly;
    update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:sid];
    update.localizedCallerName = title;
    
    self.callUUIDDict[callId] = uuid;
    //弹出电话页面
    
    [self.provider reportNewIncomingCallWithUUID:uuid update:update completion:^(NSError * _Nullable error) {
        NSLog(@"error");
    }];
}

#pragma - mark CXProviderDelegate
- (void)providerDidReset:(CXProvider *)provider {
    NSLog(@"providerDidReset");
}

- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
    NSLog(@"performStartCallAction");
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    NSLog(@"performAnswerCallAction");
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVoiceChat error:nil];

    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    NSLog(@"performEndCallAction");
    if([action.callUUID isEqual:[WFAVEngineKit sharedEngineKit].currentSession.callUUID]) {
        if ([WFAVEngineKit sharedEngineKit].currentSession.state != kWFAVEngineStateIdle) {
            [[WFAVEngineKit sharedEngineKit].currentSession endCall];
        }
    }
    [action fulfill];
}
-(void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    if ([WFAVEngineKit sharedEngineKit].currentSession.state == kWFAVEngineStateIncomming) {
        [[WFAVEngineKit sharedEngineKit].currentSession answerCall:false callExtra:nil];
        
        UIViewController *videoVC;
        if ([WFAVEngineKit sharedEngineKit].currentSession.conversation.type == Group_Type && [WFAVEngineKit sharedEngineKit].supportMultiCall) {
            videoVC = [[WFCUMultiVideoViewController alloc] initWithSession:[WFAVEngineKit sharedEngineKit].currentSession];
        } else {
            videoVC = [[WFCUVideoViewController alloc] initWithSession:[WFAVEngineKit sharedEngineKit].currentSession];
        }

        [[WFAVEngineKit sharedEngineKit] presentViewController:videoVC];
    }
}
@end
