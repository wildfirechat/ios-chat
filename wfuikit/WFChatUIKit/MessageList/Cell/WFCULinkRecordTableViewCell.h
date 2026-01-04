//
//  WFCULinkRecordTableViewCell.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/1/4.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WFCCMessage;

NS_ASSUME_NONNULL_BEGIN
@interface WFCULinkRecordTableViewCell : UITableViewCell
@property(nonatomic, strong)WFCCMessage *message;
+ (CGFloat)sizeOfMessage:(WFCCMessage *)msg withCellWidth:(CGFloat)width;
@end

NS_ASSUME_NONNULL_END
