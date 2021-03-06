//
//  WFCUUploadFileTableViewCell.h
//  WFChatUIKit
//
//  Created by heavyrain.lee on 2021/3/6.
//  Copyright © 2021 Wildfire Chat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCCConversation;
@class WFCUUploadFileModel;
@class WFCUUploadFileTableViewCell;

@protocol WFCUUploadFileTableViewCellDelegate <NSObject>
- (void)didTapUpload:(WFCUUploadFileTableViewCell *)cell model:(WFCUUploadFileModel *)model;
- (void)didTapCancelUpload:(WFCUUploadFileTableViewCell *)cell model:(WFCUUploadFileModel *)model;
- (void)didTapSend:(WFCUUploadFileTableViewCell *)cell model:(WFCUUploadFileModel *)model;
- (void)didTapForward:(WFCUUploadFileTableViewCell *)cell model:(WFCUUploadFileModel *)model;
@end

@interface WFCUUploadFileTableViewCell : UITableViewCell
@property(nonatomic, strong)WFCUUploadFileModel *bigFileModel;
@property (nonatomic, strong)WFCCConversation *conversation;
@property (nonatomic, weak)id<WFCUUploadFileTableViewCellDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
