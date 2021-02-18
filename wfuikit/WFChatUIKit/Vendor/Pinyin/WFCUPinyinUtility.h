//
//  WFCUPinyinUtility.h
//  WFChatUIKit
//
//  Created by dali on 2021/1/28.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUPinyinModel : NSObject
@property (nonatomic, strong)NSMutableArray *jianpin;
@property (nonatomic, strong)NSMutableArray *quanpin;
@end

@interface WFCUPinyinUtility : NSObject
-(BOOL)isMatch:(NSString *)name ofPinYin:(NSString *)pinyin;
- (BOOL)isChinese:(NSString *)text;
@end

NS_ASSUME_NONNULL_END
