//
//  WFMComment.h
//  WFMomentClient
//
//  Created by Heavyrain Lee on 2019/6/7.
//  Copyright © 2019 Heavyrain Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFMomentDefine.h"


NS_ASSUME_NONNULL_BEGIN

@class WFMCommentMessageContent;
@class WFCCMessage;

@interface WFMComment : NSObject
@property(nonatomic, assign)long long feedUid;
@property(nonatomic, assign)long long commentUid;
@property(nonatomic, assign)long long replyCommentUid;
@property(nonatomic, strong)NSString *sender;
@property(nonatomic, assign)WFMCommentType type;
@property(nonatomic, strong)NSString *text;
@property(nonatomic, strong)NSString *replyTo;
@property(nonatomic, assign)long long serverTime;
@property(nonatomic, strong)NSString *extra;

@property(nonatomic, strong)NSData *data;
@property(nonatomic, strong)NSDictionary *dict;

+ (instancetype)commentOf:(WFMCommentMessageContent *)commentContent;
@end

NS_ASSUME_NONNULL_END
