//
//  WFCUCalendarSearchViewController.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/1/4.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCUCalendarSearchViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUMessageListViewController.h"
#import "WFCUConfigManager.h"
#import "WFCUUtilities.h"
#import "MBProgressHUD.h"

@interface WFCUCalendarDayCell : UICollectionViewCell
@property(nonatomic, strong)UILabel *dayLabel;
@property(nonatomic, assign)BOOL hasMessage;
@property(nonatomic, strong)NSDate *date;
@property(nonatomic, assign)NSInteger messageCount;
@end

@implementation WFCUCalendarDayCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.dayLabel = [[UILabel alloc] initWithFrame:self.bounds];
    self.dayLabel.textAlignment = NSTextAlignmentCenter;
    self.dayLabel.font = [UIFont systemFontOfSize:16];
    self.dayLabel.layer.cornerRadius = CGRectGetWidth(self.bounds) / 2;
    self.dayLabel.layer.masksToBounds = YES;
    [self.contentView addSubview:self.dayLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.dayLabel.frame = self.bounds;
}

- (void)setHasMessage:(BOOL)hasMessage {
    _hasMessage = hasMessage;
    if (hasMessage) {
        self.dayLabel.textColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
        self.dayLabel.backgroundColor = [UIColor colorWithRed:0.9 green:0.95 blue:1.0 alpha:1.0];
        self.userInteractionEnabled = YES;
    } else {
        self.dayLabel.textColor = [UIColor lightGrayColor];
        self.dayLabel.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
    }
}

@end

@interface WFCUMonthHeaderView : UICollectionReusableView
@property(nonatomic, strong)UILabel *monthLabel;
@end

@implementation WFCUMonthHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.monthLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, frame.size.width - 32, 30)];
        self.monthLabel.font = [UIFont boldSystemFontOfSize:18];
        self.monthLabel.textColor = [UIColor blackColor];
        [self addSubview:self.monthLabel];
    }
    return self;
}

@end

@interface WFCUCalendarSearchViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property(nonatomic, strong)UICollectionView *collectionView;
@property(nonatomic, strong)NSCalendar *calendar;
@property(nonatomic, strong)NSMutableArray<NSDate *> *months;
@property(nonatomic, strong)NSMutableDictionary<NSString *, NSDictionary<NSString *, NSNumber *> *> *messageCountCache;
@property(nonatomic, strong)NSMutableSet<NSString *> *loadingMonths;
@property(nonatomic, strong)MBProgressHUD *hud;
@end

@implementation WFCUCalendarSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = WFCString(@"SearchByDate");
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;

    self.calendar = [NSCalendar currentCalendar];
    self.months = [[NSMutableArray alloc] init];
    self.messageCountCache = [[NSMutableDictionary alloc] init];
    self.loadingMonths = [[NSMutableSet alloc] init];

    // 初始化月份：当前月份在前，然后是前2个月（逆序）
    NSDate *currentDate = [NSDate date];
    for (int i = 0; i < 3; i++) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.month = -i;
        NSDate *month = [self.calendar dateByAddingComponents:components toDate:currentDate options:0];
        [self.months addObject:month];
    }

    [self setupCollectionView];
    [self loadDataForVisibleMonths];

    // 添加返回按钮
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Back") style:UIBarButtonItemStylePlain target:self action:@selector(onBack:)];
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 8;

    CGFloat itemWidth = (self.view.bounds.size.width - 32) / 7;
    layout.itemSize = CGSizeMake(itemWidth, itemWidth);
    layout.headerReferenceSize = CGSizeMake(self.view.bounds.size.width, 100);

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[WFCUCalendarDayCell class] forCellWithReuseIdentifier:@"DayCell"];
    [self.collectionView registerClass:[WFCUMonthHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"MonthHeader"];
    [self.view addSubview:self.collectionView];
}

- (void)loadDataForVisibleMonths {
    for (NSDate *month in self.months) {
        [self loadMessageDataForMonth:month];
    }
}

