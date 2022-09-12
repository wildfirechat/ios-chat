//
//  StartConferenceViewController.h
//  WFZoom
//
//  Created by WF Chat on 2021/9/3.
//  Copyright © 2021年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WFZConferenceInfo;
@interface WFZStartConferenceViewController : UIViewController
@property (nonatomic, strong)void (^createResult)(WFZConferenceInfo *conferenceInfo);
@end

NS_ASSUME_NONNULL_END
