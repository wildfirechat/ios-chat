//
//  ShareAppService.h
//  ShareExtension
//
//  Created by Tom Lee on 2020/10/7.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SharedConversation.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShareAppService : NSObject
+ (ShareAppService *)sharedAppService;

- (void)sendLinkMessage:(SharedConversation *)conversation link:(NSString *)link title:(NSString *)title thumbnailLink:(NSString *)thumbnailLink success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock;

@end

NS_ASSUME_NONNULL_END
