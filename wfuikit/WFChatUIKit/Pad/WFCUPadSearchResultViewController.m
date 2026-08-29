//
//  WFCUPadSearchResultViewController.m
//  WFChat UIKit
//

#import "WFCUPadSearchResultViewController.h"
#import "WFCUConfigManager.h"
#import "Predefine.h"

@interface WFCUPadSearchResultViewController () <UISearchBarDelegate>
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL didAutoFocus;
@end

@implementation WFCUPadSearchResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;

    //搜索框就是这一页的标题栏：输入框占 titleView，右边一颗「取消」，左边不给返回箭头。
    //对应 android `SearchPageFragment.providesOwnToolbar() == true` ——「取消」是唯一出口，
    //右栏不再额外给一条标题栏，也就不该出现「取消」旁边还立着一个返回键的两个出口。
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.titleView = self.searchBar;
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(onCancel:)];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //「点左栏顶上那条搜索框 → 本页的搜索框获得焦点」。只在头一次上屏时抢焦点，
    //之后用户自己收了键盘就别再夺回来。
    if (!self.didAutoFocus) {
        self.didAutoFocus = YES;
        [self.searchBar becomeFirstResponder];
    }
}

- (UISearchBar *)searchBar {
    if (!_searchBar) {
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        _searchBar.delegate = self;
        _searchBar.placeholder = WFCString(@"Search");
        //挂在 titleView 上，自带的那条不透明底会把导航栏切成两截，用 Minimal 只留输入框本体
        _searchBar.searchBarStyle = UISearchBarStyleMinimal;
        //「取消」改挂在导航条右侧（与 android `search_bar.xml` 里那颗一样常驻），
        //搜索框自己不再重复给一颗
        _searchBar.showsCancelButton = NO;
        if (@available(iOS 13, *)) {
            _searchBar.searchTextField.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        }
    }
    return _searchBar;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        if (@available(iOS 15, *)) {
            _tableView.sectionHeaderTopPadding = 0;
        }
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        //「展开更多」那一行用的是 forIndexPath: 版本的 dequeue，必须先登记
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"expansion"];
        _tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    }
    return _tableView;
}

#pragma mark - 取消

- (void)onCancel:(id)sender {
    [self.searchBar resignFirstResponder];
    if ([self.searchDelegate respondsToSelector:@selector(padSearchResultControllerDidCancel:)]) {
        [self.searchDelegate padSearchResultControllerDidCancel:self];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.searchDelegate padSearchResultController:self textDidChange:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

@end
