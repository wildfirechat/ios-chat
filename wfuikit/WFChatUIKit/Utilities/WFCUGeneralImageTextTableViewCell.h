//
//  WFCUGeneralImageTextTableViewCell.h
//  WFChatUIKit
//
//  Created by Rain on 2023/4/20.
//  Copyright © 2023 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUGeneralImageTextTableViewCell : UITableViewCell
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier cellHeight:(float)height;
@property(nonatomic, strong)UIImageView *portraitIV;
@property(nonatomic, strong)UILabel *titleLable;
@end

NS_ASSUME_NONNULL_END
