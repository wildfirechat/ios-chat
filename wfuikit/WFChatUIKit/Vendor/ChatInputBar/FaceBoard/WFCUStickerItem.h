//
//  StickerItem.h
//  WildFireChat
//
//  Created by heavyrain lee on 2018/8/28.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WFCUStickerItem : NSObject
@property(nonatomic, strong)NSString *key;
@property(nonatomic, strong)NSString *tabIcon;
@property(nonatomic, strong)NSMutableArray<NSString *> *stickerPaths;
@end
