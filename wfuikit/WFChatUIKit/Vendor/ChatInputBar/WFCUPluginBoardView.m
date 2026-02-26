//
//  PluginBoardView.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUPluginBoardView.h"
#import "WFCUPluginItemView.h"
#import "WFCUConfigManager.h"
#import "WFCUImage.h"

#define PLUGIN_AREA_HEIGHT 211
#define PLUGIN_PAGE_CONTROL_HEIGHT 20

#define LeftOffset ([UIScreen mainScreen].bounds.size.width-75*4)/5.0
#define RCPlaginBoardCellSize ((CGSize){ 75, 80 })
#define HorizontalItemsCount 4
#define VerticalItemsCount 2
#define ItemsPerPage (HorizontalItemsCount * VerticalItemsCount)

@interface PluginItem : NSObject
@property(nonatomic, strong)UIImage *image;
@property(nonatomic, strong)NSString *title;
@property(nonatomic, assign)NSUInteger tag;
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image tag:(NSUInteger)tag;
@end


@implementation PluginItem
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image tag:(NSUInteger)tag {
    self = [super init];
    if (self) {
        self.title = title;
        self.image = image;
        self.tag = tag;
    }
    return self;
}
@end



@interface WFCUPluginBoardView() <UIScrollViewDelegate>
@property (nonatomic, strong)NSMutableArray *pluginItems;
@property (nonatomic, weak)id<WFCUPluginBoardViewDelegate> delegate;
@property (nonatomic, assign)BOOL hasVoip;
@property (nonatomic, assign)BOOL hasPtt;
@property (nonatomic, assign)BOOL hasCollection;
@property (nonatomic, assign)BOOL hasPoll;
@property (nonatomic, strong)UIScrollView *scrollView;
@property (nonatomic, strong)UIPageControl *pageControl;
@end

@implementation WFCUPluginBoardView
- (instancetype)initWithDelegate:(id<WFCUPluginBoardViewDelegate>)delegate withVoip:(BOOL)withWoip withPtt:(BOOL)withPtt withPoll:(BOOL) withPoll withCollection:(BOOL)withCollection {
    CGFloat width = [UIScreen mainScreen].bounds.size.width-16;
    self = [super initWithFrame:CGRectMake(0, 0, width, PLUGIN_AREA_HEIGHT)];
    if (self) {
        self.delegate = delegate;
        self.hasVoip = withWoip;
        self.hasPtt = withPtt;
        self.hasCollection = withCollection;
        self.hasPoll = withPoll;
        self.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        
        [self setupScrollView];
        [self setupPageControl];
        [self setupPluginItems];
    }

    return self;
}

- (void)setupScrollView {
    CGFloat scrollViewHeight = PLUGIN_AREA_HEIGHT - PLUGIN_PAGE_CONTROL_HEIGHT;
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, scrollViewHeight)];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    [self addSubview:self.scrollView];
}

- (void)setupPageControl {
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, PLUGIN_AREA_HEIGHT - PLUGIN_PAGE_CONTROL_HEIGHT, self.frame.size.width, PLUGIN_PAGE_CONTROL_HEIGHT)];
    self.pageControl.currentPageIndicatorTintColor = [UIColor grayColor];
    self.pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    self.pageControl.hidesForSinglePage = YES;
    [self addSubview:self.pageControl];
}

- (void)setupPluginItems {
    int totalItems = (int)self.pluginItems.count;
    int pageCount = (totalItems + ItemsPerPage - 1) / ItemsPerPage;
    
    self.pageControl.numberOfPages = pageCount;
    self.scrollView.contentSize = CGSizeMake(self.frame.size.width * pageCount, self.scrollView.frame.size.height);
    
    __weak typeof(self)ws = self;
    
    for (int i = 0; i < totalItems; i++) {
        int pageIndex = i / ItemsPerPage;
        int indexInPage = i % ItemsPerPage;
        
        NSInteger currentRow = indexInPage / HorizontalItemsCount;
        NSInteger currentColumn = indexInPage % HorizontalItemsCount;
        
        CGFloat pageOffsetX = pageIndex * self.frame.size.width;
        
        CGRect frame;
        frame.size.width = RCPlaginBoardCellSize.width;
        frame.size.height = RCPlaginBoardCellSize.height;
        frame.origin.x = pageOffsetX + RCPlaginBoardCellSize.width * currentColumn + LeftOffset * (currentColumn + 1);
        frame.origin.y = RCPlaginBoardCellSize.height * currentRow + 15 + currentRow * 18;
        
        PluginItem *pluginItem = self.pluginItems[i];
        
        WFCUPluginItemView *item = [[WFCUPluginItemView alloc] initWithTitle:pluginItem.title image:pluginItem.image frame:frame];
        item.tag = pluginItem.tag;
        NSUInteger tag = item.tag;
        item.onItemClicked = ^(void) {
            NSLog(@"on item %lu pressed", tag);
            [ws.delegate onItemClicked:tag];
        };
        [self.scrollView addSubview:item];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = (int)(scrollView.contentOffset.x / pageWidth + 0.5);
    self.pageControl.currentPage = page;
}

- (NSMutableArray *)pluginItems {
    if (!_pluginItems) {
        _pluginItems = [@[
                          [[PluginItem alloc] initWithTitle:WFCString(@"Album") image:[WFCUImage imageNamed:@"chat_input_plugin_album"] tag:1],
                          [[PluginItem alloc] initWithTitle:WFCString(@"TakePhoto") image:[WFCUImage imageNamed:@"chat_input_plugin_camera"] tag:2],
                          [[PluginItem alloc] initWithTitle:WFCString(@"Location") image:[WFCUImage imageNamed:@"chat_input_plugin_location"] tag:3],
                          [[PluginItem alloc] initWithTitle:WFCString(@"Files") image:[WFCUImage imageNamed:@"chat_input_plugin_file"] tag:5],
                          [[PluginItem alloc] initWithTitle:WFCString(@"Card") image:[WFCUImage imageNamed:@"chat_input_plugin_card"] tag:6],
                          [[PluginItem alloc] initWithTitle:WFCString(@"Pan") image:[WFCUImage imageNamed:@"chat_input_plugin_file"] tag:10]
                          ] mutableCopy];

#if WFCU_SUPPORT_VOIP
        if (self.hasVoip) {
            [_pluginItems insertObject:[[PluginItem alloc] initWithTitle:WFCString(@"VideoCall") image:[WFCUImage imageNamed:@"chat_input_plugin_video_call"] tag:4] atIndex:2];
        }
#endif
#ifdef WFC_PTT
        if(self.hasPtt) {
            [_pluginItems addObject:[[PluginItem alloc] initWithTitle:WFCString(@"Talk") image:[WFCUImage imageNamed:@"chat_input_plugin_intercom"] tag:7]];
        }
#endif
        if(self.hasCollection) {
            [_pluginItems insertObject:[[PluginItem alloc] initWithTitle:WFCString(@"Collection") image:[WFCUImage imageNamed:@"chat_input_plugin_collection"] tag:8] atIndex:_pluginItems.count];
        }
        if(self.hasPoll) {
            [_pluginItems insertObject:[[PluginItem alloc] initWithTitle:WFCString(@"Poll") image:[WFCUImage imageNamed:@"chat_input_plugin_poll"] tag:9] atIndex:_pluginItems.count];
        }
    }
    return _pluginItems;
}
@end