- (void)loadMessageDataForMonth:(NSDate *)monthDate {
    NSString *monthKey = [self formatMonthKey:monthDate];

    if ([self.loadingMonths containsObject:monthKey] || self.messageCountCache[monthKey]) {
        return;
    }

    [self.loadingMonths addObject:monthKey];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 获取月份的开始和结束时间（本地时区）
        NSDateComponents *components = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:monthDate];
        components.day = 1;
        components.hour = 0;
        components.minute = 0;
        components.second = 0;
        NSDate *firstDayOfMonth = [self.calendar dateFromComponents:components];

        NSRange rangeOfMonth = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:firstDayOfMonth];
        NSDateComponents *lastDayComponents = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:firstDayOfMonth];
        lastDayComponents.day = rangeOfMonth.length;
        lastDayComponents.hour = 23;
        lastDayComponents.minute = 59;
        lastDayComponents.second = 59;
        NSDate *lastDayOfMonth = [self.calendar dateFromComponents:lastDayComponents];

        int64_t startTime = [firstDayOfMonth timeIntervalSince1970];
        int64_t endTime = [lastDayOfMonth timeIntervalSince1970];

        __weak typeof(self) ws = self;
        NSDictionary<NSString *, NSNumber *> *counts = [[WFCCIMService sharedWFCIMService] getMessageCountByDay:ws.conversation contentTypes:nil startTime:startTime endTime:endTime];

        dispatch_async(dispatch_get_main_queue(), ^{
            ws.messageCountCache[monthKey] = counts;
            [ws.loadingMonths removeObject:monthKey];
            [ws.collectionView reloadData];
        });
    });
}

- (void)loadEarlierMonths {
    // 加载更早的月份（添加到数组末尾，因为是逆序显示）
    NSDate *oldestMonth = self.months.lastObject;
    for (int i = 1; i <= 3; i++) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.month = -i;
        NSDate *newMonth = [self.calendar dateByAddingComponents:components toDate:oldestMonth options:0];
        [self.months addObject:newMonth];
    }
    [self loadMessageDataForMonth:self.months.lastObject];
    [self.collectionView reloadData];
}

- (void)loadLaterMonths {
    // 加载更晚的月份（添加到数组开头，因为是逆序显示）
    // 但不能超过当前月份
    NSDate *latestMonth = self.months.firstObject;

    // 检查是否已经是当前月份
    NSDateComponents *latestComponents = [self.calendar components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:latestMonth];
    NSDateComponents *currentComponents = [self.calendar components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:[NSDate date]];

    if (latestComponents.year == currentComponents.year && latestComponents.month == currentComponents.month) {
        // 已经是当前月份，不再加载
        return;
    }

    for (int i = 1; i <= 3; i++) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.month = i;
        NSDate *newMonth = [self.calendar dateByAddingComponents:components toDate:latestMonth options:0];

        // 检查是否会超过当前月份
        NSDateComponents *newComponents = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:newMonth];
        if (newComponents.year > currentComponents.year ||
            (newComponents.year == currentComponents.year && newComponents.month > currentComponents.month)) {
            // 超过当前月份，停止加载
            break;
        }

        [self.months insertObject:newMonth atIndex:0];
    }

    if (self.months.count > 0) {
        [self loadMessageDataForMonth:self.months.firstObject];
        [self.collectionView reloadData];
    }
}

- (void)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString *)formatMonthKey:(NSDate *)date {
    NSDateComponents *components = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:date];
    return [NSString stringWithFormat:@"%ld-%02ld", (long)components.year, (long)components.month];
}

