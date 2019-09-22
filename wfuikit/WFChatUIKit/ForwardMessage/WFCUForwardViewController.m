//
//  ForwardViewController.m
//  WildFireChat
//
//  Created by heavyrain lee on 2018/9/27.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "WFCUForwardViewController.h"
#import "SDWebImage.h"
#import "WFCUForwardMessageCell.h"
#import "WFCUContactTableViewCell.h"
#import "WFCUSearchGroupTableViewCell.h"
#import "TYAlertView.h"
#import "TYAlertController.h"
#import "WFCUShareMessageView.h"
#import "UIView+TYAlertView.h"
#import "UIView+Toast.h"
#import "WFCUContactListViewController.h"
#import "WFCUConfigManager.h"

@interface WFCUForwardViewController () <UITableViewDataSource, UISearchControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)UISearchController *searchController;
@property (nonatomic, strong)NSMutableArray<WFCCConversationInfo *> *conversations;
@property (nonatomic, strong)NSArray<WFCCUserInfo *>  *searchFriendList;
@property (nonatomic, strong)NSArray<WFCCGroupSearchInfo *>  *searchGroupList;
@end

@implementation WFCUForwardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect frame = self.view.frame;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 54, frame.size.width, frame.size.height - 64)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.tableView.tableHeaderView = nil;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(onLeftBarBtn:)];

    self.conversations = [[[WFCCIMService sharedWFCIMService] getConversationInfos:@[@(Single_Type), @(Group_Type)] lines:@[@(0)]] mutableCopy];

    
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    if (! @available(iOS 13, *)) {
        [self.searchController.searchBar setValue:WFCString(@"Cancel") forKey:@"_cancelButtonText"];
    }
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    
    [self.searchController.searchBar setPlaceholder:WFCString(@"Search")];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        _searchController.hidesNavigationBarDuringPresentation = YES;
    } else {
        self.tableView.tableHeaderView = _searchController.searchBar;
    }
    self.definesPresentationContext = YES;
    
    self.tableView.sectionIndexColor = [UIColor grayColor];
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
}

