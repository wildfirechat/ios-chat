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
#import "WFCUConferenceCommandContent.h"
#import "WFCUConfigManager.h"
#import "WFCUImage.h"
#import "GCDAsyncSocket.h"
#import <ReplayKit/ReplayKit.h>
#import "WFCUI420VideoFrame.h"
#import "WFCUBroadcastDefine.h"

NSString *kMuteStateChanged = @"kMuteStateChanged";


@interface WFCUConferenceManager () <GCDAsyncSocketDelegate, WFAVExternalVideoSource, WFAVCallSessionAudioDataDelegate>
@property(nonatomic, strong)UIButton *alertViewCheckBtn;

@property (nonatomic, strong)GCDAsyncSocket *socket;
@property (nonatomic, strong)dispatch_queue_t queue;
@property (nonatomic, strong)NSMutableArray *sockets;
@property (nonatomic,strong)RPSystemBroadcastPickerView *broadPickerView;
@property(nonatomic, strong)NSMutableData *receivedData;
@property(nonatomic, strong)NSMutableData *receivedAudioData;
@property (nonatomic, strong) NSLock *audioDataLock;
@property(nonatomic, assign)BOOL broadcastWithAudio;
@property(nonatomic, weak)id<WFAVExternalFrameDelegate> frameDelegate;

@property(nonatomic, assign)NSUInteger deviceSampleRate;;
@end

static WFCUConferenceManager *sharedSingleton = nil;
@implementation WFCUConferenceManager
+ (WFCUConferenceManager *)sharedInstance {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[WFCUConferenceManager alloc] init];
                sharedSingleton.applyingUnmuteAudioMembers = [[NSMutableArray alloc] init];
                sharedSingleton.applyingUnmuteVideoMembers = [[NSMutableArray alloc] init];
                sharedSingleton.handupMembers = [[NSMutableArray alloc] init];
                [[NSNotificationCenter defaultCenter] addObserver:sharedSingleton selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:sharedSingleton
                                                         selector:@selector(onAppTerminate)
                                                             name:UIApplicationWillTerminateNotification
                                                           object:nil];
            }
        }
    }

    return sharedSingleton;
}

- (void)muteAudio:(BOOL)mute {
    if(mute) {
        if(![WFAVEngineKit sharedEngineKit].currentSession.isAudience && [WFAVEngineKit sharedEngineKit].currentSession.isVideoMuted && ![[WFAVEngineKit sharedEngineKit].currentSession isBroadcasting]) {
            if(![[WFAVEngineKit sharedEngineKit].currentSession switchAudience:YES]) {
                NSLog(@"switch to audience failure");
                return;
            }
        }
        [[WFAVEngineKit sharedEngineKit].currentSession muteAudio:mute];
    } else {
        if([WFAVEngineKit sharedEngineKit].currentSession.isAudience && ![[WFAVEngineKit sharedEngineKit].currentSession canSwitchAudience]) {
            NSLog(@"can not switch to participater");
            return;
        }
        
        if([WFAVEngineKit sharedEngineKit].currentSession.isAudience && self.currentConferenceInfo.maxParticipants > 0) {
            __block int participantCount = 0;
            [[WFAVEngineKit sharedEngineKit].currentSession.participants enumerateObjectsUsingBlock:^(WFAVParticipantProfile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if(!obj.audience) {
                    participantCount++;
                }
            }];
            if(participantCount >= self.currentConferenceInfo.maxParticipants) {
                if([self.delegate respondsToSelector:@selector(showToast:)]) {
                    [self.delegate showToast:@"发言人数已满，无法切换到发言人!"];
                }
                return;
            }
        }
        [[WFAVEngineKit sharedEngineKit].currentSession muteAudio:mute];
        
        if([WFAVEngineKit sharedEngineKit].currentSession.isAudience) {
            [[WFAVEngineKit sharedEngineKit].currentSession muteVideo:YES];
            [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:NO];
        }
    }
    [self notifyMuteStateChanged];
}

