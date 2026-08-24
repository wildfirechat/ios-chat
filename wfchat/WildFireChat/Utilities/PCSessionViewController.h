//
//  PCSessionViewController.h
//  WildFireChat
//
//  Created by heavyrain lee on 2019/3/2.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface PCSessionViewController : UIViewController
// 全部在线设备（调用方传入，页面内会随 kSettingUpdated 通知刷新）
@property (nonatomic, strong)NSArray<WFCCPCOnlineInfo *> *pcOnlineInfos;
@end

NS_ASSUME_NONNULL_END
