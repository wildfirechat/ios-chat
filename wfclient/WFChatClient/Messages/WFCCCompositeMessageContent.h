//
//  WFCCCompositeMessageContent.h
//  WFChatClient
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"
@class WFCCMessage;

NS_ASSUME_NONNULL_BEGIN

@interface WFCCCompositeMessageContent : WFCCMessageContent
@property (nonatomic, strong)NSString *title;
@property (nonatomic, strong)NSArray<WFCCMessage *> *messages;
@end

NS_ASSUME_NONNULL_END
