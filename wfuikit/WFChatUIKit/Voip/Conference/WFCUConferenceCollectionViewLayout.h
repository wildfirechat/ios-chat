//
//  WFCUConferenceCollectionViewLayout.h
//  WFChatUIKit
//
//  Created by Rain on 2022/9/21.
//  Copyright © 2022 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUConferenceCollectionViewLayout : UICollectionViewLayout
- (CGPoint)getOffsetOfItems:(NSArray<NSIndexPath *> *)items leftItems:(NSMutableArray<NSIndexPath *> *)leftItems rightItems:(NSMutableArray<NSIndexPath *> *)rightItems;
@end

NS_ASSUME_NONNULL_END
