//
//  WFCUMultiCallOngoingExpendedCell.h
//  WFChatUIKit
//
//  Created by Rain on 2022/5/8.
//  Copyright © 2022 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol WFCUMultiCallOngoingExpendedCellDelegate <NSObject>
-(void)didJoinButtonPressed;
-(void)didCancelButtonPressed;
@end

@interface WFCUMultiCallOngoingExpendedCell : UITableViewCell
@property(nonatomic, weak)id<WFCUMultiCallOngoingExpendedCellDelegate> delegate;
@property(nonatomic, strong)UILabel *callHintLabel;
@property(nonatomic, strong)UIButton *joinButton;
@property(nonatomic, strong)UIButton *cancelButton;
@end

NS_ASSUME_NONNULL_END
