//
//  WFCUConferenceManager.h
//  WFChatUIKit
//
//  Created by Tom Lee on 2021/2/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WFCUConferenceManagerDelegate <NSObject>
-(void)onChangeModeRequest:(BOOL)isAudience;
@end

@interface WFCUConferenceManager : NSObject
+ (WFCUConferenceManager *)sharedInstance;
@property (nonatomic, weak) id<WFCUConferenceManagerDelegate> delegate;

- (void)request:(NSString *)userId changeModel:(BOOL)isAudience inConference:(NSString *)conferenceId;
- (void)kickoff:(NSString *)userId inConference:(NSString *)conferenceId;
- (void)requestChangeModel:(BOOL)isAudience inConference:(NSString *)conferenceId;
@end
