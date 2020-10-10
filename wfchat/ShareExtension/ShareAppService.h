//
//  ShareAppService.h
//  ShareExtension
//
//  Created by Tom Lee on 2020/10/7.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SharedConversation.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShareAppService : NSObject
+ (ShareAppService *)sharedAppService;

- (void)sendLinkMessage:(SharedConversation *)conversation link:(NSString *)link title:(NSString *)title thumbnailLink:(NSString *)thumbnailLink success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock;

- (void)sendTextMessage:(SharedConversation *)conversation text:(NSString *)text success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock;

- (void)sendImageMessage:(SharedConversation *)conversation mediaUrl:(NSString *)mediaUrl thubnail:(UIImage *)thubnail success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock;

- (void)sendFileMessage:(SharedConversation *)conversation mediaUrl:(NSString *)mediaUrl fileName:(NSString *)fileName size:(long long)size success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock;

- (void)uploadFiles:(NSString *)file
          mediaType:(int)mediaType
          fullImage:(BOOL)fullImage
           progress:(void(^)(int sentcount, int total))progressBlock
            success:(void(^)(NSString *url))successBlock
              error:(void(^)(NSString *errorMsg))errorBlock;

- (BOOL)isLogin;
@end

NS_ASSUME_NONNULL_END
