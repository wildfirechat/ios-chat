//
//  WFCUPanViewController.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/24.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCUPanViewController.h"
#import "WFCUPanFileListViewController.h"
#import "WFCUPanService.h"
#import "WFCUConfigManager.h"
#import "WFCUPanSpace.h"
#import "WFCUPanFile.h"
#import "WFCUImage.h"
#import <WFChatClient/WFCCIMService.h>

@interface WFCUPanSpaceCell : UITableViewCell
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@end

@implementation WFCUPanSpaceCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.iconView = [[UIImageView alloc] init];
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.iconView];
        
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = [UIFont systemFontOfSize:16];
        [self.contentView addSubview:self.nameLabel];
        
        self.infoLabel = [[UILabel alloc] init];
        self.infoLabel.font = [UIFont systemFontOfSize:12];
        self.infoLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:self.infoLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.iconView.frame = CGRectMake(15, 10, 40, 40);
    self.nameLabel.frame = CGRectMake(65, 10, self.bounds.size.width - 80, 22);
    self.infoLabel.frame = CGRectMake(65, 35, self.bounds.size.width - 80, 18);
}

@end

@interface WFCUPanViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<WFCUPanSpace *> *spaces;
@property (nonatomic, strong) UISegmentedControl *segmentControl;
@end

@implementation WFCUPanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    
    self.spaces = [NSMutableArray array];
    
    // 根据模式设置标题和UI
    [self setupUI];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[WFCUPanSpaceCell class] forCellReuseIdentifier:@"spaceCell"];
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:self.tableView];
    
    [self loadSpaces];
    
    // 监听空间更新通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadSpaces)
                                                 name:@"kPanSpaceDidUpdateNotification"
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kPanSpaceDidUpdateNotification" object:nil];
}

- (void)setupUI {
    switch (self.viewMode) {
        case WFCUPanViewModeMySpaces: {
            if (self.isMoveMode || self.isCopyMode) {
                self.title = WFCString(@"SelectDestination");
                [self updateRightBarButtonForMoveMode];
            } else {
                self.title = WFCString(@"MySpaces");
                // 添加操作按钮
                UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                         target:self
                                                                                         action:@selector(onAdd:)];
                self.navigationItem.rightBarButtonItem = addItem;
            }
            break;
        }
        case WFCUPanViewModeUserPublic:
            self.title = [NSString stringWithFormat:@"%@的网盘", self.targetUserName ?: @""];
            break;
            
        case WFCUPanViewModeAll:
        default: {
            // 添加空间类型切换（全局/部门/我的）
            self.segmentControl = [[UISegmentedControl alloc] initWithItems:@[WFCString(@"Global"), WFCString(@"Dept"), WFCString(@"My")]];
            self.segmentControl.selectedSegmentIndex = 0;
            [self.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            self.navigationItem.titleView = self.segmentControl;
            
            if (self.isMoveMode || self.isCopyMode) {
                // 移动/复制模式下显示取消和粘贴按钮
                [self updateRightBarButtonForMoveMode];
            } else {
                // 普通模式下显示上传按钮
                UIBarButtonItem *uploadItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                                            target:self 
                                                                                            action:@selector(onUpload:)];
                self.navigationItem.rightBarButtonItem = uploadItem;
            }
            break;
        }
    }
}

- (void)updateRightBarButtonForMoveMode {
    // 移动模式下显示取消和粘贴按钮
    // 在空间列表中，粘贴按钮禁用（因为还没有选择具体的空间目录）
    
    // 创建取消按钮
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(onCancelMove:)];
    
    // 创建粘贴按钮（禁用状态，因为空间列表不是具体目录）
    UIButton *pasteBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
    [pasteBtn setTitle:WFCString(@"Paste") forState:UIControlStateNormal];
    [pasteBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    pasteBtn.enabled = NO;
    
    UIBarButtonItem *pasteItem = [[UIBarButtonItem alloc] initWithCustomView:pasteBtn];
    
    // 同时显示取消和粘贴按钮（粘贴禁用）
    self.navigationItem.rightBarButtonItems = @[pasteItem, cancelItem];
}

- (void)onCancelMove:(id)sender {
    // 取消移动，返回到原始查看状态
    [self returnToOriginalView];
}

// 返回到原始查看状态
- (void)returnToOriginalView {
    NSArray *viewControllers = self.navigationController.viewControllers;
    for (UIViewController *vc in viewControllers) {
        if ([vc isKindOfClass:[WFCUPanFileListViewController class]]) {
            WFCUPanFileListViewController *fileListVC = (WFCUPanFileListViewController *)vc;
            if (!fileListVC.isMoveMode && !fileListVC.isCopyMode) {
                // 找到原始的文件列表页面（非移动/复制模式）
                [self.navigationController popToViewController:vc animated:YES];
                return;
            }
        }
    }
    // 如果没找到，返回到空间列表（非移动/复制模式）
    for (UIViewController *vc in viewControllers) {
        if ([vc isKindOfClass:[WFCUPanViewController class]]) {
            WFCUPanViewController *panVC = (WFCUPanViewController *)vc;
            if (!panVC.isMoveMode && !panVC.isCopyMode) {
                [self.navigationController popToViewController:vc animated:YES];
                return;
            }
        }
    }
    // 如果还没找到，直接pop到根
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadSpaces];
}

