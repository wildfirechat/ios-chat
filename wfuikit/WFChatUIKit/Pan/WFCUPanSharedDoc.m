//
//  WFCUPanSharedDoc.m
//  WFChatUIKit
//

#import "WFCUPanSharedDoc.h"

@implementation WFCUPanShareSource

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    WFCUPanShareSource *source = [[WFCUPanShareSource alloc] init];
    source.targetType = [dict[@"targetType"] isKindOfClass:[NSString class]] ? dict[@"targetType"] : nil;
    source.targetId = [dict[@"targetId"] isKindOfClass:[NSString class]] ? dict[@"targetId"] : nil;
    source.targetName = [dict[@"targetName"] isKindOfClass:[NSString class]] ? dict[@"targetName"] : nil;
    source.createdByName = [dict[@"createdByName"] isKindOfClass:[NSString class]] ? dict[@"createdByName"] : nil;
    source.createdAt = [dict[@"createdAt"] isKindOfClass:[NSString class]] ? dict[@"createdAt"] : nil;
    return source;
}

@end

@implementation WFCUPanSharedDoc

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    // SharedDocVO: {file:{...}, permission, sharedAt, sources:[...]}
    NSDictionary *fileDict = [dict[@"file"] isKindOfClass:[NSDictionary class]] ? dict[@"file"] : dict;
    WFCUPanFile *file = [WFCUPanFile fromDictionary:fileDict];
    if (!file) {
        return nil;
    }

    WFCUPanSharedDoc *doc = [[WFCUPanSharedDoc alloc] init];
    doc.file = file;
    doc.permission = [dict[@"permission"] isKindOfClass:[NSString class]] ? dict[@"permission"] : nil;
    doc.sharedAt = [dict[@"sharedAt"] isKindOfClass:[NSString class]] ? dict[@"sharedAt"] : nil;

    NSMutableArray<WFCUPanShareSource *> *sources = [NSMutableArray array];
    NSArray *items = dict[@"sources"];
    if ([items isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in items) {
            WFCUPanShareSource *source = [WFCUPanShareSource fromDictionary:item];
            if (source) {
                [sources addObject:source];
            }
        }
    }
    doc.sources = sources;

    return doc;
}

- (BOOL)canEdit {
    return [self.permission isEqualToString:@"EDIT"];
}

@end
