//
//  WFCUConferenceManager.h
//  WFChatUIKit
//
//  Created by Tom Lee on 2021/2/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCUConferenceCommandContent.h"


#if WFCU_SUPPORT_VOIP
extern NSString *kMuteStateChanged;

@class WFZConferenceInfo;
@class WFCUConferenceHistory;

@protocol WFCUConferenceManagerDelegate <NSObject>
-(void)onChangeModeRequest:(BOOL)isAudience;
-(void)onReceiveCommand:(WFCUConferenceCommandType)commandType content:(WFCUConferenceCommandContent *)commandContent fromUser:(NSString *)sender;
@end

@interface WFCUConferenceManager : NSObject
+ (WFCUConferenceManager *)sharedInstance;
@property (nonatomic, weak) id<WFCUConferenceManagerDelegate> delegate;
@property (nonatomic, strong)WFZConferenceInfo *currentConferenceInfo;
- (void)muteAudio:(BOOL)mute;
- (void)muteVideo:(BOOL)mute;
- (void)muteAudioVideo:(BOOL)mute;
- (void)enableAudioDisableVideo;
- (void)switchAudioAndScreansharing:(UIView *)view;
- (void)leaveConference:(BOOL)destroy;

- (void)request:(NSString *)userId changeModel:(BOOL)isAudience inConference:(NSString *)conferenceId;

- (void)addHistory:(WFZConferenceInfo *)info duration:(int)duration;

- (NSArray<WFCUConferenceHistory *> *)getConferenceHistoryList;

- (NSString *)linkFromConferenceId:(NSString *)conferenceId password:(NSString *)password;

//主持人要求全部静音，allowMemberUnmute是否允许自主解除静音。
- (void)requestRecording:(BOOL)recording;

//展示带有单选框的alertview
- (void)presentCommandAlertView:(UIViewController *)controller message:(NSString *)message actionTitle:(NSString *)actionTitle cancelTitle:(NSString *)cancelTitle contentText:(NSString *)contentText checkBox:(BOOL)checkBox actionHandler:(void (^)(BOOL checked))actionHandler cancelHandler:(void (^)(void))cancelHandler;

- (void)joinChatroom;
@property(nonatomic, assign)BOOL failureJoinChatroom;

@property(nonatomic, assign)BOOL isOwner;

//主持人要求全部静音，allowMemberUnmute是否允许自主解除静音。
- (BOOL)requestMuteAll:(BOOL)allowMemberUnmute;

//主持人中止全部静音，unmute是否解除静音。
- (BOOL)requestUnmuteAll:(BOOL)unmute;

//主持人要求成员更改mute状态。
- (BOOL)requestMember:(NSString *)memberId Mute:(BOOL)isMute;

//成员拒绝解除静音请求
- (void)rejectUnmuteRequest;

//成员申请解除静音，true是取消
- (void)applyUnmute:(BOOL)isCancel;

//主持人批准成员的unmute的请求
- (BOOL)approveMember:(NSString *)memberId unmute:(BOOL)isReject;

//主持人批准所有成员的unmute的请求
- (BOOL)approveAllMemberUnmute:(BOOL)isReject;

//举手
- (void)handup:(BOOL)handup;

//把用户举手放下
- (void)putMemberHandDown:(NSString *)memberId;

//把所有用户举手放下
- (void)putAllHandDown;

//取消焦点用户
- (BOOL)requestCancelFocus;

//设置焦点用户
- (BOOL)requestFocus:(NSString *)focusedUserId;

//是否申请了unmute，等待主持人的批准
@property(nonatomic, assign)BOOL isApplyingUnmute;

//主持人收到的申请unmute的请求
@property(nonatomic, strong)NSMutableArray<NSString *> *applyingUnmuteMembers;

//是否举手
@property(nonatomic, assign)BOOL isHandup;

//主持人收到的举手的请求
@property(nonatomic, strong)NSMutableArray<NSString *> *handupMembers;

//是否直播中
- (BOOL)isBroadcasting;
@end
#endif