- (void)muteVideo:(BOOL)mute {
    if(mute) {
        if(![WFAVEngineKit sharedEngineKit].currentSession.isAudience && [WFAVEngineKit sharedEngineKit].currentSession.isAudioMuted && ![[WFAVEngineKit sharedEngineKit].currentSession isBroadcasting]) {
            [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:YES];
        }
        [[WFAVEngineKit sharedEngineKit].currentSession muteVideo:mute];
    } else {
        if([WFAVEngineKit sharedEngineKit].screenSharingReplaceMode && [self isBroadcasting]) {
            return;
        }
        if([WFAVEngineKit sharedEngineKit].currentSession.isAudience && self.currentConferenceInfo.maxParticipants > 0) {
            __block int participantCount = 0;
            [[WFAVEngineKit sharedEngineKit].currentSession.participants enumerateObjectsUsingBlock:^(WFAVParticipantProfile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if(!obj.audience) {
                    participantCount++;
                }
            }];
            if(participantCount >= self.currentConferenceInfo.maxParticipants) {
                if([self.delegate respondsToSelector:@selector(showToast:)]) {
                    [self.delegate showToast:@"发言人数已满，无法切换到发言人!"];
                }
                return;
            }
        }
        [[WFAVEngineKit sharedEngineKit].currentSession muteVideo:mute];
        
        if([WFAVEngineKit sharedEngineKit].currentSession.isAudience) {
            [[WFAVEngineKit sharedEngineKit].currentSession muteAudio:YES];
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

- (void)startScreansharing:(UIView *)view withAudio:(BOOL)withAudio {
    if(![self isBroadcasting]) {
        [self broadcast:view withAudio:withAudio];
        [[WFAVEngineKit sharedEngineKit].currentSession muteAudio:NO];
        [[WFAVEngineKit sharedEngineKit].currentSession muteVideo:YES];
        if([WFAVEngineKit sharedEngineKit].currentSession.isAudience) {
            [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:NO];
        }
        [self notifyMuteStateChanged];
    }
}

- (void)stopScreansharing {
    if([self isBroadcasting]) {
        [self cancelBroadcast];
    }
}

- (void)reloadConferenceInfo {
    __weak typeof(self)ws = self;
    [[WFCUConfigManager globalManager].appServiceProvider queryConferenceInfo:self.currentConferenceInfo.conferenceId password:self.currentConferenceInfo.password success:^(WFZConferenceInfo * _Nonnull conferenceInfo) {
        ws.currentConferenceInfo = conferenceInfo;
    } error:^(int errorCode, NSString * _Nonnull message) {
        
    }];
}

- (void)setCurrentConferenceInfo:(WFZConferenceInfo *)currentConferenceInfo {
    if(![_currentConferenceInfo.conferenceId isEqualToString:currentConferenceInfo.conferenceId]) {
        [self resetCommandState];
    }
    _currentConferenceInfo = currentConferenceInfo;
}

- (void)leaveConference:(BOOL)destroy {
    if([[WFAVEngineKit sharedEngineKit].currentSession isBroadcasting]) {
        [self cancelBroadcast];
    }
    
    [[WFAVEngineKit sharedEngineKit].currentSession leaveConference:NO];
    
    if(destroy) {
        [[WFCUConfigManager globalManager].appServiceProvider  destroyConference:[WFAVEngineKit sharedEngineKit].currentSession.callId success:^{
            
        } error:^(int errorCode, NSString * _Nonnull message) {
            
        }];
    }
}

- (UIButton *)alertViewCheckBtn {
    if(!_alertViewCheckBtn) {
        CGFloat width = [[[NSUserDefaults standardUserDefaults] objectForKey:@"wfc_conference_alert_checkbox_width"] floatValue];
        CGFloat height = [[[NSUserDefaults standardUserDefaults] objectForKey:@"wfc_conference_alert_checkbox_height"] floatValue];
        _alertViewCheckBtn = [[UIButton alloc] initWithFrame:CGRectMake(8, 44, width, height)];
        [_alertViewCheckBtn setImage:[WFCUImage imageNamed:@"multi_unselected"] forState:UIControlStateNormal];
        [_alertViewCheckBtn setImage:[WFCUImage imageNamed:@"multi_selected"] forState:UIControlStateSelected];
        [_alertViewCheckBtn.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_alertViewCheckBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_alertViewCheckBtn addTarget:self action:@selector(onAlertViewCheckBtnPressed:) forControlEvents:UIControlEventTouchDown];
    }
    return _alertViewCheckBtn;
}

- (void)onAlertViewCheckBtnPressed:(id)sender {
    self.alertViewCheckBtn.selected = !self.alertViewCheckBtn.selected;
}

- (void)requestRecording:(BOOL)recording {
    __weak typeof(self)ws = self;
    [[WFCUConfigManager globalManager].appServiceProvider recordConference:self.currentConferenceInfo.conferenceId record:recording success:^{
        [ws sendCommandMessage:RECORDING targetUserId:nil boolValue:recording];
        [ws reloadConferenceInfo];
    } error:^(int errorCode, NSString * _Nonnull message) {
        
    }];
}

- (void)presentCommandAlertView:(UIViewController *)controller message:(NSString *)message actionTitle:(NSString *)actionTitle cancelTitle:(NSString *)cancelTitle contentText:(NSString *)contentText checkBox:(BOOL)checkBox actionHandler:(void (^)(BOOL checked))actionHandler cancelHandler:(void (^)(void))cancelHandler {
    __weak typeof(self)ws = self;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:checkBox?[NSString stringWithFormat:@"%@\n\n\n", message]:message preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *action1 = [UIAlertAction actionWithTitle:cancelTitle?cancelTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        ws.alertViewCheckBtn = nil;
        if(cancelHandler) {
            cancelHandler();
        }
    }];
    [alertController addAction:action1];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        actionHandler(ws.alertViewCheckBtn.selected);
        ws.alertViewCheckBtn = nil;
    }];
    [alertController addAction:action2];
    
    if(checkBox) {
        [self.alertViewCheckBtn setTitle:[NSString stringWithFormat:@" %@", contentText] forState:UIControlStateNormal];
    } else {
        [self.alertViewCheckBtn setTitle:[NSString stringWithFormat:@"%@", contentText] forState:UIControlStateNormal];
        [_alertViewCheckBtn setImage:nil forState:UIControlStateNormal];
        [_alertViewCheckBtn setImage:nil forState:UIControlStateSelected];
    }
    
    [alertController.view addSubview:self.alertViewCheckBtn];
    
    [controller presentViewController:alertController animated:NO completion:^{
        CGSize size = alertController.view.bounds.size;
        if(ws.alertViewCheckBtn.frame.size.width != size.width - 16 || ws.alertViewCheckBtn.frame.size.height != size.height - 88) {
            [[NSUserDefaults standardUserDefaults] setObject:@(size.width - 16) forKey:@"wfc_conference_alert_checkbox_width"];
            [[NSUserDefaults standardUserDefaults] setObject:@(size.height - 88) forKey:@"wfc_conference_alert_checkbox_height"];
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [[NSUserDefaults standardUserDefaults] synchronize];
            });
        }
        ws.alertViewCheckBtn.frame = CGRectMake(8, 44, size.width - 16, size.height - 88);
    }];
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
            } else if([msg.content isKindOfClass:[WFCUConferenceCommandContent class]]) {
                WFCUConferenceCommandContent *command = (WFCUConferenceCommandContent *)msg.content;
                if([command.conferenceId isEqualToString:[WFAVEngineKit sharedEngineKit].currentSession.callId]) {
                    switch (command.type) {
                        //全体静音，只有主持人可以操作，结果写入conference profile中。带有参数是否允许成员自主解除静音。
                        case MUTE_ALL_AUDIO:
                            [self onMuteAll:YES allowUnMute:command.boolValue];
                            break;
                        //全体静音，只有主持人可以操作，结果写入conference profile中。带有参数是否允许成员自主解除静音。
                        case MUTE_ALL_VIDEO:
                            [self onMuteAll:NO allowUnMute:command.boolValue];
                            break;
                        //取消全体静音，只有主持人可以操作，结果写入conference profile中。带有参数是否邀请成员解除静音。
                        case CANCEL_MUTE_ALL_AUDIO:
                            [self onCancelMuteAll:YES requestUnmute:command.boolValue];
                            break;
                        //取消全体静音，只有主持人可以操作，结果写入conference profile中。带有参数是否邀请成员解除静音。
                        case CANCEL_MUTE_ALL_VIDEO:
                            [self onCancelMuteAll:NO requestUnmute:command.boolValue];
                            break;
                        //要求某个用户更改静音状态，只有主持人可以操作。带有参数是否静音/解除静音。
                        case REQUEST_MUTE_AUDIO:
                            if([command.targetUserId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                                [self onRequestMute:YES mute:command.boolValue];
                            } else {
                                return;
                            }
                            break;
                        //要求某个用户更改静音状态，只有主持人可以操作。带有参数是否静音/解除静音。
                        case REQUEST_MUTE_VIDEO:
                            if([command.targetUserId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                                [self onRequestMute:NO mute:command.boolValue];
                            } else {
                                return;
                            }
                            break;
                        //拒绝UNMUTE要求。（如果同意不需要通知对方同意)
                        case REJECT_UNMUTE_AUDIO_REQUEST:
                            break;
                        //拒绝UNMUTE要求。（如果同意不需要通知对方同意)
                        case REJECT_UNMUTE_VIDEO_REQUEST:
                            
                        //普通用户申请解除静音，带有参数是请求，还是取消请求。
                        case APPLY_UNMUTE_AUDIO:
                            if([self.currentConferenceInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                                if(command.boolValue) {
                                    [self.applyingUnmuteAudioMembers removeObject:msg.fromUser];
                                } else {
                                    if(![self.applyingUnmuteAudioMembers containsObject:msg.fromUser]) {
                                        [self.applyingUnmuteAudioMembers addObject:msg.fromUser];
                                    }
                                }
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceCommandStateChanged" object:nil];
                            }
                            break;

                        //普通用户申请解除静音，带有参数是请求，还是取消请求。
                        case APPLY_UNMUTE_VIDEO:
                            if([self.currentConferenceInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                                if(command.boolValue) {
                                    [self.applyingUnmuteVideoMembers removeObject:msg.fromUser];
                                } else {
                                    if(![self.applyingUnmuteVideoMembers containsObject:msg.fromUser]) {
                                        [self.applyingUnmuteVideoMembers addObject:msg.fromUser];
                                    }
                                }
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceCommandStateChanged" object:nil];
                            }
                            break;
                            break;
                        //管理员批准解除静音申请，带有参数是同意，还是拒绝申请。
                        case APPROVE_UNMUTE_AUDIO:
                        //管理员批准全部解除静音申请，带有参数是同意，还是拒绝申请。
                        case APPROVE_ALL_UNMUTE_AUDIO:
                            if(self.isApplyingUnmuteAudio) {
                                self.isApplyingUnmuteAudio = NO;
                                if(command.boolValue) {
                                    [self muteAudio:NO];
                                }
                            } else {
                                return;
                            }
                            break;
                        //管理员批准解除静音申请，带有参数是同意，还是拒绝申请。
                        case APPROVE_UNMUTE_VIDEO:
                        //管理员批准全部解除静音申请，带有参数是同意，还是拒绝申请。
                        case APPROVE_ALL_UNMUTE_VIDEO:
                            if(self.isApplyingUnmuteVideo) {
                                self.isApplyingUnmuteVideo = NO;
                                if(command.boolValue) {
                                    [self muteVideo:NO];
                                }
                            } else {
                                return;
                            }
                            break;
                        //举手，带有参数是举手还是放下举手
                        case HANDUP:
                            if(![self.handupMembers containsObject:msg.fromUser]) {
                                [self.handupMembers addObject:msg.fromUser];
                            }
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceCommandStateChanged" object:nil];
                            break;
                        //主持人放下成员的举手
                        case PUT_HAND_DOWN:
                            if(self.isHandup) {
                                self.isHandup = NO;
                            } else {
                                return;
                            }
                            break;
                        //主持人放下全体成员的举手
                        case PUT_ALL_HAND_DOWN:
                            if(self.isHandup) {
                                self.isHandup = NO;
                            } else {
                                return;
                            }
                            break;
                        case RECORDING:
                            [self reloadConferenceInfo];
                            break;
                            
                        case FOCUS:
                        case CANCEL_FOCUS:
                            self.currentConferenceInfo.focus = command.targetUserId;
                            [self reloadConferenceInfo];
                            break;
                        default:
                            break;
                    }
                    
                    //回调给UI来进行提醒或通知
                    if([self.delegate respondsToSelector:@selector(onReceiveCommand:content:fromUser:)]) {
                        [self.delegate onReceiveCommand:command.type content:command fromUser:msg.fromUser];
                    }
                }
            }
        }
    }
}

- (void)onMuteAll:(BOOL)audio allowUnMute:(BOOL)allowUnmute {
    [self reloadConferenceInfo];
    WFAVCallSession *session = [[WFAVEngineKit sharedEngineKit] currentSession];
    if(!session.isAudience) {
        if(audio) {
            self.isAllowUnMuteVideoWhenMuteAll = allowUnmute;
            [self muteAudio:YES];
        } else {
            self.isAllowUnMuteVideoWhenMuteAll = allowUnmute;
            [self muteVideo:YES];
        }
    }
}

- (void)onCancelMuteAll:(BOOL)audio requestUnmute:(BOOL)requestUnmute {
    [self reloadConferenceInfo];
}

- (void)onRequestMute:(BOOL)audio mute:(BOOL)mute {
    if(mute) {
        if(audio) {
            [self muteAudio:YES];
        } else {
            [self muteVideo:YES];
        }
    }
}

- (void)onAppTerminate {
    NSLog(@"conference manager onAppTerminate");
    if(self.socket && self.sockets.count) {
        NSLog(@"is broadcating...");
        [self cancelBroadcast];
    }
}

- (void)resetCommandState {
    [self.applyingUnmuteAudioMembers removeAllObjects];
    [self.applyingUnmuteVideoMembers removeAllObjects];
    [self.handupMembers removeAllObjects];
    self.isApplyingUnmuteAudio = NO;
    self.isApplyingUnmuteVideo = NO;
    self.isHandup = NO;
    self.isMuteAllAudio = NO;
    self.isMuteAllVideo = NO;
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

- (void)sendCommandMessage:(WFCUConferenceCommandContent *)commandContent {
    WFCCConversation *conv = [WFCCConversation conversationWithType:Chatroom_Type target:self.currentConferenceInfo.conferenceId line:0];
    [[WFCCIMService sharedWFCIMService] send:conv content:commandContent success:nil error:nil];
}

- (void)joinChatroom {
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] joinChatroom:self.currentConferenceInfo.conferenceId success:nil error:^(int error_code) {
        ws.failureJoinChatroom = YES;
    }];
}

