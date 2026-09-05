//
//  WFCUGroupMemberCollectionViewController.h
//  WFChatUIKit
//
//  Created by heavyrain lee on 2019/8/18.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUGroupMemberCollectionViewController : UIViewController
@property(nonatomic, strong)NSString *groupId;
// 入口会话的 line（普通群=0，AI 群=2）；群成员管理通知发到该 line
@property(nonatomic, assign)int line;
@end

NS_ASSUME_NONNULL_END
