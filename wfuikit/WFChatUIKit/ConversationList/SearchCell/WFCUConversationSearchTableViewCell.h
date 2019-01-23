//
//  ConversationSearchTableViewCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BubbleTipView.h"
#import <WFChatClient/WFCChatClient.h>


@interface WFCUConversationSearchTableViewCell : UITableViewCell
@property (strong, nonatomic) UIImageView *potraitView;
@property (strong, nonatomic) UILabel *targetView;
@property (strong, nonatomic) UILabel *digestView;
@property (strong, nonatomic) UILabel *timeView;
@property (nonatomic, strong)WFCCMessage *message;
@property (nonatomic, strong)NSString *keyword;
@end
