//
//  WFCUConferenceCollectionViewLayout.h
//  WFChatUIKit
//
//  Created by Rain on 2022/9/21.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUConferenceCollectionViewLayout : UICollectionViewLayout
- (CGPoint)getOffsetOfItems:(NSArray<NSIndexPath *> *)items;
@property(nonatomic, assign)BOOL audioOnly;
@end

NS_ASSUME_NONNULL_END