- (BOOL)isOwner {
    return [self.currentConferenceInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId];
}

- (BOOL)requestMuteAll:(BOOL)allowMemberUnmute {
    if(![self isOwner])
        return NO;
    
    self.currentConferenceInfo.audience = YES;
    self.currentConferenceInfo.allowTurnOnMic = allowMemberUnmute;
    __weak typeof(self)ws = self;
    
    [[WFCUConfigManager globalManager].appServiceProvider updateConference:self.currentConferenceInfo success:^() {
        [ws sendCommandMessage:MUTE_ALL_AUDIO targetUserId:nil boolValue:allowMemberUnmute];
    } error:^(int errorCode, NSString * _Nonnull message) {
        
    }];
    
    return YES;
}

- (BOOL)requestUnmuteAll:(BOOL)unmute {
    if(![self isOwner])
        return NO;
    
    self.currentConferenceInfo.audience = NO;
    self.currentConferenceInfo.allowTurnOnMic = YES;
    __weak typeof(self)ws = self;
    
    [[WFCUConfigManager globalManager].appServiceProvider updateConference:self.currentConferenceInfo success:^(void) {
        [ws sendCommandMessage:CANCEL_MUTE_ALL_AUDIO targetUserId:nil boolValue:unmute];
    } error:^(int errorCode, NSString * _Nonnull message) {
        
    }];
    
    return YES;
}

