//
//  InformationCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUInformationCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"


#define TEXT_TOP_PADDING 6
#define TEXT_BUTTOM_PADDING 6
#define TEXT_LEFT_PADDING 8
#define TEXT_RIGHT_PADDING 8


#define TEXT_LABEL_TOP_PADDING TEXT_TOP_PADDING + 4
#define TEXT_LABEL_BUTTOM_PADDING TEXT_BUTTOM_PADDING + 4
#define TEXT_LABEL_LEFT_PADDING 30
#define TEXT_LABEL_RIGHT_PADDING 30

@implementation WFCUInformationCell

+ (CGSize)sizeForCell:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    CGFloat height = [super hightForHeaderArea:msgModel];
    NSString *infoText;
    if ([msgModel.message.content isKindOfClass:[WFCCNotificationMessageContent class]]) {
        WFCCNotificationMessageContent *content = (WFCCNotificationMessageContent *)msgModel.message.content;
        infoText = [content formatNotification:msgModel.message];
    } else {
        infoText = [msgModel.message digest];
    }
    CGSize size = [WFCUUtilities getTextDrawingSize:infoText font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(width - TEXT_LABEL_LEFT_PADDING - TEXT_LABEL_RIGHT_PADDING - TEXT_LEFT_PADDING - TEXT_RIGHT_PADDING, 8000)];
    size.height += TEXT_LABEL_TOP_PADDING + TEXT_LABEL_BUTTOM_PADDING + TEXT_TOP_PADDING + TEXT_BUTTOM_PADDING;
    size.height += height;
    return CGSizeMake(width, size.height);
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserverForName:kUserInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        WFCCUserInfo *userInfo = note.userInfo[@"userInfo"];
        BOOL needUpdate = false;
        if ([ws.model.message.content isKindOfClass:[WFCCAddGroupeMemberNotificationContent class]]) {
            WFCCAddGroupeMemberNotificationContent *cnt = (WFCCAddGroupeMemberNotificationContent *)ws.model.message.content;
            if ([cnt.invitor isEqualToString:userInfo.userId] || [cnt.invitees containsObject:userInfo.userId]) {
                needUpdate = true;
            }
        } else if ([ws.model.message.content isKindOfClass:[WFCCCreateGroupNotificationContent class]]) {
            WFCCCreateGroupNotificationContent *cnt = (WFCCCreateGroupNotificationContent *)ws.model.message.content;
            if ([cnt.creator isEqualToString:userInfo.userId]) {
                needUpdate = true;
            }
        }
        
        if (needUpdate) {
            [ws setModel:ws.model];
        }
    }];
    
    NSString *infoText;
    if ([model.message.content isKindOfClass:[WFCCNotificationMessageContent class]]) {
        WFCCNotificationMessageContent *content = (WFCCNotificationMessageContent *)model.message.content;
        infoText = [content formatNotification:model.message];
    } else {
        infoText = [model.message digest];
    }
    
    CGFloat width = self.contentView.bounds.size.width;
    
    CGSize size = [WFCUUtilities getTextDrawingSize:infoText font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(width - TEXT_LABEL_LEFT_PADDING - TEXT_LABEL_RIGHT_PADDING - TEXT_LEFT_PADDING - TEXT_RIGHT_PADDING, 8000)];
    
    
    self.infoLabel.text = infoText;
    self.infoLabel.layoutMargins = UIEdgeInsetsMake(TEXT_TOP_PADDING, TEXT_LEFT_PADDING, TEXT_BUTTOM_PADDING, TEXT_RIGHT_PADDING);
    CGFloat timeLableEnd = 0;
    if (!self.timeLabel.hidden) {
        timeLableEnd = self.timeLabel.frame.size.height + self.timeLabel.frame.origin.y;
    }
    self.infoLabel.frame = CGRectMake((width - size.width)/2 - 8, timeLableEnd + TEXT_LABEL_TOP_PADDING, size.width + 16, size.height + TEXT_TOP_PADDING + TEXT_BUTTOM_PADDING);
//    self.infoLabel.textAlignment = NSTextAlignmentCenter;

}

- (UILabel *)infoLabel {
    if (!_infoLabel) {
        _infoLabel = [[UILabel alloc] init];
        _infoLabel.numberOfLines = 0;
        _infoLabel.font = [UIFont systemFontOfSize:14];
        
        _infoLabel.textColor = [UIColor whiteColor];
        _infoLabel.numberOfLines = 0;
        _infoLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.font = [UIFont systemFontOfSize:14.f];
        _infoLabel.layer.masksToBounds = YES;
        _infoLabel.layer.cornerRadius = 5.f;
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.backgroundColor = [UIColor colorWithRed:201/255.f green:201/255.f blue:201/255.f alpha:1.f];
        
        [self.contentView addSubview:_infoLabel];
    }
    return _infoLabel; 
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
