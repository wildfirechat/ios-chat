//
//  WFCUOrganizationViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/7.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUOrganizationViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "WFCUProfileTableViewController.h"
#import "WFCUContactSelectTableViewCell.h"
#import "WFCUContactTableViewCell.h"
#import "pinyin.h"
#import "WFCUFavGroupTableViewController.h"
#import "WFCUFriendRequestViewController.h"
#import "UITabBar+badge.h"
#import "WFCUNewFriendTableViewCell.h"
#import "WFCUAddFriendViewController.h"
#import "MBProgressHUD.h"
#import "WFCUFavChannelTableViewController.h"
#import "WFCUConfigManager.h"
#import "UIView+Toast.h"
#import "UIImage+ERCategory.h"
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "WFCUPinyinUtility.h"
#import "WFCUImage.h"
#import "WFCUOrganizationCache.h"
#import "WFCUOrganization.h"
#import "WFCUEmployee.h"
#import "WFCUUtilities.h"
#import "WFCUOrganizationEx.h"


@interface WFCUOrganizationViewController () <UITableViewDataSource, UISearchControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<NSString *> *selectedContacts;

@property (nonatomic, strong)  UISearchController       *searchController;

@property(nonatomic, strong)UIActivityIndicatorView *activityIndicator;

@property (nonatomic, assign)NSInteger lastOrganizationId;

@property(nonatomic, strong)NSMutableArray<WFCUOrganizationEx *> *paths;

@property(nonatomic, strong)UICollectionView *collectionView;

@property(nonatomic, strong)NSArray<WFCUEmployee *> *searchResults;
@end

@implementation WFCUOrganizationViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.paths = [[NSMutableArray alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrganizationExUpdated:) name:kOrganizationExUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrganizationUpdated:) name:kOrganizationUpdated object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGRect frame = self.view.frame;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.tableHeaderView = nil;
    if (self.selectContact) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(onLeftBarBtn:)];
        
        if(self.multiSelect) {
            self.selectedContacts = [[NSMutableArray alloc] init];
            [self updateNavBarBtn];
        }
    } else {
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithImage:[WFCUImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(onBackBtn:)];
        UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithImage:[WFCUImage imageNamed:@"close"] style:UIBarButtonItemStylePlain target:self action:@selector(onLeftBarBtn:)];
        self.navigationItem.leftBarButtonItems = @[back, close];
    }
    
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    
    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        self.searchController.searchBar.searchTextField.backgroundColor = [WFCUConfigManager globalManager].naviBackgroudColor;
        UIImage* searchBarBg = [UIImage imageWithColor:[UIColor whiteColor] size:CGSizeMake(self.view.frame.size.width - 8 * 2, 36) cornerRadius:4];
        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
    } else {
        [self.searchController.searchBar setValue:WFCString(@"Cancel") forKey:@"_cancelButtonText"];
    }
    
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    
    [self.searchController.searchBar setPlaceholder:WFCString(@"SearchContact")];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        _searchController.hidesNavigationBarDuringPresentation = YES;
    }
    self.definesPresentationContext = YES;
    
    self.tableView.sectionIndexColor = [UIColor colorWithHexString:@"0x4e4e4e"];
    
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 32) collectionViewLayout:layout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.tableView.tableHeaderView = self.collectionView;
    
    [self.view addSubview:self.tableView];
    
    [self.view bringSubviewToFront:self.activityIndicator];
    
    [self loadData];
}

- (void)onOrganizationExUpdated:(NSNotification *)notification {
    NSInteger orgId = [notification.object integerValue];
    if(orgId == self.lastOrganizationId) {
        WFCUOrganizationEx * path = [[WFCUOrganizationCache sharedCache] getOrganizationEx:self.lastOrganizationId refresh:NO];
        WFCUOrganizationEx *p = [self.paths lastObject];
        p.organization = path.organization;
        p.subOrganizations = path.subOrganizations;
        p.employees = path.employees;
        [self.tableView reloadData];
        [self.collectionView reloadData];
    }
}

- (void)onOrganizationUpdated:(NSNotification *)notification {
    [self.collectionView reloadData];
}

- (void)setOrganizationIds:(NSArray<NSNumber *> *)organizationIds {
    _organizationIds = organizationIds;
    if(!_paths) {
        _paths = [[NSMutableArray alloc] init];
    }
    [organizationIds enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        WFCUOrganizationEx *path = [[WFCUOrganizationEx alloc] init];
        path.organizationId = [obj integerValue];
        [self.paths addObject:path];
    }];
}

-(NSInteger)lastOrganizationId {
    return [self.paths lastObject].organizationId;
}

