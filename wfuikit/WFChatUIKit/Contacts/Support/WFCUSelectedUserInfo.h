//
//  WFCSelectedUserInfo.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import <WFChatClient/WFCCUserInfo.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SelectedStatusType) {
    Disable,
    Unchecked,
    Checked,
};
@interface WFCUSelectedUserInfo : WFCCUserInfo
@property (nonatomic, assign)SelectedStatusType selectedStatus;
@end

NS_ASSUME_NONNULL_END
