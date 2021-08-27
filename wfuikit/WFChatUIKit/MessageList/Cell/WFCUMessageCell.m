//
//  MessageCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUMessageCell.h"
#import "WFCUUtilities.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "ZCCCircleProgressView.h"
#import "WFCUConfigManager.h"


#define Portrait_Size 40
#define SelectView_Size 20
#define Name_Label_Height  14
#define Name_Label_Padding  6
#define Name_Client_Padding  2
#define Portrait_Padding_Left 16
#define Portrait_Padding_Right 16
#define Portrait_Padding_Buttom 4

#define Client_Arad_Buttom_Padding 8

#define Client_Bubble_Top_Padding  6
#define Client_Bubble_Bottom_Padding  4

#define Bubble_Padding_Arraw 16
#define Bubble_Padding_Another_Side 8

#define MESSAGE_BASE_CELL_QUOTE_SIZE 14


@interface WFCUMessageCell ()
@property (nonatomic, strong)UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong)UIImageView *failureView;
@property (nonatomic, strong)UIImageView *maskView;

@property (nonatomic, strong)ZCCCircleProgressView *receiptView;

@property (nonatomic, strong)UIImageView *selectView;
@end

@implementation WFCUMessageCell
+ (CGFloat)clientAreaWidth {
  return [WFCUMessageCell bubbleWidth] - Bubble_Padding_Arraw - Bubble_Padding_Another_Side;
}

+ (CGFloat)bubbleWidth {
    return ([UIScreen mainScreen].bounds.size.width - Portrait_Size - Portrait_Padding_Left - Portrait_Padding_Right) * 0.7;
}

+ (CGSize)sizeForCell:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
  CGFloat height = [super hightForHeaderArea:msgModel];
  CGFloat portraitSize = Portrait_Size;
  CGFloat nameLabelHeight = Name_Label_Height + Name_Client_Padding;
  CGFloat clientAreaWidth = [self clientAreaWidth];
  
  CGSize clientArea = [self sizeForClientArea:msgModel withViewWidth:clientAreaWidth];
  CGFloat nameAndClientHeight = clientArea.height;
  if (msgModel.showNameLabel) {
    nameAndClientHeight += nameLabelHeight;
  }
    
    nameAndClientHeight += Client_Bubble_Top_Padding;
    nameAndClientHeight += Client_Bubble_Bottom_Padding;
    
  if (portraitSize + Portrait_Padding_Buttom > nameAndClientHeight) {
    height += portraitSize + Portrait_Padding_Buttom;
  } else {
    height += nameAndClientHeight;
  }
  height += Client_Arad_Buttom_Padding;   //buttom padding
    
  height += [self sizeForQuoteArea:msgModel withViewWidth:clientAreaWidth].height;
    
  return CGSizeMake(width, height);
}

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
  return CGSizeZero;
}

+ (CGSize)sizeForQuoteArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    if ([msgModel.message.content isKindOfClass:[WFCCTextMessageContent class]]) {
        WFCCTextMessageContent *txtContent = (WFCCTextMessageContent *)msgModel.message.content;
        if (txtContent.quoteInfo) {
            CGFloat quoteWidth = width - Portrait_Size - Portrait_Padding_Right - Portrait_Size - Portrait_Padding_Left - 8;
            NSString *quoteTxt = [NSString stringWithFormat:@"%@:%@", txtContent.quoteInfo.userDisplayName, txtContent.quoteInfo.messageDigest];
            CGSize size = [WFCUUtilities getTextDrawingSize:quoteTxt font:[UIFont systemFontOfSize:MESSAGE_BASE_CELL_QUOTE_SIZE] constrainedSize:CGSizeMake(quoteWidth, 44)];
            size.height += 12;
            size.width = width;
            return size;
        }
    }
    return CGSizeZero;
}

- (void)updateStatus {
    if (self.model.message.direction == MessageDirection_Send) {
        if (self.model.message.status == Message_Status_Sending) {
            CGRect frame = self.bubbleView.frame;
            frame.origin.x -= 24;
            frame.origin.y = frame.origin.y + frame.size.height - 24;
            frame.size.width = 20;
            frame.size.height = 20;
            self.activityIndicatorView.hidden = NO;
            self.activityIndicatorView.frame = frame;
            [self.activityIndicatorView startAnimating];
        } else {
            [_activityIndicatorView stopAnimating];
            _activityIndicatorView.hidden = YES;
            [self updateReceiptView];
        }
        
        if (self.model.message.status == Message_Status_Send_Failure) {
            CGRect frame = self.bubbleView.frame;
            frame.origin.x -= 24;
            frame.origin.y = frame.origin.y + frame.size.height - 24;
            frame.size.width = 20;
            frame.size.height = 20;
            self.failureView.frame = frame;
            self.failureView.hidden = NO;
        } else {
            _failureView.hidden = YES;
        }
    } else {
        [_activityIndicatorView stopAnimating];
        _activityIndicatorView.hidden = YES;
        _failureView.hidden = YES;
    }
}

