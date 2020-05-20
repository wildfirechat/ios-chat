//
//  MessageCellBase.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFCUMessageModel.h"

@class WFCUMessageCellBase;

@protocol WFCUMessageCellDelegate <NSObject>
- (void)didTapMessageCell:(WFCUMessageCellBase *)cell withModel:(WFCUMessageModel *)model;
- (void)didTapMessagePortrait:(WFCUMessageCellBase *)cell withModel:(WFCUMessageModel *)model;
- (void)didLongPressMessageCell:(WFCUMessageCellBase *)cell withModel:(WFCUMessageModel *)model;
- (void)didLongPressMessagePortrait:(WFCUMessageCellBase *)cell withModel:(WFCUMessageModel *)model;
- (void)didTapResendBtn:(WFCUMessageModel *)model;

- (void)didSelectUrl:(WFCUMessageCellBase *)cell withModel:(WFCUMessageModel *)model withUrl:(NSString *)urlString;
- (void)didSelectPhoneNumber:(WFCUMessageCellBase *)cell withModel:(WFCUMessageModel *)model withPhoneNumber:(NSString *)phoneNumber;
- (void)reeditRecalledMessage:(WFCUMessageCellBase *)cell withModel:(WFCUMessageModel *)model;

@optional
- (void)didTapReceiptView:(WFCUMessageCellBase *)cell withModel:(WFCUMessageModel *)model;
@end

@interface WFCUMessageCellBase : UICollectionViewCell
@property (nonatomic, strong)UILabel *timeLabel;
@property (nonatomic, strong)WFCUMessageModel *model;
@property (nonatomic, weak)id<WFCUMessageCellDelegate> delegate;
+ (CGSize)sizeForCell:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width;
+ (CGFloat)hightForTimeLabel:(WFCUMessageModel *)msgModel;

- (void)onTaped:(id)sender;
- (void)onLongPressed:(id)sender;
@end
