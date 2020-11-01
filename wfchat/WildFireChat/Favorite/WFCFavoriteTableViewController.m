//
//  FavoriteTableViewController.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/11/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCFavoriteTableViewController.h"
#import <WFChatUIKit/WFChatUIKit.h>
#import "AppService.h"
#import "WFCFavoriteBaseCell.h"
#import "WFCFavoriteTextCell.h"
#import "WFCFavoriteUnknownCell.h"
#import "WFCFavoriteImageCell.h"

@interface WFCFavoriteTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong)UITableView *tableView;

@property(nonatomic, strong)NSMutableArray<WFCUFavoriteItem *> *items;
@property(nonatomic, assign)BOOL hasMore;
@property(nonatomic, assign)BOOL loading;
@end

@implementation WFCFavoriteTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    self.items = [[NSMutableArray alloc] init];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadMoreData];
}
- (void)loadMoreData {
    if (!self.loading) {
        self.loading = YES;
    } else {
        return;
    }
    
    __weak typeof(self)ws = self;
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 20)];
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] init];
    activityView.center = CGPointMake(self.view.bounds.size.width/2, 10);
    [activityView startAnimating];
    [footer addSubview:activityView];
    self.tableView.tableFooterView =footer;
    
    [[AppService sharedAppService] getFavoriteItems:self.items.count ? [self.items lastObject].favId:0 count:100 success:^(NSArray<WFCUFavoriteItem *> * _Nonnull items, BOOL hasMore) {
        [ws.items addObjectsFromArray:items];
        [ws.tableView reloadData];
        ws.hasMore = hasMore;
        ws.tableView.tableFooterView = nil;
        ws.loading = NO;
    } error:^(int error_code) {
        ws.tableView.tableFooterView = nil;
        ws.loading = NO;
        ws.hasMore = NO;
    }];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (self.hasMore && ceil(targetContentOffset->y)+1 >= ceil(scrollView.contentSize.height - scrollView.bounds.size.height)) {
        [self loadMoreData];
    }
}

- (WFCFavoriteBaseCell *)cellOfFavType:(int)favType tableView:(UITableView *)tableView {
    WFCFavoriteBaseCell *cell = nil;
    if (favType == MESSAGE_CONTENT_TYPE_TEXT) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"text"];
        if (!cell) {
            cell = [[WFCFavoriteTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"text"];
        }
    } else if(favType == MESSAGE_CONTENT_TYPE_IMAGE) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"image"];
        if (!cell) {
            cell = [[WFCFavoriteImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"image"];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"unknown"];
        if (!cell) {
            cell = [[WFCFavoriteUnknownCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"unknown"];
        }
    }
    
    return cell;
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUFavoriteItem *favItem = self.items[indexPath.row];
    
    WFCFavoriteBaseCell *cell = [self cellOfFavType:favItem.favType tableView:tableView];
    cell.favoriteItem = favItem;
    
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}
#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUFavoriteItem *favItem = self.items[indexPath.row];
    return [[[self cellOfFavType:favItem.favType tableView:tableView] class] heightOf:favItem];
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WFCUFavoriteItem *favItem = self.items[indexPath.row];
        [[AppService sharedAppService] removeFavoriteItem:favItem.favId success:^{
            
        } error:^(int error_code) {
            
        }];
        
        [self.items removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}
@end
