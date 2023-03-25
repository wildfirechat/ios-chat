//
//  XLPageSegmentedTitleView.m
//  XLPageViewControllerExample
//
//  Created by MengXianLiang on 2019/5/9.
//  Copyright © 2019 xianliang meng. All rights reserved.
//  https://github.com/mengxianliang/XLPageViewController

#import "XLPageSegmentedTitleView.h"
#import "XLPageViewControllerUtil.h"

@interface XLPageSegmentedTitleView ()

@property (nonatomic, strong) UISegmentedControl *segmentedControl;

//配置信息
@property (nonatomic, strong) XLPageViewControllerConfig *config;

//底部分割线
@property (nonatomic, strong) UIView *separatorLine;

//判断是否已经加载了数据
@property (nonatomic, assign) BOOL haveLoadedDataSource;

@end

@implementation XLPageSegmentedTitleView

//初始化方法
- (instancetype)initWithConfig:(XLPageViewControllerConfig *)config {
    if (self = [super init]) {
        [self initSegmentedWithConfig:config];
    }
    return self;
}

//初始化方法
- (void)initSegmentedWithConfig:(XLPageViewControllerConfig *)config {
    
    self.config = config;
    
    self.segmentedControl = [[UISegmentedControl alloc] init];
    [self.segmentedControl addTarget:self action:@selector(segmentValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.segmentedControl.tintColor = config.segmentedTintColor;
    [self addSubview:self.segmentedControl];
    
    self.separatorLine = [[UIView alloc] init];
    self.separatorLine.backgroundColor = config.separatorLineColor;
    self.separatorLine.hidden = config.separatorLineHidden;
    [self addSubview:self.separatorLine];
}

//自动布局
- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat segmentH = self.bounds.size.height - self.config.titleViewInset.top - self.config.titleViewInset.bottom;
    CGFloat segmentW = self.bounds.size.width - self.config.titleViewInset.left - self.config.titleViewInset.right;
    
    self.segmentedControl.frame = CGRectMake(self.config.titleViewInset.left, self.config.titleViewInset.top, segmentW, segmentH);
    
    self.separatorLine.frame = CGRectMake(0, self.bounds.size.height - self.config.separatorLineHeight, self.bounds.size.width, self.config.separatorLineHeight);
    
    //加载数据源
    if (!self.haveLoadedDataSource) {
        [self loadDataSource];
    }
}

//加载分段选择器数据源
- (void)loadDataSource {
    self.haveLoadedDataSource = true;
    for (NSInteger i = 0; i < [self.dataSource pageTitleViewNumberOfTitle]; i++) {
        NSString *title = [self.dataSource pageTitleViewTitleForIndex:i];
        [self.segmentedControl insertSegmentWithTitle:title atIndex:self.segmentedControl.numberOfSegments animated:false];
    }
    self.segmentedControl.selectedSegmentIndex = self.selectedIndex;
}

//刷新方法
- (void)reloadData {
    [self.segmentedControl removeAllSegments];
    for (NSInteger i = 0; i < [self.dataSource pageTitleViewNumberOfTitle]; i++) {
        NSString *title = [self.dataSource pageTitleViewTitleForIndex:i];
        [self.segmentedControl insertSegmentWithTitle:title atIndex:self.segmentedControl.numberOfSegments animated:false];
    }
    self.segmentedControl.selectedSegmentIndex = self.selectedIndex;
}

//切换方法
- (void)segmentValueChanged:(UISegmentedControl *)segmentedControl {
    [self.delegate pageTitleViewDidSelectedAtIndex:segmentedControl.selectedSegmentIndex];
    self.lastSelectedIndex = segmentedControl.selectedSegmentIndex;
}

#pragma mark -
#pragma mark Setter
- (void)setSelectedIndex:(NSInteger)selectedIndex {
    [super setSelectedIndex:selectedIndex];
    self.segmentedControl.selectedSegmentIndex = selectedIndex;
}

@end
