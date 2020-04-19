//
//  SeletedUserViewController.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/2.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, WFCUSeletedUserHeaderViewLayoutType) {
    No = 0,
    Horizontal = 1,
    Vertical = 2
};

@interface WFCUSeletedUserViewController : UIViewController

//当前页面原则上不提供数据源需要外部提供，本页只做用户多选功能使用，为兼容以前版本当前可以不由外部提供数据
@property (nonatomic, strong)NSArray<WFCCUserInfo *> *inputData;

@property (nonatomic, assign)int maxSelectCount;//当多选时有效，0不限制。

@property (nonatomic, strong)NSString *groupId;

@property (nonatomic, strong)NSArray *candidateUsers;
@property (nonatomic, strong)NSArray *disableUserIds;
/// 布局类型为布局Vertical: 行数最大值为2
@property (nonatomic, assign)WFCUSeletedUserHeaderViewLayoutType type;
@property (nonatomic, strong)void (^selectResult)(NSArray<NSString *> *contacts);
@end

NS_ASSUME_NONNULL_END
