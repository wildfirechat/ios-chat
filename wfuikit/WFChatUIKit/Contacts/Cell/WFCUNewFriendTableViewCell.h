//
//  NewFriendTableViewCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BubbleTipView.h"

@interface WFCUNewFriendTableViewCell : UITableViewCell
@property (nonatomic, strong)UIImageView *portraitView;
@property (nonatomic, strong)UILabel *nameLabel;
@property (nonatomic, strong)BubbleTipView *bubbleView;
- (void)refresh;
@end
