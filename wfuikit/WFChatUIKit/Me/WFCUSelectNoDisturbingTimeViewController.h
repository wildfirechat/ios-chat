//
//  WFCUSelectNoDisturbingTimeViewController.h
//  WFChatUIKit
//
//  Created by dali on 2020/10/27.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUSelectNoDisturbingTimeViewController : UIViewController
@property(nonatomic, assign)int startMins;
@property(nonatomic, assign)int endMins;

@property(nonatomic, strong)void (^onSelectTime)(int startMins, int endMins);
@end

NS_ASSUME_NONNULL_END
