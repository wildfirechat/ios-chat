//
//  WFCUUserMessageListViewController.m
//  WFChatUIKit
//
//  Created by dali on 2020/8/19.
//  Copyright © 2020 wildfirechat. All rights reserved.
//

#import "WFCUUserMessageListViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>

@interface WFCUUserMessageListViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSMutableArray<WFCCMessage *> *messages;

@property(nonatomic)bool isLoading;
@end

@implementation WFCUUserMessageListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.userId refresh:NO];
    
    if (userInfo.displayName.length) {
        self.title = [NSString stringWithFormat:@"%@ 的消息", userInfo.displayName];
    }
    
    self.messages = [[[WFCCIMService sharedWFCIMService] getUserMessages:self.userId conversation:self.conversation contentTypes:nil from:0 count:20] mutableCopy];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    
    [self.tableView reloadData];
}

- (void)loadMore {
    if (!self.messages.count) {
        return;
    }
    
    NSArray *moreMsg = [[WFCCIMService sharedWFCIMService] getUserMessages:self.userId conversation:self.conversation contentTypes:nil from:[self.messages lastObject].messageId count:20];
    [self.messages addObjectsFromArray:moreMsg];
    [self.tableView reloadData];
    self.isLoading = NO;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    WFCCMessage *msg = self.messages[indexPath.row];
    cell.textLabel.text = [msg.content digest:msg];
    cell.detailTextLabel.text = [WFCUUtilities formatTimeDetailLabel:msg.serverTime];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.bounds;
    CGSize size = scrollView.contentSize;
    UIEdgeInsets inset = scrollView.contentInset;
    CGFloat scrollViewHeight = bounds.size.height;
    CGFloat currentOffset = offset.y + scrollViewHeight - inset.bottom;
    CGFloat maximumOffset = size.height;
    
    CGFloat minSpace = 5;
    CGFloat maxSpace = 10;
    bool isNeedLoadMore = false;
    //上拉加载更多
    //tableview 的 content的高度 小于 tableview的高度
    if(scrollViewHeight < maximumOffset){
        CGFloat space = maximumOffset - currentOffset;
        if(space  < minSpace){
            isNeedLoadMore = true;
        }
    }
    
    if(!self.isLoading && isNeedLoadMore){
        self.isLoading = true;
        NSLog(@"-->加载更多数据");
        [self loadMore];
    }
}

@end
