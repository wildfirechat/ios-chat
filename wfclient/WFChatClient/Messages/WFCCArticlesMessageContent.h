//
//  WFCCArticlesMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

@class WFCCLinkMessageContent;
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
@property (nonatomic, strong)WFCCArticle *topArticle;
@property (nonatomic, strong)NSArray<WFCCArticle *> *subArticles;

- (NSArray<WFCCLinkMessageContent *> *)toLinkMessageContent;
@end
