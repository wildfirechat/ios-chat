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
 @param path 图片存储路径
 
 @return 图片消息
 */
+ (instancetype)contentFrom:(UIImage *)image cachePath:(NSString *)path;

/**
 缩略图，自动生成
 */
@property (nonatomic, strong)UIImage *thumbnail;

/**
 图片尺寸
 */
@property (nonatomic, assign, readonly)CGSize size;

/**
 图片缩略图参数
 */
@property (nonatomic, strong)NSString *thumbParameter;

@end
