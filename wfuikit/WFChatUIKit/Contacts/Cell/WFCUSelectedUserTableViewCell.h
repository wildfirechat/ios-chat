//
//  WFCUSelectedUserTableViewCell.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFCUSelectedUserInfo.h"
NS_ASSUME_NONNULL_BEGIN

@interface WFCUSelectedUserTableViewCell : UITableViewCell
@property (nonatomic, strong)WFCUSelectedUserInfo *selectedUserInfo;
@property(nonatomic, strong)UIImageView *checkImageView;
@property(nonatomic, strong)UIImageView *portraitView;
@property(nonatomic, strong)UILabel *nameLabel;

@end

NS_ASSUME_NONNULL_END
