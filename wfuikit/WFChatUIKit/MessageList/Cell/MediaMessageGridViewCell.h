//
//  MediaMessageGridViewCell.h
//  WFChatUIKit
//
//  Created by dali on 2020/7/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class WFCCMessage;
@interface MediaMessageGridViewCell : UICollectionViewCell
@property(nonatomic, strong)WFCCMessage *mediaMessage;
@end

NS_ASSUME_NONNULL_END
