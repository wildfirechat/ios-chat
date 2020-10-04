//
//  ShareMessageView.h
//  TYAlertControllerDemo
//
//  Created by tanyang on 15/10/26.
//  Copyright © 2015年 tanyang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

@interface WFCUShareMessageView : UIView
@property(nonatomic, strong)WFCCConversation *conversation;
@property(nonatomic, strong)WFCCMessage *message;
@property(nonatomic, strong)NSArray<WFCCMessage *> *messages;
@property(nonatomic, strong)void (^forwardDone)(BOOL success);
@end
