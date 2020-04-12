//
//  ConversationTableViewCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BubbleTipView.h"
#import <WFChatClient/WFCChatClient.h>


@interface WFCUConversationTableViewCell : UITableViewCell
@property (strong, nonatomic) UIImageView *potraitView;
@property (strong, nonatomic) UILabel *targetView;
@property (strong, nonatomic) UILabel *digestView;
@property (strong, nonatomic) UIImageView *statusView;
@property (strong, nonatomic) UILabel *timeView;
@property (strong, nonatomic) UIImageView *silentView;
@property (nonatomic, strong)BubbleTipView *bubbleView;
@property (nonatomic, strong)WFCCConversationInfo *info;
@property (nonatomic, strong)WFCCConversationSearchInfo *searchInfo;
@property (nonatomic, assign, getter=isBig)BOOL big;

@end
