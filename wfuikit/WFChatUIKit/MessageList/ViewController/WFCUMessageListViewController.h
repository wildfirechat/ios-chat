//
//  MessageListViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/31.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WFCCConversation;

/// 会话页改动了会话本身的状态（清未读、存/清草稿），object 是那个会话。
/// 这两件事 SDK 都不发通知：iPhone 上返回会话列表会走 viewWillAppear 整表刷新，看不出来；
/// iPad 双栏下左栏那张列表一直挂在屏上，靠这条通知更新对应的那一行。
UIKIT_EXTERN NSString *const WFCUConversationInfoDidChangeNotification;

@interface WFCUMessageListViewController : UIViewController
@property (nonatomic, strong)WFCCConversation *conversation;

@property (nonatomic, strong)NSString *highlightText;
@property (nonatomic, assign)long highlightMessageId;

//显示某天消息，用于按时间搜索
@property(nonatomic, strong)NSDate *selectedDate;

//仅限于在Channel内使用。Channel的owner对订阅Channel单个用户发起一对一私聊
@property (nonatomic, strong)NSString *privateChatUser;

@property (nonatomic, assign)BOOL multiSelecting;
@property (nonatomic, strong)NSMutableArray *selectedMessageIds;

//静默加入聊天室，不发送欢迎语和告别语
@property (nonatomic, assign)BOOL silentJoinChatroom;

//保持在聊天室中，关掉聊天窗口也不退出
@property (nonatomic, assign)BOOL keepInChatroom;

//VC是presented的，关闭方式与push进入有所不同。
@property (nonatomic, assign)BOOL presented;
@end
