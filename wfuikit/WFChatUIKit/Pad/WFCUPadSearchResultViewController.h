//
//  WFCUPadSearchResultViewController.h
//  WFChat UIKit
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCUPadSearchResultViewController;

/// 搜索页只管收键盘输入，取数、分组、点击处理仍然长在左栏那个列表控制器身上。
@protocol WFCUPadSearchResultDelegate <NSObject>
/// 搜索框内容变了，按新的关键字重新取数
- (void)padSearchResultController:(WFCUPadSearchResultViewController *)controller
                    textDidChange:(NSString *)text;
@optional
/// 点了导航条右侧的「取消」
- (void)padSearchResultControllerDidCancel:(WFCUPadSearchResultViewController *)controller;
@end

/// iPad 双栏下承载搜索的右栏页面：搜索输入框就是本页的标题栏（titleView），
/// 导航条左侧不给返回箭头、右侧一颗「取消」，下面是结果列表。
///
/// 对应 android `SearchPageFragment`（登记进 `PaneRegistry`，
/// 布局是 `search_bar.xml`：搜索框 + 取消，且 `providesOwnToolbar()==true`，
/// 右栏不再给它一条标题栏 —— 所以这里也只留「取消」一个出口，不再额外挂返回箭头），
/// 以及 flutter `app_navigator.openSearch`
/// 把 `SearchPortalDelegate` 压给右栏 Navigator —— 两端的搜索框都长在搜索页自己身上，
/// 左栏顶上那个只是一颗按钮（android `R.id.search` 菜单项、flutter `_onTapSearchButton`）。
///
/// 表格的 dataSource/delegate 是左栏那个列表控制器：搜索的取数、分组、展开与点击处理
/// 都在它身上，搬出来等于把那几百行 dataSource 抄第二遍。左栏那张表和这张表靠
/// `tableView` 参数区分（各列表控制器里的 `isSearchTableView:`）。
///
/// 每次进入搜索都新建一个实例，不复用 —— 对应 android 那句「都不去重：每次进来都该是
/// 一张空搜索框，退回上次的搜索结果反而是错的」。
@interface WFCUPadSearchResultViewController : UIViewController
@property (nonatomic, strong, readonly) UISearchBar *searchBar;
@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, weak) id<WFCUPadSearchResultDelegate> searchDelegate;
@end

NS_ASSUME_NONNULL_END
