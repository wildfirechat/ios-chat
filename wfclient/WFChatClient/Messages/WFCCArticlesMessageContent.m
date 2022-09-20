//
//  WFCCArticlesMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCArticlesMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"
#import "WFCCLinkMessageContent.h"

@implementation WFCCArticle
- (NSDictionary *)toDict {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if(self.articleId.length)
        dict[@"id"] = self.articleId;
    if(self.cover.length)
        dict[@"cover"] = self.cover;
    if(self.title.length)
        dict[@"title"] = self.title;
    if(self.digest.length)
        dict[@"digest"] = self.digest;
    if(self.url.length)
        dict[@"url"] = self.url;
    if(self.readReport)
        dict[@"rr"] = @(self.readReport);
    
    return dict;
}
+ (instancetype)fromDict:(NSDictionary *)dict {
    WFCCArticle *article = [[WFCCArticle alloc] init];
    article.articleId = dict[@"id"];
    article.cover = dict[@"cover"];
    article.title = dict[@"title"];
    article.digest = dict[@"digest"];
    article.url = dict[@"url"];
    article.readReport = [dict[@"rr"] boolValue];
    return article;
}
- (WFCCLinkMessageContent *)toLinkMessageContent {
    WFCCLinkMessageContent *link = [[WFCCLinkMessageContent alloc] init];
    link.url = self.url;
    link.title = self.title;
    link.thumbnailUrl = self.cover;
    link.contentDigest = self.digest;
    return link;
}
@end

@implementation WFCCArticlesMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.searchableContent = self.topArticle.title;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[self.topArticle toDict] forKey:@"top"];
    if(self.subArticles.count) {
        NSMutableArray *as = [[NSMutableArray alloc] init];
        [self.subArticles enumerateObjectsUsingBlock:^(WFCCArticle * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [as addObject:[obj toDict]];
        }];
        [dict setObject:as forKey:@"subArticles"];
    }
    
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:kNilOptions
                                                     error:nil];
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.topArticle = [WFCCArticle fromDict:dictionary[@"top"]];
        if([dictionary[@"subArticles"] isKindOfClass:NSArray.class]) {
            NSMutableArray *arr = [[NSMutableArray alloc] init];
            [dictionary[@"subArticles"] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [arr addObject:[WFCCArticle fromDict:obj]];
            }];
            self.subArticles = arr;
        }
    }
    
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_ARTICLES;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return self.topArticle.title;
}

- (NSArray<WFCCLinkMessageContent *> *)toLinkMessageContent {
    NSMutableArray *links = [[NSMutableArray alloc] init];
    [links addObject:[self.topArticle toLinkMessageContent]];
    [self.subArticles enumerateObjectsUsingBlock:^(WFCCArticle * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [links addObject:[obj toLinkMessageContent]];
    }];
    
    return links;
}
@end
