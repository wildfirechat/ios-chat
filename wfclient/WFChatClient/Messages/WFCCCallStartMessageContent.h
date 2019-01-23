//
//  WFCCTextMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 电话总结消息
 */
@interface WFCCCallStartMessageContent : WFCCMessageContent


/**
 CallId
 */
@property (nonatomic, strong)NSString *callId;
/**
 对端用户Id
 */
@property (nonatomic, strong)NSString *targetId;
/**
 * 开始时间
 */
@property (nonatomic, assign)long long connectTime;
/**
 * 结束时间
 */
@property (nonatomic, assign)long long endTime;
/* 结束原因
WFAVCallEndReason
 0: kWFAVCallEndReasonUnknown,
 1: kWFAVCallEndReasonBusy,
 2: kWFAVCallEndReasonSignalError,
 3: kWFAVCallEndReasonHangup,
 4: kWFAVCallEndReasonMediaError,
 5: kWFAVCallEndReasonRemoteHangup,
 6: kWFAVCallEndReasonOpenCameraFailure,
 7: kWFAVCallEndReasonTimeout,
 8: kWFAVCallEndReasonAcceptByOtherClient
 */
@property (nonatomic, assign)int status;

/*
 * 是否仅音频
 */
@property (nonatomic, assign, getter=isAudioOnly)BOOL audioOnly;

@end
