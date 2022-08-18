//
//  WFCCChannelMenu.h
//  WFChatClient
//
//  Created by Rain on 2022/8/11.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"

NS_ASSUME_NONNULL_BEGIN


@interface WFCCChannelMenu : WFCCJsonSerializer
@property(nonatomic, strong)NSString *menuId;
@property(nonatomic, strong)NSString *type;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, strong)NSString *key;
@property(nonatomic, strong)NSString *url;
@property(nonatomic, strong)NSString *mediaId;
@property(nonatomic, strong)NSString *articleId;
@property(nonatomic, strong)NSString *appId;
@property(nonatomic, strong)NSString *appPage;
@property(nonatomic, assign)NSString *extra;
@property(nonatomic, strong)NSArray<WFCCChannelMenu *> *subMenus;
@end

NS_ASSUME_NONNULL_END
