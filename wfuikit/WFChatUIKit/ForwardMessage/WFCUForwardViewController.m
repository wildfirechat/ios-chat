//
//  ForwardViewController.m
//  WildFireChat
//
//  Created by heavyrain lee on 2018/9/27.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "WFCUForwardViewController.h"
#import <SDWebImage/SDWebImage.h>
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
#import "UIImage+ERCategory.h"
#import <WFChatClient/WFCChatClient.h>


@interface WFCUForwardViewController () <UITableViewDataSource, UISearchControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)UISearchController *searchController;
@property (nonatomic, strong)NSMutableArray<WFCCConversationInfo *> *conversations;
@property (nonatomic, strong)NSArray<WFCCUserInfo *>  *searchFriendList;
@property (nonatomic, strong)NSArray<WFCCGroupSearchInfo *>  *searchGroupList;
@property (nonatomic, strong)NSMutableArray<WFCCConversation *> *selectedConversations;
@property (nonatomic, assign)NSInteger maxSelectCount;
@end

@implementation WFCUForwardViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.selectedConversations = [[NSMutableArray alloc] init];
    self.maxSelectCount = 9;

    CGRect frame = self.view.frame;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 54, frame.size.width, frame.size.height - 64)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelection = YES;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.tableHeaderView = nil;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(onLeftBarBtn:)];

    self.conversations = [[[WFCCIMService sharedWFCIMService] getConversationInfos:@[@(Single_Type), @(Group_Type), @(SecretChat_Type)] lines:@[@(0)]] mutableCopy];

    self.extendedLayoutIncludesOpaqueBars = YES;

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

    [self.searchController.searchBar setPlaceholder:WFCString(@"Search")];

    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        _searchController.hidesNavigationBarDuringPresentation = YES;
    } else {
        self.tableView.tableHeaderView = _searchController.searchBar;
    }
    self.definesPresentationContext = YES;

    [self updateRightBarButtonItem];

    self.tableView.sectionIndexColor = [UIColor grayColor];
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
}

- (void)onLeftBarBtn:(UIBarButtonItem *)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)onRightBarBtn:(UIBarButtonItem *)sender {
    if (self.selectedConversations.count == 0) {
        [self.view makeToast:WFCString(@"PleaseSelectConversation") duration:1 position:CSToastPositionCenter];
        return;
    }

    // 批量转发到所有选中的会话
    __weak typeof(self)ws = self;
    __block int successCount = 0;
    __block int failCount = 0;
    __block NSInteger totalCount = self.selectedConversations.count;

    [self.selectedConversations enumerateObjectsUsingBlock:^(WFCCConversation *conversation, NSUInteger idx, BOOL *stop) {
        [ws forwardMessages:conversation completion:^(BOOL success) {
            if (success) {
                successCount++;
            } else {
                failCount++;
            }

            if (successCount + failCount == totalCount) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failCount == 0) {
                        [ws.view makeToast:WFCString(@"ForwardSuccess") duration:1 position:CSToastPositionCenter];
                    } else if (successCount == 0) {
                        [ws.view makeToast:WFCString(@"ForwardFailure") duration:1 position:CSToastPositionCenter];
                    } else {
                        [ws.view makeToast:[NSString stringWithFormat:WFCString(@"PartialForwardSuccess"), successCount, totalCount] duration:1 position:CSToastPositionCenter];
                    }
                    [ws.navigationController dismissViewControllerAnimated:YES completion:nil];
                });
            }
        }];
    }];
}

