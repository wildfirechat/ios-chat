//
//  WFCUGroupAnnouncement.m
//  WFChatUIKit
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "WFCUGroupAnnouncement.h"

@implementation WFCUGroupAnnouncement
- (NSData *)data {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:self.groupId forKey:@"gid"];
    [dict setValue:self.author forKey:@"a"];
    [dict setValue:self.text forKey:@"t"];
    [dict setValue:@(self.timestamp) forKey:@"ts"];
    return [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
}

- (void)setData:(NSData *)data {
    if (data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        self.groupId = [dict objectForKey:@"gid"];
        self.author = [dict objectForKey:@"a"];
        self.text = [dict objectForKey:@"t"];
        self.timestamp = [[dict objectForKey:@"ts"] longValue];
    }
}

- (void)setText:(NSString *)text {
    if ([text isKindOfClass:[NSNull class]]) {
        _text = nil;
    } else {
        _text = text;
    }
}

- (void)setAuthor:(NSString *)author {
    if ([author isKindOfClass:[NSNull class]]) {
        _author = nil;
    } else {
        _author = author;
    }
}
@end
