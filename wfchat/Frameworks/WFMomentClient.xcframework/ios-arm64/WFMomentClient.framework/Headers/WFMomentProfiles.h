//
//  WFMomentProfiles.h
//  WFMomentClient
//
//  Created by heavyrain lee on 2019/7/18.
//  Copyright © 2019 Heavyrain Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WFMVisiableScope) {
    WFMVisiableScope_NoLimit,
    WFMVisiableScope_3Days,
    WFMVisiableScope_1Month,
    WFMVisiableScope_6Months,
};


@interface WFMomentProfiles : NSObject
@property(nonatomic, strong)NSString *backgroupUrl;
@property(nonatomic, strong)NSArray<NSString *> *blackList;
@property(nonatomic, strong)NSArray<NSString *> *blockList;
@property(nonatomic, assign)int strangerVisiableCount;
@property(nonatomic, assign)WFMVisiableScope visiableScope;
@property(nonatomic, assign)long long updateDt;

@property(nonatomic, strong)NSData *data;
@end