- (NSString *)formatDateKey:(NSDate *)date {
    NSDateComponents *components = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    return [NSString stringWithFormat:@"%ld-%02ld-%02ld", (long)components.year, (long)components.month, (long)components.day];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.months.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDate *monthDate = self.months[section];
    NSDateComponents *components = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:monthDate];
    components.day = 1;
    NSDate *firstDayOfMonth = [self.calendar dateFromComponents:components];

    NSRange rangeOfMonth = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:firstDayOfMonth];
    NSDateComponents *firstWeekday = [self.calendar components:NSCalendarUnitWeekday fromDate:firstDayOfMonth];

    NSInteger firstDayIndex = firstWeekday.weekday - 1;

    return rangeOfMonth.length + firstDayIndex;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionHeader) {
        WFCUMonthHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"MonthHeader" forIndexPath:indexPath];

        NSDate *monthDate = self.months[indexPath.section];
        NSDateComponents *components = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:monthDate];
        header.monthLabel.text = [NSString stringWithFormat:@"%ld年%ld月", (long)components.year, (long)components.month];

        // 添加星期标签
        for (UIView *subview in header.subviews) {
            if ([subview isKindOfClass:[UILabel class]] && subview != header.monthLabel) {
                [subview removeFromSuperview];
            }
        }

        NSArray *weekdays = @[@"日", @"一", @"二", @"三", @"四", @"五", @"六"];
        CGFloat weekdayWidth = (self.view.bounds.size.width - 32) / 7;
        for (int i = 0; i < 7; i++) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16 + i * weekdayWidth, 45, weekdayWidth, 20)];
            label.text = weekdays[i];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont systemFontOfSize:14];
            label.textColor = [UIColor grayColor];
            [header addSubview:label];
        }

        return header;
    }
    return nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFCUCalendarDayCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DayCell" forIndexPath:indexPath];

    NSDate *monthDate = self.months[indexPath.section];

    // 计算日期
    NSDateComponents *components = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:monthDate];
    components.day = 1;
    NSDate *firstDayOfMonth = [self.calendar dateFromComponents:components];

    NSRange rangeOfMonth = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:firstDayOfMonth];
    NSDateComponents *firstWeekday = [self.calendar components:NSCalendarUnitWeekday fromDate:firstDayOfMonth];

    NSInteger firstDayIndex = firstWeekday.weekday - 1;
    NSInteger day = indexPath.row - firstDayIndex + 1;

    if (day >= 1 && day <= rangeOfMonth.length) {
        cell.dayLabel.text = [NSString stringWithFormat:@"%ld", (long)day];
        cell.dayLabel.hidden = NO;

        // 检查这一天是否有消息
        NSDateComponents *dateComponents = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:monthDate];
        dateComponents.day = day;
        NSDate *date = [self.calendar dateFromComponents:dateComponents];

        NSString *monthKey = [self formatMonthKey:monthDate];
        NSString *dateKey = [self formatDateKey:date];
        NSDictionary *counts = self.messageCountCache[monthKey];
        NSNumber *count = counts[dateKey];

        cell.hasMessage = count && [count integerValue] > 0;
        cell.messageCount = count ? [count integerValue] : 0;
        cell.date = date;
    } else {
        cell.dayLabel.text = @"";
        cell.dayLabel.hidden = YES;
        cell.hasMessage = NO;
        cell.date = nil;
    }

    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    WFCUCalendarDayCell *cell = (WFCUCalendarDayCell *)[collectionView cellForItemAtIndexPath:indexPath];

    if (cell.hasMessage && cell.date) {
        // 点击有消息的日期，弹出TODO提示
//        NSDateComponents *components = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:cell.date];
//        NSString *dateStr = [NSString stringWithFormat:@"%ld年%ld月%ld日", (long)components.year, (long)components.month, (long)components.day];
//
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"TODO"
//                                                                       message:[NSString stringWithFormat:@"%@\n共有 %ld 条消息", dateStr, (long)cell.messageCount]
//                                                                preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction *okAction = [UIAlertAction actionWithTitle:WFCString(@"Ok") style:UIAlertActionStyleDefault handler:nil];
//        [alert addAction:okAction];
//        [self presentViewController:alert animated:YES completion:nil];
        WFCUMessageListViewController *vc = [[WFCUMessageListViewController alloc] init];
        vc.conversation = self.conversation;
        vc.selectedDate = cell.date;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 检测是否滚动到底部，加载更早的月份
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat height = scrollView.bounds.size.height;

    if (offsetY > contentHeight - height - 50) {
        // 滚动到底部，加载更早的月份
        static BOOL isLoadingBottom = NO;
        if (!isLoadingBottom) {
            isLoadingBottom = YES;
            [self loadEarlierMonths];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                isLoadingBottom = NO;
            });
        }
    }
}

@end
