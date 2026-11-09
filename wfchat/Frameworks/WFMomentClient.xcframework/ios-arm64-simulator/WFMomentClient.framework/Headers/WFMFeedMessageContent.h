//
//  WFMFeedMessageContent.h
//  WFMomentClient
//
//  Created by Heavyrain Lee on 2019/6/7.
//  Copyright © 2019 Heavyrain Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFMFeed.h"
#import "WFMomentDefine.h"
#import <WFChatClient/WFCChatClient.h>

#define MESSAGE_CONTENT_TYPE_FEED 501

NS_ASSUME_NONNULL_BEGIN
@class WFCCMessageContent;
@interface WFMFeedMessageContent : WFCCMessageContent
@property(nonatomic, assign)long long feedId;
@property(nonatomic, assign)WFMContentType type;
@property(nonatomic, strong)NSString *text;
@property(nonatomic, strong)NSArray<WFMFeedEntry *> *medias;
@property(nonatomic, strong)NSString *sender;
@property(nonatomic, strong)NSArray<NSString *> *toUsers;
@property(nonatomic, strong)NSArray<NSString *> *excludeUsers;

@property(nonatomic, strong)NSString *extra;
@end

NS_ASSUME_NONNULL_END
