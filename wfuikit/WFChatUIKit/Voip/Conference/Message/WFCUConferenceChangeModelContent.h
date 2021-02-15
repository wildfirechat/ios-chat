//
//  WFCUConferenceChangeModelContent.h
//  WFChatUIKit
//
//  Created by Tom Lee on 2021/2/15.
//  Copyright © 2021 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

@interface WFCUConferenceChangeModelContent : WFCCMessageContent
@property (nonatomic, strong) NSString *conferenceId;
@property (nonatomic, assign) BOOL isAudience;
@end
