//
//  WFCUParticipantCollectionViewCell.h
//  WFChatUIKit
//
//  Created by dali on 2020/1/20.
//  Copyright © 2020 Tom Lee. All rights reserved.
//
#if WFCU_SUPPORT_VOIP
#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>
#import <WFAVEngineKit/WFAVEngineKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUParticipantCollectionViewCell : UICollectionViewCell
- (void)setUserInfo:(WFCCUserInfo *)userInfo callProfile:(WFAVParticipantProfile *)profile;
@end

NS_ASSUME_NONNULL_END
#endif
