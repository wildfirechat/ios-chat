//
//  WFCUReceiptViewController.m
//  WFChatUIKit
//
//  Created by heavyrain2012 on 2020/5/20.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUReceiptViewController.h"
#import "WFCUReadViewController.h"
#import "XLPageViewController.h"
#import "CommonTableViewController.h"
#import "WFCUUtilities.h"

@interface WFCUReceiptViewController () <XLPageViewControllerDelegate, XLPageViewControllerDataSrouce>
@property (nonatomic, strong)NSMutableDictionary<NSString *, NSNumber *> *readDict;
@property (nonatomic, strong)NSMutableArray *readedUserIds;
@property (nonatomic, strong)NSMutableArray *unReadedUserIds;
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) XLPageViewController *pageViewController;
@end

@implementation WFCUReceiptViewController

- (void)viewDidLoad {
    self.view.backgroundColor = [UIColor whiteColor];
    if (self.message.conversation.type != Group_Type) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"消息阅读状态";
    

    self.view.backgroundColor = [UIColor whiteColor];
    //配置
    XLPageViewControllerConfig *config = [XLPageViewControllerConfig defaultConfig];
//    config.showTitleInNavigationBar = true;
    config.titleViewStyle = XLPageTitleViewStyleSegmented;
    config.separatorLineHidden = true;
    //设置缩进
    config.titleViewInset = UIEdgeInsetsMake(5, 50, 5, 50);
    
    self.pageViewController = [[XLPageViewController alloc] initWithConfig:config];
    CGRect bounds = self.view.bounds;
    bounds.origin.y = [WFCUUtilities wf_navigationFullHeight];
    bounds.size.height -= ([WFCUUtilities wf_navigationFullHeight] + [WFCUUtilities wf_safeDistanceBottom]);
    self.pageViewController.view.frame = bounds;
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    


    self.readDict = [[WFCCIMService sharedWFCIMService] getConversationRead:self.message.conversation];
    self.readedUserIds = [[NSMutableArray alloc] init];

    int64_t sendTime = self.message.serverTime;
    [self.readDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj longLongValue] >= sendTime) {
            [self.readedUserIds addObject:key];
        }
    }];

    self.unReadedUserIds = [[NSMutableArray alloc] init];

    NSArray<WFCCGroupMember *> *members = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.message.conversation.target forceUpdate:NO];
    for (WFCCGroupMember *member in members) {
        if (![self.readedUserIds containsObject:member.memberId]) {
            [self.unReadedUserIds addObject:member.memberId];
        }
    }

    [self.readedUserIds removeObject:self.message.fromUser];
    [self.unReadedUserIds removeObject:self.message.fromUser];
    
    self.titles = @[[NSString stringWithFormat:@"已读(%ld)", self.readedUserIds.count], [NSString stringWithFormat:@"未读(%ld)", self.unReadedUserIds.count]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark TableViewDelegate&DataSource
- (UIViewController *)pageViewController:(XLPageViewController *)pageViewController viewControllerForIndex:(NSInteger)index {
    WFCUReadViewController *vc = [[WFCUReadViewController alloc] init];
    if(index == 0) {
        vc.userIds = self.readedUserIds;
    } else {
        vc.userIds = self.unReadedUserIds;
    }
    return vc;
}

- (NSString *)pageViewController:(XLPageViewController *)pageViewController titleForIndex:(NSInteger)index {
    return self.titles[index];
}

- (NSInteger)pageViewControllerNumberOfPage {
    return self.titles.count;
}

- (void)pageViewController:(XLPageViewController *)pageViewController didSelectedAtIndex:(NSInteger)index {
    
}

@end