- (BOOL)requestFocus:(NSString *)focusedUserId {
    if(![self isOwner])
        return NO;
    
    __weak typeof(self)ws = self;
    [[WFCUConfigManager globalManager].appServiceProvider focusConference:self.currentConferenceInfo.conferenceId userId:focusedUserId success:^{
        ws.currentConferenceInfo.focus = focusedUserId;
        [ws sendCommandMessage:FOCUS targetUserId:focusedUserId boolValue:NO];
    } error:^(int errorCode, NSString * _Nonnull message) {
        
    }];
    
    return YES;
}

- (BOOL)requestCancelFocus {
    if(![self isOwner])
        return NO;
    
    __weak typeof(self)ws = self;
    [[WFCUConfigManager globalManager].appServiceProvider focusConference:self.currentConferenceInfo.conferenceId userId:nil success:^{
        ws.currentConferenceInfo.focus = nil;
        [ws sendCommandMessage:CANCEL_FOCUS targetUserId:nil boolValue:NO];
    } error:^(int errorCode, NSString * _Nonnull message) {
        
    }];
    
    return YES;
}

- (BOOL)requestMember:(NSString *)memberId Mute:(BOOL)isMute {
    if(![self isOwner])
        return NO;
    
    [self sendCommandMessage:REQUEST_MUTE_AUDIO targetUserId:memberId boolValue:isMute];
    
    return YES;
}

