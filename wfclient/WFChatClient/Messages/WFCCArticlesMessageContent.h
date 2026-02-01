//
//  WFCCArticlesMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

@class WFCCLinkMessageContent;
/**
文章内容
*/
@interface WFCCArticle : NSObject
@property (nonatomic, strong)NSString *articleId;
@property (nonatomic, strong)NSString *cover;
@property (nonatomic, strong)NSString *title;
@property (nonatomic, strong)NSString *digest;
@property (nonatomic, strong)NSString *url;
@property (nonatomic, assign)BOOL readReport;
@end

/**
 富通知消息
 */
@interface WFCCArticlesMessageContent : WFCCMessageContent
/**
顶部文章
*/
@property (nonatomic, strong)WFCCArticle *topArticle;
/**
子文章列表
*/
@property (nonatomic, strong)NSArray<WFCCArticle *> *subArticles;

/**
转换为链接消息

@return 链接消息数组
*/
- (NSArray<WFCCLinkMessageContent *> *)toLinkMessageContent;
@end
