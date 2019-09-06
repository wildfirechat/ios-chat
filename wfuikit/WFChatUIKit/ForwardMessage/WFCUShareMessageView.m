//
//  ShareMessageView.m
//  TYAlertControllerDemo
//
//  Created by tanyang on 15/10/26.
//  Copyright © 2015年 tanyang. All rights reserved.
//

#import "WFCUShareMessageView.h"
#import "UIView+TYAlertView.h"
#import "UITextView+Placeholder.h"
#import "SDWebImage.h"

@interface WFCUShareMessageView ()
@property (weak, nonatomic) IBOutlet UIImageView *portraitImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *digestLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIView *digestBackgrouView;
@end

@implementation WFCUShareMessageView
- (void)updateUI {
    self.digestBackgrouView.clipsToBounds = YES;
    self.digestBackgrouView.layer.masksToBounds = YES;
    self.digestBackgrouView.layer.cornerRadius = 8.f;
    self.messageTextView.placeholder = @"给朋友留言";
    self.messageTextView.layer.masksToBounds = YES;
    self.messageTextView.layer.cornerRadius = 8.f;
    self.messageTextView.contentInset = UIEdgeInsetsMake(2, 8, 2, 2);
    self.messageTextView.layer.borderWidth = 0.5f;
    self.messageTextView.layer.borderColor = [[UIColor greenColor] CGColor];
}

- (IBAction)sendAction:(id)sender {
    [self hideView];
    WFCCTextMessageContent *textMsg;
    if (self.messageTextView.text.length) {
        textMsg = [[WFCCTextMessageContent alloc] init];
        textMsg.text = self.messageTextView.text;
    }
    
    __strong WFCCConversation *conversation = self.conversation;
    __strong void (^forwardDone)(BOOL success) = self.forwardDone;
    
    [[WFCCIMService sharedWFCIMService] send:conversation content:self.message.content success:^(long long messageUid, long long timestamp) {
        if (textMsg) {
            [[WFCCIMService sharedWFCIMService] send:conversation content:textMsg success:^(long long messageUid, long long timestamp) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (forwardDone) {
                        forwardDone(YES);
                    }
                });
            } error:^(int error_code) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (forwardDone) {
                        forwardDone(NO);
                    }
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (forwardDone) {
                    forwardDone(YES);
                }
            });
        }
    } error:^(int error_code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (forwardDone) {
                forwardDone(NO);
            }
        });
    }];
}

- (IBAction)cancelAction:(id)sender {
    [self hideView];
}

- (void)setConversation:(WFCCConversation *)conversation {
    [self updateUI];
    _conversation = conversation;
    NSString *name;
    NSString *portrait;
    
    if (conversation.type == Single_Type) {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:conversation.target refresh:NO];
        if (userInfo) {
            name = userInfo.displayName;
            portrait = userInfo.portrait;
        } else {
            name = [NSString stringWithFormat:@"用户<%@>", conversation.target];
        }
        [self.portraitImageView sd_setImageWithURL:[NSURL URLWithString:portrait] placeholderImage:[UIImage wf_imageNamed:@"PersonalChat"]];
    } else if (conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:conversation.target refresh:NO];
        if (groupInfo) {
            name = groupInfo.name;
            portrait = groupInfo.portrait;
        } else {
            name = [NSString stringWithFormat:@"群组<%@>", conversation.target];
        }
        [self.portraitImageView sd_setImageWithURL:[NSURL URLWithString:portrait] placeholderImage:[UIImage wf_imageNamed:@"group_default_portrait"]];
    } else if (conversation.type == Channel_Type) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:conversation.target refresh:NO];
        if (channelInfo) {
            name = channelInfo.name;
            portrait = channelInfo.portrait;
        } else {
            name = [NSString stringWithFormat:@"群组<%@>", conversation.target];
        }
        [self.portraitImageView sd_setImageWithURL:[NSURL URLWithString:portrait] placeholderImage:[UIImage wf_imageNamed:@"channel_default_portrait"]];
    }
    
    self.nameLabel.text = name;
}

- (void)setMessage:(WFCCMessage *)message {
    _message = message;
    self.digestLabel.text = [message.content digest:message];
}
@end