- (void)loadData {
    WFCUOrganization *roganization = [[WFCUOrganizationCache sharedCache] getOrganization:self.lastOrganizationId refresh:YES];
    if(roganization.name) {
        self.title = roganization.name;
    }
    __weak typeof(self)ws = self;
    
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"加载中...";
    [hud showAnimated:YES];
    [[WFCUOrganizationCache sharedCache] getOrganizationEx:self.lastOrganizationId refresh:YES success:^(NSInteger organizationId, WFCUOrganizationEx * _Nonnull ex) {
        [hud hideAnimated:NO];
        if(ws.lastOrganizationId == organizationId) {
            WFCUOrganizationEx *p = [self.paths lastObject];
            p.organization = ex.organization;
            p.subOrganizations = ex.subOrganizations;
            p.employees = ex.employees;
            [ws.tableView reloadData];
            [ws.collectionView reloadData];
        }
    } error:^(int error_code) {
        [hud hideAnimated:NO];
        hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"加载失败";
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
    }];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self.tableView reloadData];
        }
    }
}

- (void)updateNavBarBtn {
    if(self.selectedContacts.count == 0) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Ok") style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        if (self.multiSelect && self.maxSelectCount > 1) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@(%d/%d)", WFCString(@"Ok"),  (int)self.selectedContacts.count, self.maxSelectCount] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        } else {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@(%d)", WFCString(@"Ok"),  (int)self.selectedContacts.count] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        }
    }
}

- (void)onRightBarBtn:(UIBarButtonItem *)sender {
    if (self.selectContact) {
        if (self.selectedContacts) {
            [self left:^{
                self.selectResult(self.selectedContacts);
            }];
        }
    } else {
        UIViewController *addFriendVC = [[WFCUAddFriendViewController alloc] init];
        addFriendVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:addFriendVC animated:YES];
    }
}

- (void)onBackBtn:(UIBarButtonItem *)sender {
    if(self.paths.count > 1) {
        [self.paths removeLastObject];
        [self.tableView reloadData];
        [self loadData];
    } else {
        [self onLeftBarBtn:sender];
    }
}

- (void)onLeftBarBtn:(UIBarButtonItem *)sender {
    if (self.cancelSelect) {
        self.cancelSelect();
    }
    [self left:nil];
}

- (void)left:(void (^)(void))completion {
    if (self.isPushed) {
        [self.navigationController popViewControllerAnimated:YES];
        if(completion) {
            completion();
        }
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:completion];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)getOrganizationNameOfIndexPath:(NSIndexPath *)indexPath {
    NSString *name = @"通讯录";
    if(indexPath.row > 0) {
        WFCUOrganizationEx *path = self.paths[indexPath.row - 1];
        if(path.organization.name.length) {
            name = path.organization.name;
        } else {
            WFCUOrganization *org = [[WFCUOrganizationCache sharedCache] getOrganization:path.organizationId refresh:NO];
            if(org.name.length) {
                name = org.name;
            } else {
                name = [NSString stringWithFormat:@"%ld", path.organizationId];
            }
        }
    }
    return name;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.paths.count+1;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *name = [self getOrganizationNameOfIndexPath:indexPath];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    [cell.contentView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    CGSize size = [WFCUUtilities getTextDrawingSize:name font:[UIFont systemFontOfSize:16] constrainedSize:CGSizeMake(10000, 20)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, 32)];
    label.text = name;
    label.textColor = [UIColor blueColor];
    label.font = [UIFont systemFontOfSize:16];
    [cell.contentView addSubview:label];
    
    BOOL lastItem = (indexPath.row == self.paths.count);
    if(!lastItem) {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(size.width, 4, 25, 25)];
        iv.image = [WFCUImage imageNamed:@"back_normal"];
        [cell.contentView addSubview:iv];
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == 0) {
        [self onLeftBarBtn:nil];
    } else {
        [self.paths removeObjectsInRange:NSMakeRange(indexPath.row, self.paths.count-indexPath.row)];
        [self loadData];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *name = [self getOrganizationNameOfIndexPath:indexPath];
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    [cell.contentView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    CGSize size = [WFCUUtilities getTextDrawingSize:name font:[UIFont systemFontOfSize:16] constrainedSize:CGSizeMake(10000, 20)];
    BOOL lastItem = (indexPath.row == self.paths.count);
    if(!lastItem) {
        size.width += 25;
    }
    return CGSizeMake(size.width, 32);
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.searchController.active) {
        return self.searchResults.count;
    }
    
    WFCUOrganizationEx *path = [self.paths lastObject];
    if(path.subOrganizations.count && section == 0) {
        return path.subOrganizations.count;
    }
    return path.employees.count;
}