-(void)onStatusChanged:(NSNotification *)notification {
    if(self.model.message.messageId == [notification.object longLongValue]) {
        WFCCMessageStatus newStatus = (WFCCMessageStatus)[[notification.userInfo objectForKey:@"status"] integerValue];
        self.model.message.status = newStatus;
        [self updateStatus];
    }
}
  
- (void)onUserInfoUpdated:(NSNotification *)notification {
  WFCCUserInfo *userInfo = notification.userInfo[@"userInfo"];
  if([userInfo.userId isEqualToString:self.model.message.fromUser]) {
      if (self.model.message.conversation.type == Group_Type) {
          userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userInfo.userId inGroup:self.model.message.conversation.target refresh:NO];
      }
    [self updateUserInfo:userInfo];
  }
}
  
- (void)updateUserInfo:(WFCCUserInfo *)userInfo {
  if([userInfo.userId isEqualToString:self.model.message.fromUser]) {
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
      if(self.model.showNameLabel) {
          NSString *nameStr = nil;
          if (userInfo.friendAlias.length) {
              nameStr = userInfo.friendAlias;
          } else if(userInfo.groupAlias.length) {
              if(userInfo.displayName.length > 0) {
                  nameStr = [userInfo.groupAlias stringByAppendingFormat:@"(%@)", userInfo.displayName];
              } else {
                  nameStr = userInfo.groupAlias;
              }
          } else if(userInfo.displayName.length > 0) {
              nameStr = userInfo.displayName;
          } else {
              nameStr = [NSString stringWithFormat:@"%@<%@>", WFCString(@"User"), self.model.message.fromUser];
          }
          self.nameLabel.text = nameStr;
      }
  }
}

