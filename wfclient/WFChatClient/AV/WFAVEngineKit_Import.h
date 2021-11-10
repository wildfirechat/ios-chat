//
//  WFAVEngineKit.h
//  WFAVEngineKit
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WFAVEngineKit : NSObject
+ (instancetype _Nonnull)sharedEngineKit;
@property(nonatomic, assign, readonly)BOOL supportMultiCall;
@property(nonatomic, assign, readonly)BOOL supportConference;
- (BOOL)checkAddress:(NSString *_Nonnull)host;
@end
