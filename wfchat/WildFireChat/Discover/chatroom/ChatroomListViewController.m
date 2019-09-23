//
//  ChatroomListViewController.m
//  WildFireChat
//
//  Created by heavyrain lee on 2018/8/24.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "ChatroomListViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "ChatroomItemCell.h"
#import <WFChatUIKit/WFChatUIKit.h>

@interface ChatroomListViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView * collectionView;
@property (nonatomic, strong) NSArray<NSString *> *chatroomIds;
@property (nonatomic, strong) NSMutableArray<WFCCChatroomInfo *> *chatroomInfos;
@end

static NSString * identifier = @"cxCellID";

@implementation ChatroomListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.collectionView];
    self.chatroomIds = @[@"chatroom1", @"chatroom2", @"chatroom3"];
    self.chatroomInfos = [[NSMutableArray alloc] init];
    for (NSString *chatroomId in self.chatroomIds) {
        WFCCChatroomInfo *info = [[WFCCChatroomInfo alloc] init];
        info.chatroomId = chatroomId;
        [self.chatroomInfos addObject:info];
        
        [[WFCCIMService sharedWFCIMService] getChatroomInfo:chatroomId upateDt:0 success:^(WFCCChatroomInfo *chatroomInfo) {
            [self updateChatroomInfo:chatroomInfo];
        } error:^(int error_code) {
            
        }];
    }
}

- (void)updateChatroomInfo:(WFCCChatroomInfo *)info {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (WFCCChatroomInfo *crInfo in self.chatroomInfos) {
            if ([crInfo.chatroomId isEqualToString:info.chatroomId]) {
                NSUInteger index = [self.chatroomInfos indexOfObject:crInfo];
                [self.chatroomInfos removeObjectAtIndex:index];
                [self.chatroomInfos insertObject:info atIndex:index];
                [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]];
                break;
            }
        }
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - set_and_get
-(UICollectionView *)collectionView{
    if (!_collectionView) {
        //自动网格布局
        UICollectionViewFlowLayout * flowLayout = [[UICollectionViewFlowLayout alloc]init];
        CGFloat edgeInset = 10;
        int countInLine = 2;
        flowLayout.sectionInset = UIEdgeInsetsMake(edgeInset, edgeInset, edgeInset, edgeInset);
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        width = (width - edgeInset)/countInLine - edgeInset;
        flowLayout.itemSize = CGSizeMake(width, width + 20);

        _collectionView = [[UICollectionView alloc]initWithFrame:self.view.frame collectionViewLayout:flowLayout];
        [_collectionView registerClass:[ChatroomItemCell class] forCellWithReuseIdentifier:identifier];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView setBackgroundColor:[WFCUConfigManager globalManager].backgroudColor];
    }
    return _collectionView;
    
}

#pragma mark - deleDate
//每个分组里有多少个item
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.chatroomInfos.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ChatroomItemCell * cell = (ChatroomItemCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    cell.chatroomInfo = [self.chatroomInfos objectAtIndex:indexPath.row];
    
    return cell;
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    WFCCChatroomInfo *chatroomInfo = [self.chatroomInfos objectAtIndex:indexPath.row];
    WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
    mvc.conversation = [WFCCConversation conversationWithType:Chatroom_Type target:chatroomInfo.chatroomId line:0];
    [self.navigationController pushViewController:mvc animated:YES];
}

@end