- (void)setModel:(WFCUMessageModel *)model {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStatusChanged:) name:kSendingMessageStatusUpdated object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:
   model.message.fromUser];
  
  [super setModel:model];

  CGFloat selectViewOffset = model.selecting ? SelectView_Size + Portrait_Padding_Right : 0;
  if (model.message.direction == MessageDirection_Send) {
    CGFloat top = [WFCUMessageCellBase hightForHeaderArea:model];
    CGRect frame = self.frame;
    self.portraitView.frame = CGRectMake(frame.size.width - Portrait_Size - Portrait_Padding_Right - selectViewOffset, top, Portrait_Size, Portrait_Size);
    if (model.showNameLabel) {
      self.nameLabel.frame = CGRectMake(frame.size.width - Portrait_Size - Portrait_Padding_Right - Name_Label_Padding - 200 - selectViewOffset, top, 200, Name_Label_Height);
      self.nameLabel.hidden = NO;
      self.nameLabel.textAlignment = NSTextAlignmentRight;
    } else {
      self.nameLabel.hidden = YES;
    }

      
    CGSize size = [self.class sizeForClientArea:model withViewWidth:[WFCUMessageCell clientAreaWidth]];
      self.bubbleView.image = [UIImage imageNamed:@"sent_msg_background"];
      self.bubbleView.frame = CGRectMake(frame.size.width - Portrait_Size - Portrait_Padding_Right - Name_Label_Padding - size.width - Bubble_Padding_Arraw - Bubble_Padding_Another_Side - selectViewOffset, top + Name_Client_Padding, size.width + Bubble_Padding_Arraw + Bubble_Padding_Another_Side, size.height + Client_Bubble_Top_Padding + Client_Bubble_Bottom_Padding);
    self.contentArea.frame = CGRectMake(Bubble_Padding_Another_Side, Client_Bubble_Top_Padding, size.width, size.height);
      
      UIImage *image = self.bubbleView.image;
      self.bubbleView.image = [self.bubbleView.image
                                         resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height * 0.95, image.size.width * 0.2,image.size.height * 0.1, image.size.width * 0.05)];
      
      [self updateReceiptView];
  } else {
    CGFloat top = [WFCUMessageCellBase hightForHeaderArea:model];
    self.portraitView.frame = CGRectMake(Portrait_Padding_Left, top, Portrait_Size, Portrait_Size);
    if (model.showNameLabel) {
      self.nameLabel.frame = CGRectMake(Portrait_Padding_Left + Portrait_Size + Name_Label_Padding, top, 200, Name_Label_Height);
      self.nameLabel.hidden = NO;
      self.nameLabel.textAlignment = NSTextAlignmentLeft;
      top +=  Name_Label_Height + Name_Client_Padding;
    } else {
      self.nameLabel.hidden = YES;
    }
      
      
      
      NSString *bubbleImageName = @"received_msg_background";
      if (@available(iOS 13.0, *)) {
          if(UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
              bubbleImageName = @"chat_from_bg_normal_dark";
          }
      }
      
    CGSize size = [self.class sizeForClientArea:model withViewWidth:[WFCUMessageCell clientAreaWidth]];
      self.bubbleView.image = [UIImage imageNamed:bubbleImageName];
      self.bubbleView.frame = CGRectMake(Portrait_Padding_Left + Portrait_Size + Name_Label_Padding, top, size.width + Bubble_Padding_Arraw + Bubble_Padding_Another_Side, size.height + Client_Bubble_Top_Padding + Client_Bubble_Bottom_Padding);
    self.contentArea.frame = CGRectMake(Bubble_Padding_Arraw, Client_Bubble_Top_Padding, size.width, size.height);
      
      UIImage *image = self.bubbleView.image;
      CGFloat leftProtection = image.size.width * 0.8;
      CGFloat rightProtection = image.size.width * 0.2;

      if (self.bubbleView.frame.size.width < image.size.width) {
          leftProtection = 17;
          rightProtection = 12;
      }
      self.bubbleView.image = [self.bubbleView.image
                                         resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height * 0.8, leftProtection,
                                                                                      image.size.height * 0.2, rightProtection)];
      
      self.receiptView.hidden = YES;
  }
    
    if (model.selecting) {
        self.selectView.hidden = NO;
        if (model.selected) {
            self.selectView.image = [UIImage imageNamed:@"multi_selected"];
        } else {
            self.selectView.image = [UIImage imageNamed:@"multi_unselected"];
        }
        CGFloat top = [WFCUMessageCellBase hightForHeaderArea:model];
        CGRect frame = self.selectView.frame;
        frame.origin.y = top;
        self.selectView.frame = frame;
    } else {
        self.selectView.hidden = YES;
    }
    
    NSString *groupId = nil;
    if (self.model.message.conversation.type == Group_Type) {
        groupId = self.model.message.conversation.target;
    }
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:model.message.fromUser inGroup:groupId refresh:NO];
  if(userInfo.userId.length == 0) {
    userInfo = [[WFCCUserInfo alloc] init];
    userInfo.userId = model.message.fromUser;
  }
  
  [self updateUserInfo:userInfo];
  [self setMaskImage:self.bubbleView.image];
  [self updateStatus];
    
    if (model.highlighted) {
        UIColor *bkColor = self.backgroundColor;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.backgroundColor = [UIColor grayColor];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.backgroundColor = bkColor;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.backgroundColor = [UIColor grayColor];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        self.backgroundColor = bkColor;
                    });
                });
            });
        });
        model.highlighted = NO;
    }
    
    self.quoteContainer.hidden = YES;
    if ([model.message.content isKindOfClass:[WFCCTextMessageContent class]]) {
        WFCCTextMessageContent *txtContent = (WFCCTextMessageContent *)model.message.content;
        if (txtContent.quoteInfo) {
            if (!self.quoteLabel) {
                self.quoteLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                self.quoteLabel.font = [UIFont systemFontOfSize:MESSAGE_BASE_CELL_QUOTE_SIZE];
                self.quoteLabel.numberOfLines = 0;
                self.quoteLabel.layer.cornerRadius = 3.f;
                self.quoteLabel.layer.masksToBounds = YES;
                self.quoteLabel.userInteractionEnabled = YES;
                self.quoteLabel.textColor = [UIColor grayColor];
                [self.quoteLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onQuoteLabelTaped:)]];
                
                self.quoteContainer = [[UIView alloc] initWithFrame:CGRectZero];
                self.quoteContainer.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.f];
                self.quoteContainer.layer.cornerRadius = 3.f;
                self.quoteContainer.layer.masksToBounds = YES;
                [self.quoteContainer addSubview:self.quoteLabel];
                [self.contentView addSubview:self.quoteContainer];
            }
            CGSize size = [self.class sizeForQuoteArea:model withViewWidth:[WFCUMessageCell clientAreaWidth]];
            
            CGRect frame;
            if (model.message.direction == MessageDirection_Send) {
                frame = CGRectMake(self.frame.size.width - Portrait_Size - Portrait_Padding_Right - Name_Label_Padding - size.width - Bubble_Padding_Another_Side - selectViewOffset, self.bubbleView.frame.origin.y + self.bubbleView.frame.size.height + 4, size.width, size.height-4);
            } else {
                frame = CGRectMake(Portrait_Padding_Left + Portrait_Size + Name_Label_Padding + Bubble_Padding_Arraw, self.bubbleView.frame.origin.y + self.bubbleView.frame.size.height + 4, size.width, size.height-4);
            }
            self.quoteContainer.frame = frame;
            frame = self.quoteContainer.bounds;
            frame.size.height -= 8;
            frame.size.width -= 8;
            frame.origin.x += 4;
            frame.origin.y += 4;
            self.quoteLabel.frame = frame;
            
            self.quoteContainer.hidden = NO;
            self.quoteLabel.text = [NSString stringWithFormat:@"%@:%@", txtContent.quoteInfo.userDisplayName, txtContent.quoteInfo.messageDigest];
        }
    }
}

