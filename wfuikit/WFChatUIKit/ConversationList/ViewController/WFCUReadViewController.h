//
//  WFCUReadViewController.h
//  WFChatUIKit
//
//  Created by Rain on 2023/3/25.
//  Copyright © 2023 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUReadViewController : UIViewController
@property(nonatomic, strong)NSArray<NSString *> *userIds;
@property(nonatomic, strong)NSString *groupId;
@end

NS_ASSUME_NONNULL_END
