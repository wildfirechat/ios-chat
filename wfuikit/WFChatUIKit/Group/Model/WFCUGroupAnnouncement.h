//
//  WFCUGroupAnnouncement.h
//  WFChatUIKit
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUGroupAnnouncement : NSObject
@property(nonatomic, strong)NSString *groupId;
@property(nonatomic, strong)NSString *author;
@property(nonatomic, strong)NSString *text;
@property(nonatomic, assign)long timestamp;


//用于存储和恢复
@property(nonatomic, strong)NSData *data;
@end

NS_ASSUME_NONNULL_END