- (void)updateReceiptView {
    WFCUMessageModel *model = self.model;
    if (model.message.direction == MessageDirection_Send) {
        if([model.message.content.class getContentFlags] == WFCCPersistFlag_PERSIST_AND_COUNT && (model.message.status == Message_Status_Sent || model.message.status == Message_Status_Readed) && [[WFCCIMService sharedWFCIMService] isReceiptEnabled] && [[WFCCIMService sharedWFCIMService] isUserEnableReceipt] && ![model.message.content isKindOfClass:[WFCCCallStartMessageContent class]]) {
            if (model.message.conversation.type == Single_Type) {
                if (model.message.serverTime <= [[model.readDict objectForKey:model.message.conversation.target] longLongValue]) {
                    [self.receiptView setProgress:1 subProgress:1];
                } else if (model.message.serverTime <= [[model.deliveryDict objectForKey:model.message.conversation.target] longLongValue]) {
                    [self.receiptView setProgress:0 subProgress:1];
                } else {
                    [self.receiptView setProgress:0 subProgress:0];
                }
                if([model.message.conversation.target isEqualToString:[WFCUConfigManager globalManager].fileTransferId]) {
                    self.receiptView.hidden = YES;
                } else {
                    self.receiptView.hidden = NO;
                }
            } else if(model.message.conversation.type == Group_Type) {
                long long messageTS = model.message.serverTime;
                
                WFCCGroupInfo *groupInfo = nil;
                if (model.deliveryRate == -1) {
                    __block int delieveriedCount = 0;

                    [model.deliveryDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                        if ([obj longLongValue] >= messageTS) {
                            delieveriedCount++;
                        }
                    }];
                    groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:model.message.conversation.target refresh:NO];
                    model.deliveryRate = (float)delieveriedCount/(groupInfo.memberCount - 1);
                }
                if (model.readRate == -1) {
                    __block int readedCount = 0;

                    [model.readDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                        if ([obj longLongValue] >= messageTS) {
                            readedCount++;
                        }
                    }];
                    if (!groupInfo) {
                        groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:model.message.conversation.target refresh:NO];
                    }
                    
                    model.readRate = (float)readedCount/(groupInfo.memberCount - 1);
                }
              
                
                if (model.deliveryRate < model.readRate) {
                    model.deliveryRate = model.readRate;
                }
                
                [self.receiptView setProgress:model.readRate subProgress:model.deliveryRate];
                self.receiptView.hidden = NO;
            } else {
                self.receiptView.hidden = YES;
            }
        } else {
            self.receiptView.hidden = YES;
        }
        
        if (self.receiptView.hidden == NO) {
            self.receiptView.frame = CGRectMake(self.bubbleView.frame.origin.x - 16, self.frame.size.height - 24 , 14, 14);
        }
    }
}