- (void)rejectUnmuteRequest {
    [self sendCommandMessage:REJECT_UNMUTE_AUDIO_REQUEST targetUserId:nil boolValue:NO];
}

- (void)applyUnmute:(BOOL)isCancel isAudio:(BOOL)isAudio {
    if(isAudio) {
        self.isApplyingUnmuteAudio = !isCancel;
        [self sendCommandMessage:APPLY_UNMUTE_AUDIO targetUserId:nil boolValue:isCancel];
    } else {
        self.isApplyingUnmuteVideo = !isCancel;
        [self sendCommandMessage:APPLY_UNMUTE_VIDEO targetUserId:nil boolValue:isCancel];
    }
}

- (BOOL)approveMember:(NSString *)memberId unmute:(BOOL)isAllow isAudio:(BOOL)isAudio {
    if(![self isOwner])
        return NO;
    if(isAudio) {
        [self.applyingUnmuteAudioMembers removeObject:memberId];
    } else {
        [self.applyingUnmuteVideoMembers removeObject:memberId];
    }
    [self sendCommandMessage:isAudio?APPROVE_UNMUTE_AUDIO:APPROVE_UNMUTE_VIDEO targetUserId:memberId boolValue:isAllow];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceCommandStateChanged" object:nil];
    
    return YES;
}

- (BOOL)approveAllMemberUnmute:(BOOL)isAllow isAudio:(BOOL)isAudio {
    if(![self isOwner])
        return NO;
    
    if(isAudio) {
        [self.applyingUnmuteAudioMembers removeAllObjects];
    } else {
        [self.applyingUnmuteVideoMembers removeAllObjects];
    }
    [self sendCommandMessage:isAudio?APPROVE_ALL_UNMUTE_AUDIO:APPROVE_ALL_UNMUTE_VIDEO targetUserId:nil boolValue:isAllow];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceCommandStateChanged" object:nil];
    
    return YES;
}

- (void)handup:(BOOL)handup {
    self.isHandup = handup;
    [self sendCommandMessage:HANDUP targetUserId:nil boolValue:handup];
}

