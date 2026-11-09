//
//  WFMCommentMessageContent.h
//  WFMomentClient
//
//  Created by Heavyrain Lee on 2019/6/7.
//  Copyright © 2019 Heavyrain Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFMComment.h"
#import "WFMomentDefine.h"
#import "WFMFeed.h"
#import <WFChatClient/WFCChatClient.h>

#define MESSAGE_CONTENT_TYPE_COMMENT 502


NS_ASSUME_NONNULL_BEGIN
@class WFCCMessageContent;

@interface WFMCommentMessageContent : WFCCMessageContent
@property(nonatomic, assign)long long feedId;
@property(nonatomic, assign)long long commentId;
@property(nonatomic, assign)long long replyCommentId;
@property(nonatomic, strong)NSString *sender;
@property(nonatomic, assign)WFMCommentType type;
@property(nonatomic, strong)NSString *text;

@property(nonatomic, strong)NSString *replyTo;
@property(nonatomic, assign)long long serverTime;

@property(nonatomic, assign)WFMContentType feedType;
@property(nonatomic, strong)NSString *feedText;
@property(nonatomic, strong)NSArray<WFMFeedEntry *> *feedMedias;
@property(nonatomic, strong)NSString *feedSender;
@end

NS_ASSUME_NONNULL_END
