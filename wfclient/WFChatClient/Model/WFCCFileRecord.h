//
//  WFCCFileRecord.h
//  WFChatClient
//
//  Created by dali on 2020/8/2.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCConversation.h"
#import "WFCCJsonSerializer.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFCCFileRecord : WFCCJsonSerializer
@property (nonatomic, strong)WFCCConversation *conversation;
@property (nonatomic, assign)long long messageUid;
@property (nonatomic, strong)NSString *userId;
@property (nonatomic, strong)NSString *name;
@property (nonatomic, strong)NSString *url;
@property (nonatomic, assign)int size;
@property (nonatomic, assign)int downloadCount;
@property (nonatomic, assign)long long timestamp;
@end

NS_ASSUME_NONNULL_END
