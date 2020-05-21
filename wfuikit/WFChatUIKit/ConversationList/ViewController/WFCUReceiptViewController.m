//
//  WFCUReceiptViewController.m
//  WFChatUIKit
//
//  Created by heavyrain2012 on 2020/5/20.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUReceiptViewController.h"

@interface WFCUReceiptViewController ()
@property (nonatomic, strong)NSMutableDictionary<NSString *, NSNumber *> *deliveryDict;
@property (nonatomic, strong)NSMutableDictionary<NSString *, NSNumber *> *readDict;

@property (nonatomic, strong)NSMutableArray *deliveredUserIds;
@property (nonatomic, strong)NSMutableArray *unDeliveredUserIds;

@property (nonatomic, strong)NSMutableArray *readedUserIds;
@property (nonatomic, strong)NSMutableArray *unReadedUserIds;
@end

@implementation WFCUReceiptViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    if (self.message.conversation.type != Group_Type) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    self.deliveryDict = [[WFCCIMService sharedWFCIMService] getMessageDelivery:self.message.conversation];
    self.readDict = [[WFCCIMService sharedWFCIMService] getConversationRead:self.message.conversation];
    
    self.deliveredUserIds = [[NSMutableArray alloc] init];
    self.readedUserIds = [[NSMutableArray alloc] init];
    
    int64_t sendTime = self.message.serverTime;
    [self.deliveryDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj longLongValue] >= sendTime) {
            [self.deliveredUserIds addObject:key];
        }
    }];
    
    [self.readDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj longLongValue] >= sendTime) {
            [self.readedUserIds addObject:key];
        }
    }];
    
    self.unDeliveredUserIds = [[NSMutableArray alloc] init];
    self.unReadedUserIds = [[NSMutableArray alloc] init];
    
    NSArray<WFCCGroupMember *> *members = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.message.conversation.target forceUpdate:NO];
    for (WFCCGroupMember *member in members) {
        if (![self.deliveredUserIds containsObject:member.memberId]) {
            [self.unDeliveredUserIds addObject:member.memberId];
        }
        
        if (![self.readedUserIds containsObject:member.memberId]) {
            [self.unReadedUserIds addObject:member.memberId];
        }
    }
    [self.deliveredUserIds removeObject:self.message.fromUser];
    [self.unDeliveredUserIds removeObject:self.message.fromUser];
    [self.readedUserIds removeObject:self.message.fromUser];
    [self.unReadedUserIds removeObject:self.message.fromUser];
    
    UILabel *label = [[UILabel alloc] initWithFrame:self.view.bounds];
    label.numberOfLines = 0;
    label.text = [NSString stringWithFormat:@"%ld 成员已经收到消息， %ld 成员还未收到消息；%ld 成员已经阅读了消息，%ld 成员没有阅读消息", self.deliveredUserIds.count, self.unDeliveredUserIds.count, self.readedUserIds.count, self.unReadedUserIds.count];
    
    [self.view addSubview:label];
    
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
