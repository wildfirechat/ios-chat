//
//  WFCUPanGroupPickerViewController.m
//  WFChatUIKit
//

#import "WFCUPanGroupPickerViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUConfigManager.h"
#import "WFCUImage.h"
#import "UIFont+YH.h"
#import "UIView+Toast.h"

@interface WFCUPanGroupPickerViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<WFCCGroupInfo *> *groups;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedGroupIds;
@end

@implementation WFCUPanGroupPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = WFCString(@"SelectGroup");
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.groups = [NSMutableArray array];
    self.selectedGroupIds = [NSMutableSet set];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(onCancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"OK") style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    [self loadGroups];
}

- (void)loadGroups {
    __weak typeof(self) ws = self;
    [[WFCCIMService sharedWFCIMService] getMyGroups:^(NSArray<NSString *> *groupIds) {
        NSArray<WFCCGroupInfo *> *infos = [[WFCCIMService sharedWFCIMService] getGroupInfos:groupIds refresh:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws.groups removeAllObjects];
            if (infos.count) {
                [ws.groups addObjectsFromArray:infos];
            }
            [ws.tableView reloadData];
        });
    } error:^(int error_code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws.view makeToast:WFCString(@"NetworkError") duration:1 position:CSToastPositionCenter];
        });
    }];
}

- (void)onCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onDone:(id)sender {
    if (self.selectedGroupIds.count == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    NSMutableArray<WFCCGroupInfo *> *picked = [NSMutableArray array];
    for (WFCCGroupInfo *group in self.groups) {
        if ([self.selectedGroupIds containsObject:group.target]) {
            [picked addObject:group];
        }
    }
    void (^result)(NSArray<WFCCGroupInfo *> *) = self.selectResult;
    [self dismissViewControllerAnimated:YES completion:^{
        if (result) {
            result(picked);
        }
    }];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"groupCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    WFCCGroupInfo *group = self.groups[indexPath.row];
    cell.textLabel.text = group.displayName.length ? group.displayName : group.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %lu", WFCString(@"Items"), (unsigned long)group.memberCount];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.imageView.image = [WFCUImage imageNamed:@"file_folder"];
    cell.accessoryType = [self.selectedGroupIds containsObject:group.target] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    WFCCGroupInfo *group = self.groups[indexPath.row];
    if ([self.selectedGroupIds containsObject:group.target]) {
        [self.selectedGroupIds removeObject:group.target];
    } else {
        [self.selectedGroupIds addObject:group.target];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