- (void)putMemberHandDown:(NSString *)memberId {
    [self.handupMembers removeObject:memberId];
    [self sendCommandMessage:PUT_HAND_DOWN targetUserId:memberId boolValue:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceCommandStateChanged" object:nil];
}

- (void)putAllHandDown {
    [self.handupMembers removeAllObjects];
    [self sendCommandMessage:PUT_ALL_HAND_DOWN targetUserId:nil boolValue:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceCommandStateChanged" object:nil];
}

- (void)sendCommandMessage:(WFCUConferenceCommandType)type targetUserId:(NSString *)userId boolValue:(BOOL)boolValue {
    WFCUConferenceCommandContent *command = [WFCUConferenceCommandContent commandOfType:type conference:self.currentConferenceInfo.conferenceId];
    command.targetUserId = userId;
    command.boolValue = boolValue;
    [self sendCommandMessage:command];
}

- (void)broadcast:(UIView *)view withAudio:(BOOL)withAudio  {
    self.receivedData = [[NSMutableData alloc] init];
    self.receivedAudioData = [[NSMutableData alloc] init];
    self.audioDataLock = [[NSLock alloc] init];
    self.broadcastWithAudio = withAudio;
    [self setupSocket:NO];
    [view addSubview:self.broadPickerView];
    for (UIView *view in self.broadPickerView.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            float iOSVersion = [[UIDevice currentDevice].systemVersion floatValue];
            UIButton *button = (UIButton *)view;
            if (iOSVersion >= 13) {
                [(UIButton *)view sendActionsForControlEvents:UIControlEventTouchDown];
                [(UIButton *)view sendActionsForControlEvents:UIControlEventTouchUpInside];
            } else {
                [(UIButton *)view sendActionsForControlEvents:UIControlEventTouchDown];
            }
        }
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sendOrientationCommand)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)cancelBroadcast {
//    for (UIView *view in self.broadPickerView.subviews) {
//        if ([view isKindOfClass:[UIButton class]]) {
//            float iOSVersion = [[UIDevice currentDevice].systemVersion floatValue];
//            UIButton *button = (UIButton *)view;
//            if (iOSVersion >= 13) {
//                [(UIButton *)view sendActionsForControlEvents:UIControlEventTouchDown];
//                [(UIButton *)view sendActionsForControlEvents:UIControlEventTouchUpInside];
//            } else {
//                [(UIButton *)view sendActionsForControlEvents:UIControlEventTouchDown];
//            }
//        }
//    }
    [self sendBroadcastCommand:3 value:0];
}

- (BOOL)isBroadcasting {
    return [WFAVEngineKit sharedEngineKit].currentSession.isBroadcasting;
}

- (void)onBroadcastStarted {
    [[WFAVEngineKit sharedEngineKit].currentSession setBroadcastingWithVideoSource:self];
    [self sendOrientationCommand];
    if (self.broadcastWithAudio) {
        [self sendWithAudioCommand:YES];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kBroadcastingStatusUpdated" object:nil];
    [WFAVEngineKit sharedEngineKit].currentSession.audioDataDelegate = self;
    if([WFAVEngineKit sharedEngineKit].screenSharingReplaceMode) {
        [[WFAVEngineKit sharedEngineKit].currentSession muteVideo:NO];
    }
}

- (void)onBroadcastStoped {
    [self.socket disconnect];
    self.socket = nil;
    [self.sockets removeAllObjects];
    
    [[WFAVEngineKit sharedEngineKit].currentSession setBroadcastingWithVideoSource:nil];
    self.receivedData = nil;
    self.receivedAudioData = nil;
    self.audioDataLock = nil;
    [self.broadPickerView removeFromSuperview];
    self.broadPickerView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kBroadcastingStatusUpdated" object:nil];
    [WFAVEngineKit sharedEngineKit].currentSession.audioDataDelegate = nil;
    if([WFAVEngineKit sharedEngineKit].screenSharingReplaceMode) {
        [[WFAVEngineKit sharedEngineKit].currentSession muteVideo:YES];
    }
}

- (RPSystemBroadcastPickerView *)broadPickerView{
    if(!_broadPickerView){
        _broadPickerView = [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectMake(100, 100, 50, 50)];
        _broadPickerView.showsMicrophoneButton = NO;
        _broadPickerView.preferredExtension = [NSString stringWithFormat:@"%@.Broadcast", [[NSBundle mainBundle] bundleIdentifier]];
        _broadPickerView.hidden = YES;
    }
    return _broadPickerView;
}

- (void)setupSocket:(BOOL)retry {
    self.sockets = [NSMutableArray array];
    self.queue = dispatch_queue_create("cn.wildfirechat.conference.broadcast.receive", DISPATCH_QUEUE_SERIAL);
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.queue];
    self.socket.IPv6Enabled = NO;
    NSError *error;
    [self.socket acceptOnPort:36622 error:&error];
    [self.socket readDataWithTimeout:-1 tag:0];
    if (error == nil) {
        NSLog(@"开启监听成功");
    } else {
        NSLog(@"开启监听失败");
        if(retry) {
            
        } else {
            [self setupSocket:YES];
        }
    }
}
- (void)onReceiveBroadcastCommand:(NSString *)command {
    dispatch_async(dispatch_get_main_queue(), ^{
        if([command isEqualToString:@"Start"]) {
            [self onBroadcastStarted];
        } else if([command isEqualToString:@"Finish"]) {
            [self onBroadcastStoped];
        }
    });
}
                   
- (void)sendOrientationCommand {
    int orientation = 0;
    switch([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationLandscapeLeft:
            orientation = 3;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = 1;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = 2;
            break;
        default:
            break;
    }
    [self sendBroadcastCommand:0 value:orientation];
}

- (void)sendWithAudioCommand:(BOOL)withAudio {
    [self sendBroadcastCommand:1 value:withAudio?1:0];
}

- (void)sendBroadcastCommand:(int)type value:(int)value {
    GCDAsyncSocket *socket = self.sockets.count ? self.sockets[0] : nil;
    if(socket) {
        Command header;
        header.type = type;
        header.value = value;
        NSData *md = [[NSData alloc] initWithBytes:&header length:sizeof(Command)];
        NSLog(@"send command %d, %d", type, value);
        [socket writeData:md withTimeout:(NSTimeInterval)5 tag:0];
    }
}

#pragma mark - WFAVCallSessionAudioDataDelegate
- (OSStatus)onDeliverRecordeAudiodData:(AudioUnitRenderActionFlags *)flags timestamp:(const AudioTimeStamp *)time_stamp busNumber:(UInt32)bus_number numFrames:(UInt32)mic_frames ioData:(AudioBufferList *)io_data {
    @autoreleasepool {
        NSData *deviceAudioData = nil;
        int micSampleRate = mic_frames*50;

        //Broadcast录制系统声音的采样率是44100，但蓝牙或者耳机可能是16000，也可能是别的采样率，可以从broadcast extension获取到采样率。
        //WebRTC本地录音间隔是20ms，一般采样率为48000，当使用蓝牙耳机时，可能的采样率为16000，也有可能是其他的采样率。
        //第一步先截取20ms的设备录音；第二步把这20ms的设备录音转化为跟麦克风录音采样率一样的数据；第三步把这2部分录音数据混音。
        
        //先截取20ms的设备录音，20ms的直播frame是882帧，双声道，每个数据的2个字节。
        NSLock *Lock = self.audioDataLock;
        [Lock lock];
        //保存当前的采样率和20ms的数据，以供后面混音使用。
        int sampleRate = self.deviceSampleRate;
        int device_frames = self.deviceSampleRate/50; // deviceSampleRate * 0.02
        if (self.receivedAudioData.length >= device_frames * 2 * 2) {
            if (self.receivedAudioData.length > (device_frames * 2 * 2)*2) {
                //如果缓冲区数据太多，只保留最后一段的，之前的清掉。
                deviceAudioData = [self.receivedAudioData subdataWithRange:NSMakeRange(self.receivedAudioData.length-device_frames * 2 * 2, device_frames * 2 * 2)];
                self.receivedAudioData = [[NSMutableData alloc] init];
            } else {
                deviceAudioData = [self.receivedAudioData subdataWithRange:NSMakeRange(0, device_frames * 2 * 2)];
                [self.receivedAudioData replaceBytesInRange:NSMakeRange(0, device_frames * 2 * 2) withBytes:NULL length:0];
            }
        }
        [Lock unlock];
        
        //采样率转换
        if (deviceAudioData) {
            AVAudioFormat *inputFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                                          sampleRate:sampleRate
                                                                            channels:2
                                                                         interleaved:YES];
            AVAudioPCMBuffer *inputBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:inputFormat
                                                                          frameCapacity:device_frames];
            inputBuffer.frameLength = device_frames;
            memcpy(inputBuffer.int16ChannelData[0], deviceAudioData.bytes, device_frames*4);
            AVAudioFormat *outputFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                                           sampleRate:micSampleRate
                                                                             channels:1
                                                                          interleaved:YES];
            
            AVAudioConverter *converter = [[AVAudioConverter alloc] initFromFormat:inputFormat toFormat:outputFormat];
            if (!converter) {
                NSLog(@"Failed to create AVAudioConverter");
                deviceAudioData = nil;
            } else {
                AVAudioPCMBuffer *outputBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:outputFormat
                                                                               frameCapacity:mic_frames];
                
                AVAudioConverterOutputStatus outputStatus = [converter convertToBuffer:outputBuffer
                                                                                 error:nil
                                                                    withInputFromBlock:^AVAudioBuffer * _Nullable(AVAudioPacketCount inNumberOfPackets, AVAudioConverterInputStatus * _Nonnull outStatus) {
                    *outStatus = AVAudioConverterInputStatus_HaveData;
                    return inputBuffer;
                }];
                if (outputStatus == AVAudioConverterOutputStatus_Error) {
                    NSLog(@"Conversion failed");
                }
                
                if (outputBuffer.frameLength) {
                    deviceAudioData = [NSData dataWithBytes:outputBuffer.int16ChannelData[0] length:outputBuffer.frameLength * sizeof(int16_t)];
                } else {
                    deviceAudioData = nil;
                }
            }
        }
        
        //混音
        if (deviceAudioData) {
            for (int i = 0; i < mic_frames; i++) {
                if (io_data->mBuffers[0].mNumberChannels == 1) {
                    short deviceFrame = *((short*)(deviceAudioData.bytes+i*2));
                    short micFrame = *((short*)(io_data->mBuffers[0].mData+i*2));
                    int mixed = (float)deviceFrame*0.5+(float)micFrame*0.5 + 0.5;
                    if(mixed > 32767) {
                        mixed = 32767;
                    } else if(mixed < -32767) {
                        mixed = -32767;
                    }
                    *((short*)(io_data->mBuffers[0].mData+i*2)) = mixed;
                }
            }
        }
    }
    
    return 0;
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    [self.sockets removeObject:sock];
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    [self.sockets removeObject:sock];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    [self.sockets addObject:newSocket];
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [self.receivedData appendData:data];
    @autoreleasepool {
        if(self.receivedData.length > sizeof(PacketHeader)) {
            PacketHeader header;
            memcpy(&header, self.receivedData.bytes, sizeof(PacketHeader));
            while(self.receivedData.length >= sizeof(PacketHeader) + header.dataLen) {
                NSData *rawData = [[NSData alloc] initWithBytes:self.receivedData.bytes+sizeof(PacketHeader) length:header.dataLen];
                [self.receivedData replaceBytesInRange:NSMakeRange(0, sizeof(PacketHeader) + header.dataLen) withBytes:NULL length:0];
                
                if(header.dataType == 0) {
                    if(rawData.length) {
                        NSString *status = [NSString stringWithUTF8String:rawData.bytes];
                        NSLog(@"Receive command:%@", status);
                        [self onReceiveBroadcastCommand:status];
                    } else {
                        NSLog(@"Bad command");
                    }
                } else if(header.dataType == 1) {
                    SampleInfo sampleInfo;
                    memcpy(&sampleInfo, rawData.bytes, sizeof(SampleInfo));

                    NSData *frameData = [[NSData alloc] initWithBytes:rawData.bytes+sizeof(SampleInfo) length:sampleInfo.dataLen];
                    
                    if(sampleInfo.type == 0) { //video
                        WFCUI420VideoFrame *i420Frame = [[WFCUI420VideoFrame alloc] initWithWidth:sampleInfo.width height:sampleInfo.height];
                        [i420Frame fromBytes:frameData];
                        CVPixelBufferRef pixelBuffer = [i420Frame toPixelBuffer];
                        
                        RTC_OBJC_TYPE(RTCCVPixelBuffer) *rtcPixelBuffer =
                        [[RTC_OBJC_TYPE(RTCCVPixelBuffer) alloc] initWithPixelBuffer:pixelBuffer];
                        NSTimeInterval timeStampSeconds = CACurrentMediaTime();
                        int64_t timeStampNs = lroundf(timeStampSeconds * NSEC_PER_SEC);
                        RTC_OBJC_TYPE(RTCVideoFrame) *videoFrame =
                        [[RTC_OBJC_TYPE(RTCVideoFrame) alloc] initWithBuffer:rtcPixelBuffer
                                                                    rotation:0
                                                                 timeStampNs:timeStampNs];
                        
                        
                        [self.frameDelegate capturer:nil didCaptureVideoFrame:videoFrame];
                        CVPixelBufferRelease(pixelBuffer);
                    } else if(sampleInfo.type == 1) { //audio
                        NSLock *Lock = self.audioDataLock;
                        [Lock lock];
                        //sampleInfo.height保存从Broadcast extension获取到的采样率。
                        if(self.deviceSampleRate != sampleInfo.height) {
                            //如果采样率有变化，抛弃掉之前的数据。
                            self.deviceSampleRate = sampleInfo.height;
                            self.receivedAudioData = [[NSMutableData alloc] init];
                        }
                        [self.receivedAudioData appendData:frameData];
                        [Lock unlock];
                    }
                } else {
                    NSLog(@"Unknown command");
                }
                
                if(self.receivedData.length > sizeof(PacketHeader)) {
                    memcpy(&header, self.receivedData.bytes, sizeof(PacketHeader));
                } else {
                    break;
                }
            }
        }
    }
    [sock readDataWithTimeout:-1 tag:0];
}

#pragma - mark WFAVExternalVideoSource
- (void)startCapture:(id<WFAVExternalFrameDelegate>_Nonnull)delegate {
    self.frameDelegate = delegate;
}

- (void)stopCapture {
    self.frameDelegate = nil;
}
@end
#endif