- (void)onQuoteLabelTaped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didTapQuoteLabel:withModel:)]) {
        [self.delegate didTapQuoteLabel:self withModel:self.model];
    }
}
- (void)onTapReceiptView:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didTapReceiptView:withModel:)] && self.model.message.conversation.type == Group_Type) {
        [self.delegate didTapReceiptView:self withModel:self.model];
    }
}
- (void)setMaskImage:(UIImage *)maskImage{
    if (_maskView == nil) {
        _maskView = [[UIImageView alloc] initWithImage:maskImage];
        
        _maskView.frame = self.bubbleView.bounds;
        self.bubbleView.layer.mask = _maskView.layer;
        self.bubbleView.layer.masksToBounds = YES;
    } else {
        _maskView.image = maskImage;
        _maskView.frame = self.bubbleView.bounds;
    }
}

- (ZCCCircleProgressView *)receiptView {
    if (!_receiptView) {
        _receiptView = [[ZCCCircleProgressView alloc] initWithFrame:CGRectMake(0, 0, 14, 14)];
        _receiptView.hidden = YES;
        _receiptView.userInteractionEnabled = YES;
        [_receiptView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapReceiptView:)]];
        [self.contentView addSubview:_receiptView];
    }
    return _receiptView;
}

- (UIImageView *)portraitView {
  if (!_portraitView) {
    _portraitView = [[UIImageView alloc] init];
    _portraitView.clipsToBounds = YES;
    _portraitView.layer.cornerRadius = 3.f;
    [_portraitView setImage:[UIImage imageNamed:@"PersonalChat"]];
    
    [_portraitView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapPortrait:)]];
      [_portraitView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressPortrait:)]];
      
    _portraitView.userInteractionEnabled=YES;
    
    [self.contentView addSubview:_portraitView];
  }
  return _portraitView;
}

- (void)didTapPortrait:(id)sender {
  [self.delegate didTapMessagePortrait:self withModel:self.model];
}

- (void)didLongPressPortrait:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self.delegate didLongPressMessagePortrait:self withModel:self.model];
    }
}

- (UILabel *)nameLabel {
  if (!_nameLabel) {
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.font = [UIFont systemFontOfSize:Name_Label_Height-2];
    _nameLabel.textColor = [UIColor grayColor];
    [self.contentView addSubview:_nameLabel];
  }
  return _nameLabel;
}

- (UIView *)contentArea {
  if (!_contentArea) {
    _contentArea = [[UIView alloc] init];
    [self.bubbleView addSubview:_contentArea];
  }
  return _contentArea;
}
- (UIImageView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIImageView alloc] init];
        [self.contentView addSubview:_bubbleView];
        [_bubbleView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressed:)]];
        
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onDoubleTaped:)];
        doubleTapGesture.numberOfTapsRequired = 2;
        doubleTapGesture.numberOfTouchesRequired = 1;
        [_bubbleView addGestureRecognizer:doubleTapGesture];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTaped:)];
        [_bubbleView addGestureRecognizer:tap];
        [tap requireGestureRecognizerToFail:doubleTapGesture];
        tap.cancelsTouchesInView = NO;
        [_bubbleView setUserInteractionEnabled:YES];
    }
    return _bubbleView;
}
- (UIActivityIndicatorView *)activityIndicatorView {
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.contentView addSubview:_activityIndicatorView];
    }
    return _activityIndicatorView;
}
- (UIImageView *)failureView {
    if (!_failureView) {
        _failureView = [[UIImageView alloc] init];
        _failureView.image = [UIImage imageNamed:@"failure"];
        [_failureView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onResend:)]];
        [_failureView setUserInteractionEnabled:YES];
        [self.contentView addSubview:_failureView];
    }
    return _failureView;
}

- (UIImageView *)selectView {
    if(!_selectView) {
        CGFloat top = [WFCUMessageCellBase hightForHeaderArea:self.model];
        CGRect frame = self.frame;
        frame = CGRectMake(frame.size.width - SelectView_Size - Portrait_Padding_Right, top, SelectView_Size, SelectView_Size);
        
        _selectView = [[UIImageView alloc] initWithFrame:frame];
        _selectView.image = [UIImage imageNamed:@"multi_unselected"];
        UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSelect:)];
        [_selectView addGestureRecognizer:tap];
        _selectView.userInteractionEnabled = YES;
        [self.contentView addSubview:_selectView];
    }
    return _selectView;
}

- (void)onSelect:(id)sender {
    self.model.selected = !self.model.selected;
    if (self.model.selected) {
        self.selectView.image = [UIImage imageNamed:@"multi_selected"];
    } else {
        self.selectView.image = [UIImage imageNamed:@"multi_unselected"];
    }
}

- (void)onResend:(id)sender {
    [self.delegate didTapResendBtn:self.model];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
