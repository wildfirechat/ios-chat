//
//  WFCUPublicMenuButton.h
//  WFChatUIKit
//
//  Created by Rain on 2022/8/11.
//  Copyright © 2022 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

NS_ASSUME_NONNULL_BEGIN
@class WFCUPublicMenuButton;
@protocol WFCUPublicMenuButtonDelegate <NSObject>
- (void)didTapButton:(WFCUPublicMenuButton *)button menu:(WFCCChannelMenu *)channelMenu;
@end

@interface WFCUPublicMenuButton : UIButton
@property (nonatomic, strong)id<WFCUPublicMenuButtonDelegate> delegate;
- (void)setChannelMenu:(WFCCChannelMenu *)channelMenu isSubMenu:(BOOL)isSubMenu;


@property(nonatomic, assign)BOOL expended;
@property(nonatomic, strong)WFCCChannelMenu *channelMenu;
@end

NS_ASSUME_NONNULL_END
