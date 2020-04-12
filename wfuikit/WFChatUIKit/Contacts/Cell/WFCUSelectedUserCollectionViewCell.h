//
//  SelectedUserCollectionViewCell.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/4.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFCUSelectedUserInfo.h"
NS_ASSUME_NONNULL_BEGIN

@interface WFCUSelectedUserCollectionViewCell : UICollectionViewCell
@property (nonatomic, strong)WFCUSelectedUserInfo *user;
@property (nonatomic, strong)UIImageView *imgV;
@property (nonatomic, assign)BOOL isSmall;
@end

NS_ASSUME_NONNULL_END
