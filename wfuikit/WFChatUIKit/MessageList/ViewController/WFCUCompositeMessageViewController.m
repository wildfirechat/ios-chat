//
//  WFCUCompositeMessageViewController.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUCompositeMessageViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"
#import "WFCUCompositeBaseCell.h"
#import "WFCUCompositeTextCell.h"

@interface WFCUCompositeMessageViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSMutableArray<WFCCMessage *> *messages;
@end

@implementation WFCUCompositeMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.messages = [[NSMutableArray alloc] initWithArray:self.compositeContent.messages];
    
    [self setupTableHeaderView];
    
    self.title = self.compositeContent.title;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
}
- (void)setupTableHeaderView {
#define HEADER_HEIGHT 30
#define HEADER_FONT_SIZE 16
#define HEADER_LINE_PADDING 16
    NSDate *from = [[NSDate alloc] initWithTimeIntervalSince1970:self.messages.firstObject.serverTime/1000];
    NSDate *to = [[NSDate alloc] initWithTimeIntervalSince1970:self.messages.lastObject.serverTime/1000];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    
    NSString *fromString = [dateFormatter stringFromDate:from];
    NSString *toString = [dateFormatter stringFromDate:to];
    
    CGFloat width = self.view.frame.size.width;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, HEADER_HEIGHT)];
    NSString *timeString;
    if ([fromString isEqualToString:toString]) {
        timeString = fromString;
    } else {
        timeString = [NSString stringWithFormat:@"%@ 至 %@", fromString, toString];
    }
    CGSize size = [WFCUUtilities getTextDrawingSize:timeString font:[UIFont systemFontOfSize:HEADER_FONT_SIZE] constrainedSize:CGSizeMake(width, HEADER_HEIGHT)];
    
    UIView *leftLine = [[UIView alloc] initWithFrame:CGRectMake(HEADER_LINE_PADDING, HEADER_HEIGHT/2, (width-size.width)/2-HEADER_LINE_PADDING-HEADER_LINE_PADDING, 1)];
    leftLine.backgroundColor = [UIColor grayColor];
    [headerView addSubview:leftLine];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((width-size.width)/2, (HEADER_HEIGHT-size.height)/2, size.width, size.height)];
    label.text = timeString;
    label.textColor = [UIColor grayColor];
    label.font = [UIFont systemFontOfSize:HEADER_FONT_SIZE];
    [headerView addSubview:label];
    
    UIView *rightLine = [[UIView alloc] initWithFrame:CGRectMake((width+size.width)/2+HEADER_LINE_PADDING, HEADER_HEIGHT/2, (width-size.width)/2-HEADER_LINE_PADDING-HEADER_LINE_PADDING, 1)];
    rightLine.backgroundColor = [UIColor grayColor];
    [headerView addSubview:rightLine];
    
    self.tableView.tableHeaderView = headerView;
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.compositeContent.messages.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCMessage *msg = self.messages[indexPath.row];
    WFCUCompositeBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([msg.content class])];
    if (!cell) {
        cell = [WFCUCompositeBaseCell cellOfMessage:msg];
    }
    
    if (indexPath.row == self.messages.count-1) {
        cell.lastMessage = YES;
    } else {
        cell.lastMessage = NO;
    }
    
    BOOL sameUser = NO;
    if (indexPath.row != 0) {
        WFCCMessage *premsg = self.messages[indexPath.row-1];
        if ([premsg.fromUser isEqualToString:msg.fromUser]) {
            sameUser = YES;
        }
    }
    cell.hiddenPortrait = sameUser;
    
    cell.message = msg;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCMessage *msg = self.messages[indexPath.row];
    WFCUCompositeBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([msg.content class])];
    if (!cell) {
        cell = [WFCUCompositeBaseCell cellOfMessage:msg];
    }
    
    return [cell.class heightForMessage:msg];
}
@end
