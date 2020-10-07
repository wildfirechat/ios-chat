//
//  SharedConversation.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/10/6.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "SharedConversation.h"

/*
 @property(nonatomic, assign)int type;
 @property(nonatomic, strong)NSString *target;
 @property(nonatomic, assign)int line;
 @property(nonatomic, strong)NSString *title;
 @property(nonatomic, strong)NSString *portraitUrl;
 */
@implementation SharedConversation
+ (BOOL)supportsSecureCoding {
    return YES;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:self.type forKey:@"type"];
    [coder encodeObject:self.target forKey:@"target"];
    [coder encodeInt:self.line forKey:@"line"];
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeObject:self.portraitUrl forKey:@"portrait"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.type = [coder decodeIntForKey:@"type"];
        self.target = [coder decodeObjectForKey:@"target"];
        self.line = [coder decodeIntForKey:@"line"];
        self.title = [coder decodeObjectForKey:@"title"];
        self.portraitUrl = [coder decodeObjectForKey:@"portrait"];
    }
    return self;
}
- (void)setTitle:(NSString *)title {
    if (!title) {
        _title = @"";
    } else {
        _title = title;
    }
}
- (void)setPortraitUrl:(NSString *)portraitUrl {
    if (!portraitUrl) {
        _portraitUrl = @"";
    } else {
        _portraitUrl = portraitUrl;
    }
}
+ (instancetype)from:(int)type target:(NSString *)target line:(int)line {
    SharedConversation *sc = [[SharedConversation alloc] init];
    sc.type = type;
    sc.target = target;
    sc.line = line;
    return sc;
}
@end
