//
//  WFCUGroupAnnouncementViewController.h
//  WFChatUIKit
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFCUGroupAnnouncement.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFCUGroupAnnouncementViewController : UIViewController
@property(nonatomic, strong)WFCUGroupAnnouncement *announcement;
@property(nonatomic, assign)BOOL isManager;
@end

NS_ASSUME_NONNULL_END
