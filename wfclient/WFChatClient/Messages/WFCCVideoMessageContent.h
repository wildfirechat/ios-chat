//
//  WFCCVideoMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/2.
//  Copyright © 2017年 wildfire chat. All rights reserved.
//

#import "WFCCMediaMessageContent.h"
#import <UIKit/UIKit.h>

/**
视频消息
*/
@interface WFCCVideoMessageContent : WFCCMediaMessageContent

/**
 构造方法

 @param localPath 本地路径
 @param image 缩略图
 @return 视频消息
 */
+ (instancetype)contentPath:(NSString *)localPath thumbnail:(UIImage *)image;

/**
 缩略图
 */
@property (nonatomic, strong)UIImage *thumbnail;

/**
 时长
*/
@property (nonatomic, assign)long duration;
@end
