//
//  WFCCUserOnlineState.h
//  WFChatClient
//
//  Created by heavyrain on 2022/2/17.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCCClientState : NSObject
@property(nonatomic, assign)int platform;
@property(nonatomic, assign)int state;
@end

@interface WFCCUserCustomState : NSObject
@property(nonatomic, assign)int state;
@property(nonatomic, strong)NSString *text;
@end

@interface WFCCUserOnlineState : NSObject
@property(nonatomic, strong)NSString *userId;
@property(nonatomic, strong)WFCCUserCustomState *customState;
@property(nonatomic, strong)NSArray<WFCCClientState *> *clientStates;
@end

NS_ASSUME_NONNULL_END
