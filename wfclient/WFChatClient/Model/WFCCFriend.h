//
//  WFCCFriend.h
//  WFChatClient
//
//  Created by heavyrain on 2021/5/16.
//  Copyright © 2021 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCCFriend : NSObject
/*
 好友ID
 */
@property(nonatomic, strong)NSString *userId;

/*
 好友昵称
 */
@property(nonatomic, strong)NSString *alias;

/*
 扩展信息，添加方式等
 */
@property(nonatomic, strong)NSString *extra;

/*
 添加好友时间
 */
@property(nonatomic, assign)long long timestamp;
@end

NS_ASSUME_NONNULL_END
