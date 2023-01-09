//
//  WFCSelectedUserInfo.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <WFChatClient/WFCCUserInfo.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SelectedStatusType) {
    Disable_Checked,
    Unchecked,
    Checked,
    Disable_Unchecked
};
@class WFCUOrganization;
@class WFCUEmployee;
@interface WFCUSelectModel : NSObject
@property(nonatomic, strong)WFCCUserInfo *userInfo;
@property(nonatomic, strong)WFCUOrganization *organization;
@property(nonatomic, strong)WFCUEmployee *employee;
@property (nonatomic, assign)SelectedStatusType selectedStatus;
@property(nonatomic, strong)NSMutableArray<NSNumber *> *paths;
@end

NS_ASSUME_NONNULL_END
