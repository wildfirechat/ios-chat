//
//  WFPttListViewController.m
//  PttUIKit
//
//  Created by Hao Jia on 2021/10/14.
//

#ifdef WFC_PTT
#import "WFPttChannelListViewController.h"
#import <PttClient/WFPttClient.h>
#import "WFPttCreateChannelViewController.h"
#import "WFPttJoinChannelViewController.h"
#import "WFPttChannelViewController.h"
#import <WFChatClient/WFCChatClient.h>

@interface WFPttChannelListViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSArray *items;
@end

@implementation WFPttChannelListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"+" style:UIBarButtonItemStyleDone target:self action:@selector(onAddBtn:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSettingUpdated:) name:kSettingUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTalkingBegain:) name:kWFPttTalkingBegainNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTalkingEnd:) name:kWFPttTalkingEndNotification object:nil];
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    [self loadData];
}

- (void)onSettingUpdated:(NSNotification *)notification {
    [self loadData];
}

- (void)onTalkingBegain:(NSNotification *)notification {
    [self loadData];
}

- (void)onTalkingEnd:(NSNotification *)notification {
    [self loadData];
}

- (void)loadData {
    self.items = [[WFPttClient sharedClient] getSubscribedChannels].reverseObjectEnumerator.allObjects;
    [self.tableView reloadData];
}

- (void)onAddBtn:(id)sender {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    __weak typeof(self)ws = self;
    
    UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"创建频道" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        WFPttCreateChannelViewController *vc = [[WFPttCreateChannelViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [ws.navigationController presentViewController:nav animated:YES completion:nil];
    }];
    
    UIAlertAction *joinAction = [UIAlertAction actionWithTitle:@"加入频道" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        WFPttJoinChannelViewController *vc = [[WFPttJoinChannelViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [ws.navigationController presentViewController:nav animated:YES completion:nil];
    }];
    
    [actionSheet addAction:createAction];
    [actionSheet addAction:joinAction];
    [actionSheet addAction:actionCancel];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [self loadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    NSString *channelId = self.items[indexPath.row];
    WFPttChannelInfo *channelInfo = [[WFPttClient sharedClient] getChannelInfo:channelId];
    NSString *text = channelInfo.name.length ? channelInfo.name : @"频道";
    
    NSDictionary<NSString *, NSNumber *> *talkingMembers = [[WFPttClient sharedClient] getTalkingMember:channelId];
    NSArray *keys = talkingMembers.allKeys;
    for (int i = 0; i < talkingMembers.count; i++) {
        NSString *key = keys[i];
        WFCCUserInfo *talkingUser = [[WFCCIMService sharedWFCIMService] getUserInfo:key refresh:NO];
        if(i) {
            text = [text stringByAppendingString:@","];
        } else {
            text = [text stringByAppendingString:@"    "];
        }
        text = [text stringByAppendingString:talkingUser.displayName];
    }
    cell.textLabel.text = text;
    return cell;
}
#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFPttChannelViewController *vc = [[WFPttChannelViewController alloc] init];
    vc.channelId = self.items[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
-(NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *channelId = self.items[indexPath.row];
    NSString *owner = [[WFPttClient sharedClient] getChannelOwner:channelId];
    
    UITableViewRowAction *action;
    if([[WFCCNetworkService sharedInstance].userId isEqualToString:owner]) {
        action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            [[WFPttClient sharedClient] destroyChannel:channelId success:nil error:nil];
        }];
    } else {
        action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"退出" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            [[WFPttClient sharedClient] leaveChanel:channelId success:nil error:nil];
           }];
    }
    
    action.backgroundColor = [UIColor redColor];
    
    return @[action];
}
@end
#endif //WFC_PTT
