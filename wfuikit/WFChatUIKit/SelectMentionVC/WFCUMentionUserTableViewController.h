//
//  WFCUMentionUserTableViewController.h
//  WFChatUIKit
//
//  Created by WF Chat on 2018/10/24.
//  Copyright © 2018 WF Chat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol WFCUMentionUserDelegate <NSObject>
- (void)didMentionType:(int)type user:(NSString *)userId range:(NSRange)range text:(NSString *)text;
- (void)didCancelMentionAtRange:(NSRange)range;
@end

@class WFCCConversation;
@interface WFCUMentionUserTableViewController : UIViewController
@property (nonatomic, strong)NSString *groupId;
@property (nonatomic, weak)id<WFCUMentionUserDelegate> delegate;
@property (nonatomic, assign)NSRange range;
@end

NS_ASSUME_NONNULL_END
