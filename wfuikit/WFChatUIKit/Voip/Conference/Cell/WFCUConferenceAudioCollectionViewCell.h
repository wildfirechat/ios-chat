//
//  WFCUConferenceAudioCollectionViewCell.h
//  WFChatUIKit
//
//  Created by Rain on 2022/10/5.
//  Copyright © 2022 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class WFAVParticipantProfile;
@interface WFCUConferenceAudioCollectionViewCell : UICollectionViewCell
- (void)setProfiles:(NSMutableArray<WFAVParticipantProfile *> *)participants pages:(NSUInteger)pages;
@end

NS_ASSUME_NONNULL_END
