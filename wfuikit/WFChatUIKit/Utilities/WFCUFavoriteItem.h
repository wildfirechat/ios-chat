//
//  WFCUFavoriteItem.h
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/11/1.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCCConversation;
@class WFCCMessageContent;


@interface WFCUFavoriteItem : NSObject
@property(nonatomic, assign)int favId;
@property(nonatomic, assign)int favType;
@property(nonatomic, assign)int64_t timestamp;
@property(nonatomic, strong)WFCCConversation *conversation;
@property(nonatomic, strong)NSString *origin;
@property(nonatomic, strong)NSString *sender;
@property(nonatomic, strong)NSString *title;
@property(nonatomic, strong)NSString *url;
@property(nonatomic, strong)NSString *thumbUrl;
@property(nonatomic, strong)NSString *data;

+ (WFCUFavoriteItem *)itemFromContent:(WFCCMessageContent *)content;
- (WFCCMessageContent *)toContent;
@end

NS_ASSUME_NONNULL_END
