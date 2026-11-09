//
//  WFMFeed.h
//  WFMomentClient
//
//  Created by Heavyrain Lee on 2019/6/7.
//  Copyright © 2019 Heavyrain Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFMomentDefine.h"
#import "WFMComment.h"

@class WFMFeedMessageContent;
@class WFCCMessage;

NS_ASSUME_NONNULL_BEGIN
@interface WFMFeedEntry : NSObject
@property(nonatomic, strong)NSString *mediaUrl;
@property(nonatomic, strong)NSString *thumbUrl;
@property(nonatomic, assign)int mediaWidth;
@property(nonatomic, assign)int mediaHeight;
@end

@interface WFMFeed : NSObject
@property(nonatomic, assign)long long feedUid;
@property(nonatomic, strong)NSString *sender;
@property(nonatomic, assign)WFMContentType type;
@property(nonatomic, strong)NSString *text;
@property(nonatomic, strong)NSArray<WFMFeedEntry *> *medias;
@property(nonatomic, strong)NSArray<NSString *> *mentionedUser;
@property(nonatomic, strong)NSArray<NSString *> *toUsers;
@property(nonatomic, strong)NSArray<NSString *> *excludeUsers;
@property(nonatomic, assign)long long serverTime;
@property(nonatomic, strong)NSString *extra;

@property(nonatomic, strong)NSMutableArray<WFMComment *> *comments;
@property(nonatomic, assign, readonly)BOOL hasMoreComments;

@property(nonatomic, strong)NSData *data;
@property(nonatomic, strong)NSDictionary *dict;

+ (instancetype)feedOf:(WFMFeedMessageContent *)feedContent;
@end

NS_ASSUME_NONNULL_END