- (void)segmentChanged:(UISegmentedControl *)sender {
    [self loadSpaces];
}

- (void)loadSpaces {
    if (![WFCUConfigManager globalManager].panServiceProvider) {
        return;
    }
    
    if (self.viewMode == WFCUPanViewModeMySpaces) {
        // 加载我的空间（只加载我自己的两个空间）
        [self loadMySpaces];
    } else if (self.viewMode == WFCUPanViewModeUserPublic) {
        // 加载指定用户的公共空间
        [self loadUserPublicSpace];
    } else {
        // 加载所有空间（根据分段控件筛选）
        [self loadAllSpaces];
    }
}

- (void)loadMySpaces {
    // 调用 /api/v1/spaces/my 接口，只返回我的两个空间
    [[WFCUConfigManager globalManager].panServiceProvider getMySpacesWithSuccess:^(NSArray<WFCUPanSpace *> *spaces) {
        [self.spaces removeAllObjects];
        [self.spaces addObjectsFromArray:spaces];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } error:^(int errorCode, NSString *message) {
        NSLog(@"Load my spaces error: %d, %@", errorCode, message);
    }];
}

- (void)loadUserPublicSpace {
    // 调用 /api/v1/spaces/user/{userId}/public 接口
    [[WFCUConfigManager globalManager].panServiceProvider getUserPublicSpace:self.targetUserId 
                                                                     success:^(WFCUPanSpace *space) {
        [self.spaces removeAllObjects];
        if (space) {
            [self.spaces addObject:space];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } error:^(int errorCode, NSString *message) {
        NSLog(@"Load user public space error: %d, %@", errorCode, message);
    }];
}

- (void)loadAllSpaces {
    [[WFCUConfigManager globalManager].panServiceProvider getSpacesWithSuccess:^(NSArray<WFCUPanSpace *> *spaces) {
        [self.spaces removeAllObjects];
        
        NSInteger segmentIndex = self.segmentControl.selectedSegmentIndex;
        NSString *currentUserId = [WFCCNetworkService sharedInstance].userId;
        
        for (WFCUPanSpace *space in spaces) {
            if (segmentIndex == 0 && space.spaceType == WFCUPanSpaceTypeGlobalPublic) {
                [self.spaces addObject:space];
            } else if (segmentIndex == 1 && (space.spaceType == WFCUPanSpaceTypeDeptPublic || space.spaceType == WFCUPanSpaceTypeDeptPrivate)) {
                [self.spaces addObject:space];
            } else if (segmentIndex == 2 && (space.spaceType == WFCUPanSpaceTypeUserPublic || space.spaceType == WFCUPanSpaceTypeUserPrivate)) {
                // "我的"标签只显示当前用户自己的空间
                if ([space.ownerId isEqualToString:currentUserId]) {
                    [self.spaces addObject:space];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } error:^(int errorCode, NSString *message) {
        NSLog(@"Load spaces error: %d, %@", errorCode, message);
    }];
}

- (void)onAdd:(id)sender {
    // 我的空间模式下的添加操作
    [self showCreateFolderDialog];
}

- (void)onUpload:(id)sender {
    // 显示上传选项
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"Upload") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"CreateFolder") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showCreateFolderDialog];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"UploadFile") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showFilePicker];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showCreateFolderDialog {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"CreateFolder") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = WFCString(@"FolderName");
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Create") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *name = alert.textFields.firstObject.text;
        if (name.length > 0 && self.spaces.count > 0) {
            WFCUPanSpace *space = self.spaces.firstObject;
            [[WFCUConfigManager globalManager].panServiceProvider createFolder:space.spaceId parentId:0 name:name success:^(WFCUPanFile *file) {
                [self loadSpaces];
            } error:^(int errorCode, NSString *message) {
                NSLog(@"Create folder error: %d, %@", errorCode, message);
            }];
        }
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showFilePicker {
    // 简化实现，实际应该使用文档选择器
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"Tip") message:@"Please implement file picker" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.spaces.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUPanSpaceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"spaceCell" forIndexPath:indexPath];
    WFCUPanSpace *space = self.spaces[indexPath.row];
    
    cell.nameLabel.text = space.name;
    cell.infoLabel.text = [NSString stringWithFormat:@"%@: %lld/%lld MB", WFCString(@"Storage"), space.usedQuota / 1024 / 1024, space.totalQuota / 1024 / 1024];
    
    // 所有空间都显示 folder 图标
    cell.iconView.image = [WFCUImage imageNamed:@"file_folder"];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WFCUPanSpace *space = self.spaces[indexPath.row];
    WFCUPanFileListViewController *vc = [[WFCUPanFileListViewController alloc] init];
    vc.space = space;
    vc.parentId = 0;
    vc.hidesBottomBarWhenPushed = YES;
    
    // 如果是移动模式，传递移动状态
    if (self.isMoveMode) {
        vc.isMoveMode = YES;
        vc.fileToMove = self.fileToMove;
        vc.sourceSpace = self.sourceSpace;
        vc.sourceParentId = self.sourceParentId;
    }
    
    // 如果是复制模式，传递复制状态
    if (self.isCopyMode) {
        vc.isCopyMode = YES;
        vc.fileToCopy = self.fileToCopy;
        vc.sourceCopySpace = self.sourceCopySpace;
        vc.sourceCopyParentId = self.sourceCopyParentId;
    }
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

@end
