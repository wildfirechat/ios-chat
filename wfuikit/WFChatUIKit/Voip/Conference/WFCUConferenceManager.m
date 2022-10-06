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

NSString *kMuteStateChanged = @"kMuteStateChanged";

@interface WFCUConferenceManager ()
@property(nonatomic, strong)UIButton *alertViewCheckBtn;
@end

static WFCUConferenceManager *sharedSingleton = nil;
@implementation WFCUConferenceManager
+ (WFCUConferenceManager *)sharedInstance {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[WFCUConferenceManager alloc] init];
                sharedSingleton.applyingUnmuteMembers = [[NSMutableArray alloc] init];
                sharedSingleton.handupMembers = [[NSMutableArray alloc] init];
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

- (void)enableAudioAndScreansharing {
    [[WFAVEngineKit sharedEngineKit].currentSession muteAudio:NO];
    if([WFAVEngineKit sharedEngineKit].currentSession.isAudience) {
        [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:NO];
    }
    [[WFAVEngineKit sharedEngineKit].currentSession setInAppScreenSharing:YES];
    [self notifyMuteStateChanged];
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

    UIAlertAction *action1 = [UIAlertAction actionWithTitle:cancelTitle?cancelTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
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
                        case MUTE_ALL:
                            [self reloadConferenceInfo];
                            if(![WFAVEngineKit sharedEngineKit].currentSession.isAudience) {
                                [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:YES];
                            }
                            break;
                        //取消全体静音，只有主持人可以操作，结果写入conference profile中。带有参数是否邀请成员解除静音。
                        case CANCEL_MUTE_ALL:
                            [self reloadConferenceInfo];
                            break;
                            
                        //要求某个用户更改静音状态，只有主持人可以操作。带有参数是否静音/解除静音。
                        case REQUEST_MUTE:
                            if([command.targetUserId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                                if(command.boolValue) {
                                    [self muteAudioVideo:YES];
                                }
                            } else {
                                return;
                            }
                            break;
                        //拒绝UNMUTE要求。（如果同意不需要通知对方同意)
                        case REJECT_UNMUTE_REQUEST:
                            break;
                            
                        //普通用户申请解除静音，带有参数是请求，还是取消请求。
                        case APPLY_UNMUTE:
                            if([self.currentConferenceInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                                if(command.boolValue) {
                                    [self.applyingUnmuteMembers removeObject:msg.fromUser];
                                } else {
                                    if(![self.applyingUnmuteMembers containsObject:msg.fromUser]) {
                                        [self.applyingUnmuteMembers addObject:msg.fromUser];
                                    }
                                }
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceCommandStateChanged" object:nil];
                            }
                            break;
                        //管理员批准解除静音申请，带有参数是同意，还是拒绝申请。
                        case APPROVE_UNMUTE:
                            if(self.isApplyingUnmute) {
                                self.isApplyingUnmute = NO;
                                if(command.boolValue) {
                                    [self muteAudio:NO];
                                }
                            } else {
                                return;
                            }
                            break;
                        //管理员批准全部解除静音申请，带有参数是同意，还是拒绝申请。
                        case APPROVE_ALL_UNMUTE:
                            if(self.isApplyingUnmute) {
                                self.isApplyingUnmute = NO;
                                if(command.boolValue) {
                                    [self muteAudio:NO];
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

- (void)resetCommandState {
    [self.applyingUnmuteMembers removeAllObjects];
    [self.handupMembers removeAllObjects];
    self.isApplyingUnmute = NO;
    self.isHandup = NO;
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
        [ws sendCommandMessage:MUTE_ALL targetUserId:nil boolValue:allowMemberUnmute];
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
        [ws sendCommandMessage:CANCEL_MUTE_ALL targetUserId:nil boolValue:unmute];
    } error:^(int errorCode, NSString * _Nonnull message) {
        
    }];
    
    return YES;
}

- (BOOL)requestMember:(NSString *)memberId Mute:(BOOL)isMute {
    if(![self isOwner])
        return NO;
    
    [self sendCommandMessage:REQUEST_MUTE targetUserId:memberId boolValue:isMute];
    
    return YES;
}

- (void)rejectUnmuteRequest {
    [self sendCommandMessage:REJECT_UNMUTE_REQUEST targetUserId:nil boolValue:NO];
}

- (void)applyUnmute:(BOOL)isCancel {
    self.isApplyingUnmute = !isCancel;
    [self sendCommandMessage:APPLY_UNMUTE targetUserId:nil boolValue:isCancel];
}

- (BOOL)approveMember:(NSString *)memberId unmute:(BOOL)isAllow {
    if(![self isOwner])
        return NO;
    
    [self.applyingUnmuteMembers removeObject:memberId];
    [self sendCommandMessage:APPROVE_UNMUTE targetUserId:memberId boolValue:isAllow];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceCommandStateChanged" object:nil];
    
    return YES;
}

- (BOOL)approveAllMemberUnmute:(BOOL)isAllow {
    if(![self isOwner])
        return NO;
    
    [self.applyingUnmuteMembers removeAllObjects];
    [self sendCommandMessage:APPROVE_ALL_UNMUTE targetUserId:nil boolValue:isAllow];
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
@end
#endif
