//
//  ConversationSettingMemberCollectionViewLayout.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/11/3.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUConversationSettingMemberCollectionViewLayout : UICollectionViewFlowLayout
- (instancetype)initWithItemMargin:(CGFloat)itemMargin;
- (CGFloat)getHeigthOfItemCount:(int)itemCount;
@end
