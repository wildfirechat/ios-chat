//
//  SwitchTableViewCell.h
//  WildFireChat
//
//  Created by heavyrain lee on 27/12/2017.
//  Copyright © 2017 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

typedef NS_ENUM(NSInteger, SwitchType) {
    SwitchType_Conversation_None = 0,
    SwitchType_Conversation_Silent = 1,
    SwitchType_Conversation_Top = 2,
    SwitchType_Conversation_Save_To_Contact = 3,
    SwitchType_Conversation_Show_Alias = 4,
    SwitchType_Setting_Global_Silent = 5,
    SwitchType_Setting_Show_Notification_Detail = 6,
    SwitchType_Setting_Sync_Draft = 7,
};

@interface WFCUSwitchTableViewCell : UITableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier conversation:(WFCCConversation*)conversation;
@property(nonatomic, assign)SwitchType type;
@end