- (void)forwardMessages:(WFCCConversation *)conversation completion:(void (^)(BOOL success))completion {
    WFCUShareMessageView *shareView = [WFCUShareMessageView createViewFromNib];
    shareView.conversation = conversation;
    if(!self.message && self.messages.count == 1) {
        shareView.message = [self.messages firstObject];
    } else {
        shareView.message = self.message;
        shareView.messages = self.messages;
    }
    shareView.forwardDone = ^(BOOL success) {
        if (completion) {
            completion(success);
        }
    };
    TYAlertController *alertController = [TYAlertController alertControllerWithAlertView:shareView preferredStyle:TYAlertControllerStyleAlert];
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

- (void)updateRightBarButtonItem {
    NSString *title = [NSString stringWithFormat:@"%@(%lu/%ld)", WFCString(@"Ok"), (unsigned long)self.selectedConversations.count, (long)self.maxSelectCount];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
    self.navigationItem.rightBarButtonItem.enabled = self.selectedConversations.count > 0;
}

- (BOOL)isConversationSelected:(WFCCConversation *)conversation {
    for (WFCCConversation *conv in self.selectedConversations) {
        if ([conv isEqual:conversation]) {
            return YES;
        }
    }
    return NO;
}

- (void)setMessage:(WFCCMessage *)message {
    if([message.content isKindOfClass:[WFCCArticlesMessageContent class]]) {
        WFCCArticlesMessageContent *articles = (WFCCArticlesMessageContent *)message.content;
        NSArray<WFCCLinkMessageContent *> *links = [articles toLinkMessageContent];
        if(links.count == 1) {
            WFCCMessage *msg = [message duplicate];
            msg.content = links[0];
            _message = msg;
        } else {
            NSMutableArray *msgs = [[NSMutableArray alloc] init];
            [links enumerateObjectsUsingBlock:^(WFCCLinkMessageContent * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                WFCCMessage *msg = [message duplicate];
                msg.content = obj;
                [msgs addObject:msg];
            }];
            _messages = msgs;
        }
    } else {
        _message = message;
    }
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
                [cell setUserId:self.searchFriendList[indexPath.row].userId groupId:nil];
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

            // 设置 checkbox 选中状态
            cell.isChecked = [self isConversationSelected:info.conversation];

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
                        if (![ws isConversationSelected:conversation]) {
                            if (ws.selectedConversations.count < ws.maxSelectCount) {
                                [ws.selectedConversations addObject:conversation];
                                [ws updateRightBarButtonItem];
                            } else {
                                [ws.view makeToast:[NSString stringWithFormat:WFCString(@"MaxSelectCount"), ws.maxSelectCount] duration:1 position:CSToastPositionCenter];
                                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                            }
                        }
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
        if (![self isConversationSelected:selectedConv]) {
            if (self.selectedConversations.count < self.maxSelectCount) {
                [self.selectedConversations addObject:selectedConv];
                [self updateRightBarButtonItem];

                // 刷新 cell 显示
                if (!self.searchController.isActive && indexPath.section != 0) {
                    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }
            } else {
                [self.view makeToast:[NSString stringWithFormat:WFCString(@"MaxSelectCount"), self.maxSelectCount] duration:1 position:CSToastPositionCenter];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCConversation *deselectedConv;
    if (self.searchController.isActive) {
        if (indexPath.section == 0 && self.searchFriendList.count > 0) {
            WFCCUserInfo *userInfo = self.searchFriendList[indexPath.row];
            deselectedConv = [[WFCCConversation alloc] init];
            deselectedConv.type = Single_Type;
            deselectedConv.target = userInfo.userId;
            deselectedConv.line = 0;
        } else {
            WFCCGroupInfo *groupInfo = self.searchGroupList[indexPath.row].groupInfo;
            deselectedConv = [[WFCCConversation alloc] init];
            deselectedConv.type = Group_Type;
            deselectedConv.target = groupInfo.target;
            deselectedConv.line = 0;
        }
    } else {
        if (indexPath.section != 0) {
            deselectedConv = self.conversations[indexPath.row].conversation;
        }
    }

    if (deselectedConv) {
        for (int i = 0; i < self.selectedConversations.count; i++) {
            WFCCConversation *conv = self.selectedConversations[i];
            if ([conv isEqual:deselectedConv]) {
                [self.selectedConversations removeObjectAtIndex:i];
                [self updateRightBarButtonItem];

                // 刷新 cell 显示
                if (!self.searchController.isActive && indexPath.section != 0) {
                    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }
                break;
            }
        }
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
