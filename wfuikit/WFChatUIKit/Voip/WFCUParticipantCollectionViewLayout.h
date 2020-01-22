//
//  WFCUParticipantCollectionViewLayout.h
//  WFChatUIKit
//
//  Created by dali on 2020/1/21.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUParticipantCollectionViewLayout : UICollectionViewLayout
@property (assign, nonatomic) CGFloat itemWidth;
@property (assign, nonatomic) CGFloat itemHeight;
@property (assign, nonatomic) CGFloat itemSpace;
@property (assign, nonatomic) CGFloat lineSpace;
@end

NS_ASSUME_NONNULL_END
