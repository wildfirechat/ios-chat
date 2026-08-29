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
        //按页面自己的宽度算格子，不是屏幕宽：iPad 双栏下这张页面在右栏里，
        //按整屏宽算出来的两列会溢出栏外。iPhone 上取值没变。
        CGFloat width = [WFCUPadUtility layoutWidthForView:self.view];
        width = (width - edgeInset)/countInLine - edgeInset;
        flowLayout.itemSize = CGSizeMake(width, width + 20);

        _collectionView = [[UICollectionView alloc]initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_collectionView registerClass:[ChatroomItemCell class] forCellWithReuseIdentifier:identifier];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView setBackgroundColor:[WFCUConfigManager globalManager].backgroudColor];
    }
    return _collectionView;
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    //栏宽会变（旋转、Stage Manager），格子跟着重算一次
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    if (![flowLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        return;
    }
    CGFloat edgeInset = flowLayout.sectionInset.left;
    CGFloat width = self.collectionView.bounds.size.width;
    if (width <= 0) {
        return;
    }
    width = (width - edgeInset)/2 - edgeInset;
    if (ABS(flowLayout.itemSize.width - width) > 0.5) {
        flowLayout.itemSize = CGSizeMake(width, width + 20);
        [flowLayout invalidateLayout];
    }
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
