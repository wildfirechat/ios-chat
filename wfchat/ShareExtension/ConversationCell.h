//
//  ConversationCell.h
//  ShareExtension
//
//  Created by Tom Lee on 2020/10/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SharedConversation.h"
NS_ASSUME_NONNULL_BEGIN

@interface ConversationCell : UITableViewCell
@property(nonatomic, strong)UIImageView *portraitView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)SharedConversation *conversation;
@end

NS_ASSUME_NONNULL_END
