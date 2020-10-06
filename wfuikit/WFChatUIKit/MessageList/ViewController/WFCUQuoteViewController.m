//
//  WFCUQuoteViewController.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUQuoteViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDPhotoBrowser.h"


@interface WFCUQuoteViewController ()
@end

@implementation WFCUQuoteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    WFCCMessage *msg = [[WFCCIMService sharedWFCIMService] getMessageByUid:self.messageUid];
    if (!msg) {
        //Todo msg not exist, should go back
        NSLog(@"msg not exist");
        return;
    }
    self.view.backgroundColor = [UIColor whiteColor];
    
    //Todo display message content
    if ([msg.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        
    } else if ([msg.content isKindOfClass:[WFCCSoundMessageContent class]]) {
        
    } else if ([msg.content isKindOfClass:[WFCCStickerMessageContent class]]) {
        
    } else {
        
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