- (void)onLeftBarBtn:(UIBarButtonItem *)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)altertSend:(WFCCConversation *)conversation {
    WFCUShareMessageView *shareView = [WFCUShareMessageView createViewFromNib];
    
    shareView.conversation = conversation;
    shareView.message = self.message;
    __weak typeof(self)ws = self;
    shareView.forwardDone = ^(BOOL success) {
        if (success) {
            [ws.view makeToast:WFCString(@"ForwardSuccess") duration:1 position:CSToastPositionCenter];
            [ws.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [ws.view makeToast:WFCString(@"ForwardFailure") duration:1 position:CSToastPositionCenter];
        }
    };
    TYAlertController *alertController = [TYAlertController alertControllerWithAlertView:shareView preferredStyle:TYAlertControllerStyleAlert];
    
//    // blur effect
//    [alertController setBlurEffectWithView:self.view];
//
    //alertController.alertViewOriginY = 60;
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
//    [shareView showInWindow];
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.active) {
        int sec = 0;
        if (self.searchFriendList.count) {
            sec++;
            if (section == sec-1) {
                return self.searchFriendList.count;
            }
        }
        
        if (self.searchGroupList.count) {
            sec++;
            if (section == sec-1) {
                return self.searchGroupList.count;
            }
        }
        
        return 0;
    } else {
        if (section == 0) {
            return 1;
        }
        return self.conversations.count;
    }
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
#define REUSECONVIDENTIFY @"resueConvCell"
#define REUSENEWCONVIDENTIFY @"resueNewConvCell"
    if (self.searchController.active) {
        int sec = 0;
        if (self.searchFriendList.count) {
            sec++;
            if (indexPath.section == sec-1) {
                WFCUContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendCell"];
                if (cell == nil) {
                    cell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"friendCell"];
                }
                cell.userId = self.searchFriendList[indexPath.row].userId;
                return cell;
            }
        }
        if (self.searchGroupList.count) {
            sec++;
            if (indexPath.section == sec-1) {
                WFCUSearchGroupTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupCell"];
                if (cell == nil) {
                    cell = [[WFCUSearchGroupTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupCell"];
                }
                cell.groupSearchInfo = self.searchGroupList[indexPath.row];
                return cell;
            }
        }
        return nil;
    } else {
        if (indexPath.section == 0) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:REUSENEWCONVIDENTIFY];
            if(!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSENEWCONVIDENTIFY];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            cell.textLabel.text = WFCString(@"CreateNewChat");
            return cell;
        } else {
            WFCUForwardMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:REUSECONVIDENTIFY];
            if(!cell) {
                cell = [[WFCUForwardMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSECONVIDENTIFY];
            }
            WFCCConversationInfo *info = [self.conversations objectAtIndex:indexPath.row];
            cell.conversation = info.conversation;
            return cell;
        }
        
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.searchController.active) {
        int sec = 0;
        if (self.searchFriendList.count) {
            sec++;
        }
        
        if (self.searchGroupList.count) {
            sec++;
        }
        
        if (sec == 0) {
            sec = 1;
        }
        return sec;
    }
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if (self.searchController.isActive) {
            return 44;
        } else {
            return 0;
        }
    }
    return 21;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.searchController.isActive) {
        if (self.searchGroupList.count + self.searchFriendList.count > 0) {
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, section == 0 ? 44 : 20)];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, section == 0 ? 24 : 0, self.tableView.frame.size.width, 20)];
            
            label.font = [UIFont systemFontOfSize:13];
            label.textColor = [UIColor grayColor];
            label.textAlignment = NSTextAlignmentLeft;
            label.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
            
            int sec = 0;
            if (self.searchFriendList.count) {
                sec++;
                if (section == sec-1) {
                    label.text = WFCString(@"Contact");
                }
            }
            
            if (self.searchGroupList.count) {
                sec++;
                if (section == sec-1) {
                    label.text = WFCString(@"Group");
                }
            }

            [header addSubview:label];
            return header;
        } else {
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 50)];
            return header;
        }
    } else {
        NSString *title = WFCString(@"RecentChat");
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 21)];
        label.font = [UIFont systemFontOfSize:13];
        label.textColor = [UIColor grayColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = [NSString stringWithFormat:@"  %@", title];
        label.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        return label;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCConversation *selectedConv;
    if (self.searchController.isActive) {
        if (indexPath.section == 0 && self.searchFriendList.count > 0) {
            WFCCUserInfo *userInfo = self.searchFriendList[indexPath.row];
            selectedConv = [[WFCCConversation alloc] init];
            selectedConv.type = Single_Type;
            selectedConv.target = userInfo.userId;
            selectedConv.line = 0;
        } else {
            WFCCGroupInfo *groupInfo = self.searchGroupList[indexPath.row].groupInfo;
            selectedConv = [[WFCCConversation alloc] init];
            selectedConv.type = Group_Type;
            selectedConv.target = groupInfo.target;
            selectedConv.line = 0;
        }
    } else {
        if (indexPath.section == 0) { //new conversation
            WFCUContactListViewController *pvc = [[WFCUContactListViewController alloc] init];
            pvc.selectContact = YES;
            pvc.multiSelect = NO;
            pvc.isPushed = YES;
            __weak typeof(self)ws = self;
            pvc.selectResult = ^(NSArray<NSString *> *contacts) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (contacts.count == 1) {
                        WFCCConversation *conversation = [[WFCCConversation alloc] init];
                        conversation.type = Single_Type;
                        conversation.target = contacts[0];
                        conversation.line = 0;
                        [ws altertSend:conversation];
                    }
                });
            };
            
            [self.navigationController pushViewController:pvc animated:YES];
            return;
        } else {
            selectedConv = self.conversations[indexPath.row].conversation;
        }
    }
    if (selectedConv) {
        [self altertSend:selectedConv];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}
#pragma mark - UISearchControllerDelegate
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    
    if (searchString.length) {
        self.searchFriendList = [[WFCCIMService sharedWFCIMService] searchFriends:searchString];
        self.searchGroupList = [[WFCCIMService sharedWFCIMService] searchGroups:searchString];
    } else {
        self.searchFriendList = nil;
        self.searchGroupList = nil;
    }
    
    
    [self.tableView reloadData];
}
@end
