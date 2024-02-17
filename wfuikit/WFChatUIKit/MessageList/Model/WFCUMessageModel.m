//
//  MessageModel.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUMessageModel.h"

@implementation WFCUMessageModel
+ (instancetype)modelOf:(WFCCMessage *)message showName:(BOOL)showName showTime:(BOOL)showTime {
  WFCUMessageModel *model = [[WFCUMessageModel alloc] init];
  model.message = message;
  model.showNameLabel = showName;
  model.showTimeLabel = showTime;
  [model loadQuotedMessage];
    
  return model;
}

- (void)loadQuotedMessage {
    if([self.message.content isKindOfClass:[WFCCTextMessageContent class]]) {
        WFCCTextMessageContent *txtCont = (WFCCTextMessageContent *)self.message.content;
        if(txtCont.quoteInfo) {
            self.quotedMessage = [[WFCCIMService sharedWFCIMService] getMessageByUid:txtCont.quoteInfo.messageUid];
            if(!self.quotedMessage) {
                [[WFCCIMService sharedWFCIMService] getRemoteMessage:txtCont.quoteInfo.messageUid success:^(WFCCMessage *message) {
                    self.quotedMessage = message;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:@(self.message.messageId)];
                } error:^(int error_code) {
                    
                }];
            }
        }
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.deliveryRate = -1;
        self.readRate = -1;
    }
    return self;
}
@end