#define REUSEIDENTIFY @"resueCell"
- (WFCUContactTableViewCell *)dequeueOrAllocContactCell:(UITableView *)tableView {
    WFCUContactTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
    }
    return contactCell;
}
#define ORGANIZATION_REUSEIDENTIFY @"organizationCell"
- (WFCUContactTableViewCell *)dequeueOrAllocOrganizationCell:(UITableView *)tableView {
    WFCUContactTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:ORGANIZATION_REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ORGANIZATION_REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
    }
    return contactCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.searchController.active) {
        WFCUEmployee *emp = self.searchResults[indexPath.row];
        WFCUContactTableViewCell *contactCell = [self dequeueOrAllocContactCell:tableView];
        contactCell.nameLabel.text = emp.name;
        
        [contactCell.portraitView sd_setImageWithURL:[NSURL URLWithString:[emp.portraitUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [WFCUImage imageNamed:@"employee"]];
        
        return contactCell;
    } else {
        UITableViewCell *cell = nil;
        WFCUOrganizationEx *path = [self.paths lastObject];
        if(path.subOrganizations.count && indexPath.section == 0) {
            WFCUOrganization *org = path.subOrganizations[indexPath.row];
            WFCUContactTableViewCell *contactCell = [self dequeueOrAllocOrganizationCell:tableView];
            contactCell.nameLabel.text = [NSString stringWithFormat:@"%@(%d)", org.name, org.memberCount];
            contactCell.imageView.image = [WFCUImage imageNamed:@"organization_icon"];
            cell = contactCell;
        } else {
            WFCUEmployee *emp = path.employees[indexPath.row];
            WFCUContactTableViewCell *contactCell = [self dequeueOrAllocContactCell:tableView];
            contactCell.nameLabel.text = emp.name;
            
            [contactCell.portraitView sd_setImageWithURL:[NSURL URLWithString:[emp.portraitUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [WFCUImage imageNamed:@"employee"]];
            
            cell = contactCell;
        }
        return cell;
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(self.searchController.active) {
        return 1;
    }
    
    WFCUOrganizationEx *path = [self.paths lastObject];
    if(path.subOrganizations.count && path.employees.count)
        return 2;
    if(path.subOrganizations.count)
        return 1;
    if(path.employees.count)
        return 1;
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

- (UIActivityIndicatorView *)activityIndicator {
    if (!_activityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
        [self.view addSubview:_activityIndicator];
        [self.view bringSubviewToFront:_activityIndicator];
    }
    return _activityIndicator;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
  if (self.selectContact) {
    return index;
  }
  if (self.searchController.active) {
    return index;
  }
  return index;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.searchController.active) {
        WFCUEmployee *emp = self.searchResults[indexPath.row];
        WFCUProfileTableViewController *vc = [[WFCUProfileTableViewController alloc] init];
        vc.userId = emp.employeeId;
        vc.sourceType = FriendSource_Org;
        vc.hidesBottomBarWhenPushed = YES;
        
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        WFCUOrganizationEx *path = [self.paths lastObject];
        if(path.subOrganizations.count && indexPath.section == 0) {
            WFCUOrganization *org = path.subOrganizations[indexPath.row];
            WFCUOrganizationEx *newPath = [[WFCUOrganizationEx alloc] init];
            newPath.organizationId = org.organizationId;
            newPath.organization = org;
            [self.paths addObject:newPath];
            [self.tableView reloadData];
            [self loadData];
        } else {
            WFCUEmployee *emp = path.employees[indexPath.row];
            WFCUProfileTableViewController *vc = [[WFCUProfileTableViewController alloc] init];
            vc.userId = emp.employeeId;
            vc.sourceType = FriendSource_Org;
            vc.hidesBottomBarWhenPushed = YES;
            
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}
#pragma mark - UISearchControllerDelegate
- (void)didPresentSearchController:(UISearchController *)searchController {
    self.tabBarController.tabBar.hidden = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
    CGRect frame = self.collectionView.frame;
    frame.size.height = 0;
    self.collectionView.frame = frame;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    self.tabBarController.tabBar.hidden = NO;
    self.extendedLayoutIncludesOpaqueBars = NO;
    CGRect frame = self.collectionView.frame;
    frame.size.height = 32;
    self.collectionView.frame = frame;
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (searchController.active) {
        NSString *searchString = [self.searchController.searchBar text];
        if(searchString.length) {
            [[WFCUConfigManager globalManager].orgServiceProvider searchEmployee:self.lastOrganizationId keyword:searchString success:^(NSArray<WFCUEmployee *> * _Nonnull employees) {
                NSLog(@"the search result is %d", employees.count);
                self.searchResults = employees;
                [self.tableView reloadData];
            } error:^(int error_code) {
                
            }];
        } else {
            self.searchResults = @[];
        }
    }
    [self.tableView reloadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
