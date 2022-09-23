//
//  WFCUFloatingWindow.h
//  WFDemo
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//
#if WFCU_SUPPORT_VOIP
#import <Foundation/Foundation.h>
#import <WFAVEngineKit/WFAVEngineKit.h>

@class WFZConferenceInfo;
/*!
 最小化显示的悬浮窗
 */
@interface WFCUFloatingWindow : NSObject

/*!
 悬浮窗的Window
 */
@property(nonatomic, strong) UIWindow *window;

/*!
 音频通话最小化时的Button
 */
@property(nonatomic, strong) UIButton *floatingButton;

/*!
 视频通话最小化时的视频View
 */
@property(nonatomic, strong) UIView *videoView;

/*!
 当前的通话实体
 */
@property(nonatomic, strong) WFAVCallSession *callSession;

/*!
 开启悬浮窗

 @param callSession  通话实体
 @param focusUserProfile  焦点用户
 @param touchedBlock 悬浮窗点击的Block
 */
+ (void)startCallFloatingWindow:(WFAVCallSession *)callSession conferenceInfo:(WFZConferenceInfo *)conferenceInfo focusUser:(WFAVParticipantProfile *)focusUserProfile
              withTouchedBlock:(void (^)(WFAVCallSession *callSession, WFZConferenceInfo *conferenceInfo))touchedBlock;

/*!
 关闭当前悬浮窗
 */
+ (void)stopCallFloatingWindow;

@end
#endif
