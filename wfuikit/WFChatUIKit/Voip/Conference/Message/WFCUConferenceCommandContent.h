//
//  WFCUConferenceCommandContent.h
//  WFChatUIKit
//
//  Created by Heavyrain on 2022/10/02.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

/**
 命令消息的类型
 */
typedef NS_ENUM(NSInteger, WFCUConferenceCommandType) {
    //全体静音，只有主持人可以操作，结果写入conference profile中。带有参数是否允许成员自主解除静音。
    MUTE_ALL,
    //取消全体静音，只有主持人可以操作，结果写入conference profile中。带有参数是否邀请成员解除静音。
    CANCEL_MUTE_ALL,
    
    //要求某个用户更改静音状态，只有主持人可以操作。带有参数是否静音/解除静音。
    REQUEST_MUTE,
    //拒绝UNMUTE要求。（如果同意不需要通知对方同意)
    REJECT_UNMUTE_REQUEST,
    
    //普通用户申请解除静音，带有参数是请求，还是取消请求。
    APPLY_UNMUTE,
    //管理员批准解除静音申请，带有参数是同意，还是拒绝申请。
    APPROVE_UNMUTE,
    //管理员批准全部解除静音申请，带有参数是同意，还是拒绝申请。
    APPROVE_ALL_UNMUTE,
    
    //举手，带有参数是举手还是放下举手
    HANDUP,
    //主持人放下成员的举手
    PUT_HAND_DOWN,
    //主持人放下全体成员的举手
    PUT_ALL_HAND_DOWN,
    
    //录制，有参数是录制还是取消录制
    RECORDING
};

@interface WFCUConferenceCommandContent : WFCCMessageContent
+ (instancetype)commandOfType:(WFCUConferenceCommandType)type conference:(NSString *)conferenceId;
@property (nonatomic, assign) WFCUConferenceCommandType type;
@property (nonatomic, strong) NSString *conferenceId;
@property (nonatomic, strong) NSString *targetUserId;
@property (nonatomic, assign) BOOL boolValue;
@end
