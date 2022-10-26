//
//  ConferenceInfo.h
//  WFZoom
//
//  Created by WF Chat on 2021/9/4.
//  Copyright © 2021年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface WFZConferenceInfo : NSObject
@property(nonatomic, strong)NSString *conferenceId;
@property(nonatomic, strong)NSString *conferenceTitle;
@property(nonatomic, strong)NSString *password;
@property(nonatomic, strong)NSString *pin;
@property(nonatomic, strong)NSString *owner;
@property(nonatomic, strong)NSArray<NSString *> *managers;
@property(nonatomic, strong)NSString *focus;
@property(nonatomic, assign)long long startTime;
@property(nonatomic, assign)long long endTime;
@property(nonatomic, assign)BOOL audience;
@property(nonatomic, assign)BOOL advance;
@property(nonatomic, assign)BOOL allowTurnOnMic;
@property(nonatomic, assign)BOOL noJoinBeforeStart;
@property(nonatomic, assign)BOOL recording;


+ (instancetype)fromDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;
@end

NS_ASSUME_NONNULL_END
