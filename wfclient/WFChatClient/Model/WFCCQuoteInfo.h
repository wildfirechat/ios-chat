//
//  WFCCQuoteInfo.h
//  WFChatClient
//
//  Created by dali on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCCQuoteInfo : NSObject
- (instancetype)initWithMessageUid:(long long)messageUid;
@property (nonatomic, assign)long long messageUid;
@property (nonatomic, strong)NSString *userId;
@property (nonatomic, strong)NSString *userDisplayName;
@property (nonatomic, strong)NSString *messageDigest;

- (NSDictionary *)encode;
- (void)decode:(NSDictionary *)dictData;
@end

NS_ASSUME_NONNULL_END
