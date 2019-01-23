//
//  ChatroomItemCell.h
//  WildFireChat
//
//  Created by heavyrain lee on 2018/8/24.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

@interface ChatroomItemCell : UICollectionViewCell
@property(nonatomic, strong)UIImageView *portraitIV;
@property(nonatomic, strong)UILabel *titleLable;
@property(nonatomic, strong)WFCCChatroomInfo *chatroomInfo;
@end
