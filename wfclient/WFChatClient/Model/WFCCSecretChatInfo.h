//
//  WFCCSecretChatInfo.h
//  WFChatClient
//
//  Created by heavyrain on 2021/5/16.
//  Copyright © 2021 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 密聊状态

 - SecretChatState_Starting: 密聊会话建立中
 - SecretChatState_Accepting: 密聊会话接受中
 - SecretChatState_Established: 密聊会话已建立
 - SecretChatState_Canceled: 密聊会话已取消
 */
typedef NS_ENUM(NSInteger, WFCCSecretChatState) {
    SecretChatState_Starting,
    SecretChatState_Accepting,
    SecretChatState_Established,
    SecretChatState_Canceled
};

@interface WFCCSecretChatInfo : NSObject
/*
 密聊ID
 */
@property(nonatomic, strong)NSString *targetId;

/*
 用户ID
 */
@property(nonatomic, strong)NSString *userId;

/*
 密聊状态
 */
@property(nonatomic, assign)WFCCSecretChatState state;

/*
 阅后即焚时间
 */
@property(nonatomic, assign)int burnTime;

/*
   创建时间
 */
@property(nonatomic, assign)long long createTime;
@end

NS_ASSUME_NONNULL_END
