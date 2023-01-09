//
//  WFCUSelectedUserTableViewCell.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFCUSelectModel.h"
NS_ASSUME_NONNULL_BEGIN

@class WFCUOrganization;
@class WFCUSelectModel;
@protocol WFCUSelectedUserTableViewCellDelegate <NSObject>
- (void)didTapNextLevel:(WFCUSelectModel *)organization;
@end

@interface WFCUSelectedUserTableViewCell : UITableViewCell
@property (nonatomic, weak)id<WFCUSelectedUserTableViewCellDelegate> delegate;
@property (nonatomic, strong)WFCUSelectModel *selectedObject;
@property(nonatomic, strong)UIImageView *checkImageView;
@property(nonatomic, strong)UIImageView *portraitView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UIButton *nextLevel;

@end

NS_ASSUME_NONNULL_END
