//
//  ContactTableViewCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUContactTableViewCell : UITableViewCell
@property (nonatomic, strong)NSString *userId;

@property (nonatomic, strong)UIImageView *portraitView;
@property (nonatomic, strong)UILabel *nameLabel;

@property (nonatomic, strong)NSString *groupAlias;

@property (nonatomic, assign, getter=isBig)BOOL big;
@end
