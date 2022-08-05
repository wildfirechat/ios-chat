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
#import <CommonCrypto/CommonCrypto.h>
#import "MBProgressHUD.h"


@interface WFCUCompositeMessageViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSMutableArray<WFCCMessage *> *messages;
@property (nonatomic, strong)WFCCCompositeMessageContent *compositeContent;
@end

@implementation WFCUCompositeMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.messages = [[NSMutableArray alloc] initWithArray:self.compositeContent.messages];
    
    [self setupTableHeaderView];
    
    self.title = self.compositeContent.title;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    
    if (!self.compositeContent.loaded && self.compositeContent.remoteUrl) {
        [self downloadComositeContent];
    }
}
- (void)downloadComositeContent {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"加载中...";
    [hud showAnimated:YES];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.compositeContent.remoteUrl]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            if(data.length) {
                NSString *uuid = nil;
                if (self.message.messageId > 0) {
                    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
                    uuid = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
                    CFRelease(uuidObject);
                } else {
                    uuid = [self getMD5WithData:data];
                }
                NSString *path = [[WFCCUtilities getDocumentPathWithComponent:@"/COMPOSITE_MESSAGE"] stringByAppendingPathComponent:uuid];
                if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    [data writeToFile:path atomically:YES];
                }
                
                WFCCCompositeMessageContent *content = self.compositeContent;
                content.localPath = path;
                self.message.content = content;
                if (self.message.messageId > 0) {
                    [[WFCCIMService sharedWFCIMService] updateMessage:self.message.messageId content:content];
                }
                self.messages = [[NSMutableArray alloc] initWithArray:self.compositeContent.messages];
                [self.tableView reloadData];
            } else {
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = @"加载失败";
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
            }
        });
    });
}
- (NSString *)getMD5WithData:(NSData *)data {
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    CC_MD5_Update(&md5, data.bytes, (uint32_t)data.length);
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(result, &md5);
    NSMutableString *resultString = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
      [resultString appendFormat:@"%02x", result[i]];
    }
    return resultString;
}

- (WFCCCompositeMessageContent *)compositeContent {
    return (WFCCCompositeMessageContent *)self.message.content;
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
    return self.messages.count;
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
