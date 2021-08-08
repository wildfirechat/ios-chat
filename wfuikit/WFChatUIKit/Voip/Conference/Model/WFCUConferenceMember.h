//
//  WFCUConferenceMember.h
//  WFChatUIKit
//
//  Created by Tom Lee on 2021/2/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUConferenceMember : NSObject
@property (nonatomic, strong)NSString *userId;
@property (nonatomic, assign)BOOL isHost;
@property (nonatomic, assign)BOOL isAudioEnabled;
@property (nonatomic, assign)BOOL isVideoEnabled;
@property (nonatomic, assign)BOOL isMe;
@property (nonatomic, assign)BOOL isAudience;
@property (nonatomic, assign)BOOL isAudioOnly;
@end

NS_ASSUME_NONNULL_END
