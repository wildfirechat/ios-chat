//
//  WFCCImageMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/2.
//  Copyright © 2017年 wildfire chat. All rights reserved.
//

#import "WFCCMediaMessageContent.h"
#import <UIKit/UIKit.h>

/**
 图片消息
 */
@interface WFCCImageMessageContent : WFCCMediaMessageContent

/**
 构造方法

 @param image 图片
 @return 图片消息
 */
+ (instancetype)contentFrom:(UIImage *)image;

/**
 缩略图，自动生成
 */
@property (nonatomic, strong)UIImage *thumbnail;

@end
