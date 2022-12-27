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

@interface OrganizationPath : NSObject
@property (nonatomic, assign)NSInteger organizationId;
@property(nonatomic, strong)WFCUOrganization *organization;
@property(nonatomic, strong)NSArray<WFCUOrganization *> *subOrganizations;
@property(nonatomic, strong)NSArray<WFCUEmployee *> *employees;
@end

@implementation OrganizationPath
@end

@interface WFCUOrganizationViewController () <UITableViewDataSource, UISearchControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<NSString *> *selectedContacts;

@property (nonatomic, strong) NSMutableArray<WFCCUserInfo *> *searchList;
@property (nonatomic, strong)  UISearchController       *searchController;

@property(nonatomic, strong)UIActivityIndicatorView *activityIndicator;

@property(nonatomic, strong)NSMutableArray<OrganizationPath *> *paths;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendRequestUpdated:) name:kFriendRequestUpdated object:nil];
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
    _searchList = [NSMutableArray array];
    
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
    } else {
        self.tableView.tableHeaderView = _searchController.searchBar;
    }
    self.definesPresentationContext = YES;
    
    self.tableView.sectionIndexColor = [UIColor colorWithHexString:@"0x4e4e4e"];
    [self.view addSubview:self.tableView];
    
    [self.view bringSubviewToFront:self.activityIndicator];
    
    [self loadData];
}

- (void)setOrganizationId:(NSInteger)organizationId {
    if(!_paths) {
        _paths = [[NSMutableArray alloc] init];
    }
    if(!self.paths.count) {
        OrganizationPath *path = [[OrganizationPath alloc] init];
        path.organizationId = organizationId;
        [self.paths addObject:path];
    } else {
        OrganizationPath *path = [self.paths lastObject];
        if(path.organizationId != organizationId) {
            path.organizationId = organizationId;
            path.organization = nil;
            path.subOrganizations = nil;
            path.employees = nil;
        }
    }
}

-(NSInteger)organizationId {
    return [self.paths lastObject].organizationId;
}

- (void)loadData {
    [self.activityIndicator startAnimating];
    WFCUOrganization *roganization = [[WFCUOrganizationCache sharedCache] getOrganization:self.organizationId];
    if(roganization.name) {
        self.title = roganization.name;
    }
    __weak typeof(self)ws = self;
    [[WFCUConfigManager globalManager].orgServiceProvider getOrganization:self.organizationId success:^(WFCUOrganization * _Nonnull organization, NSArray<WFCUOrganization *> * _Nonnull subOrganization, NSArray<WFCUEmployee *> * _Nonnull employees) {
        [subOrganization enumerateObjectsUsingBlock:^(WFCUOrganization * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [[WFCUOrganizationCache sharedCache] put:obj.organizationId organization:obj];
        }];
        [employees enumerateObjectsUsingBlock:^(WFCUEmployee * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [[WFCUOrganizationCache sharedCache] put:obj.employeeId employee:obj];
        }];
        
        if(organization.organizationId == ws.organizationId) {
            OrganizationPath *path = [self.paths lastObject];
            path.organization = organization;
            path.subOrganizations = subOrganization;
            path.employees = employees;
            [ws.tableView reloadData];
        }
        [ws.activityIndicator stopAnimating];
    } error:^(int error_code) {
        [ws.activityIndicator stopAnimating];
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
        OrganizationPath *path = [self.paths lastObject];
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

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    OrganizationPath *path = [self.paths lastObject];
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
    UITableViewCell *cell = nil;
    OrganizationPath *path = [self.paths lastObject];
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
        
        [contactCell.portraitView sd_setImageWithURL:[NSURL URLWithString:[emp.portraitUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
        
        cell = contactCell;
    }
    return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    OrganizationPath *path = [self.paths lastObject];
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
    OrganizationPath *path = [self.paths lastObject];
    if(path.subOrganizations.count && indexPath.section == 0) {
        WFCUOrganization *org = path.subOrganizations[indexPath.row];
        OrganizationPath *newPath = [[OrganizationPath alloc] init];
        newPath.organizationId = org.organizationId;
        newPath.organization = org;
        [self.paths addObject:newPath];
        [self.tableView reloadData];
        [self loadData];
    } else {
        WFCUEmployee *emp = path.employees[indexPath.row];
        WFCUProfileTableViewController *vc = [[WFCUProfileTableViewController alloc] init];
        vc.userId = emp.employeeId;

        vc.hidesBottomBarWhenPushed = YES;
        
        [self.navigationController pushViewController:vc animated:YES];
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
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    self.tabBarController.tabBar.hidden = NO;
    self.extendedLayoutIncludesOpaqueBars = NO;
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (searchController.active) {
        NSString *searchString = [self.searchController.searchBar text];
       
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
