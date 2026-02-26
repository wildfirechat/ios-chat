//
//  WFCUPanFileListViewController.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/24.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCUPanFileListViewController.h"
#import "WFCUPanService.h"
#import "WFCUConfigManager.h"
#import "WFCUPanFile.h"
#import "WFCUImage.h"
#import "WFCUPanUploadManager.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "MBProgressHUD.h"

@interface WFCUPanFileCell : UITableViewCell
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@end

@implementation WFCUPanFileCell

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

@interface WFCUPanFileListViewController () <UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<WFCUPanFile *> *files;
@end

@implementation WFCUPanFileListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.space.name;
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    
    self.files = [NSMutableArray array];
    
    // 更新导航栏按钮
    [self updateRightBarButton];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[WFCUPanFileCell class] forCellReuseIdentifier:@"fileCell"];
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:self.tableView];
    
    // 添加长按手势
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.5;
    [self.tableView addGestureRecognizer:longPress];
    
    [self loadFiles];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadFiles];
}

- (void)loadFiles {
    if (![WFCUConfigManager globalManager].panServiceProvider) {
        return;
    }
    
    [[WFCUConfigManager globalManager].panServiceProvider getSpaceFiles:self.space.spaceId parentId:self.parentId success:^(NSArray<WFCUPanFile *> *files) {
        [self.files removeAllObjects];
        [self.files addObjectsFromArray:files];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } error:^(int errorCode, NSString *message) {
        NSLog(@"Load files error: %d, %@", errorCode, message);
    }];
}

#pragma mark - Long Press Menu

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    
    CGPoint point = [gesture locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
    if (indexPath && indexPath.row < self.files.count) {
        WFCUPanFile *file = self.files[indexPath.row];
        [self showActionMenuForFile:file atIndexPath:indexPath];
    }
}

- (void)showActionMenuForFile:(WFCUPanFile *)file atIndexPath:(NSIndexPath *)indexPath {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:file.name message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (self.space.canManage) {
        // 有写权限：显示完整菜单（分享、移动、复制、删除）
        
        // 分享 - 只有文件可以分享
        if (file.type == WFCUPanFileTypeFile) {
            [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Share") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self shareFile:file];
            }]];
        }
        
        // 移动
        [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Move") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self startMoveFile:file];
        }]];
        
        // 复制（跨空间复制）
        [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Copy") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self startCopyFile:file];
        }]];
        
        // 删除
        [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self deleteFile:file atIndexPath:indexPath];
        }]];
        
    } else {
        // 无写权限：只显示转存
        [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Duplicate") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self duplicateFile:file];
        }]];
    }
    
    // 取消
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

/**
 * 更新导航栏右侧按钮
 * 普通模式显示+按钮，移动/复制模式显示取消和粘贴按钮
 */
- (void)updateRightBarButton {
    if (self.isMoveMode) {
        // 判断是否是原文件夹（同一空间且同一父目录）
        BOOL isSameLocation = (self.space.spaceId == self.sourceSpace.spaceId && self.parentId == self.sourceParentId);
        
        // 创建取消按钮
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(onCancelMove:)];
        
        // 创建粘贴按钮
        UIButton *pasteBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
        [pasteBtn setTitle:WFCString(@"Paste") forState:UIControlStateNormal];
        
        if (isSameLocation) {
            // 在原文件夹，按钮灰色不可点
            [pasteBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            pasteBtn.enabled = NO;
        } else {
            // 在其他位置，按钮可点击
            [pasteBtn setTitleColor:[WFCUConfigManager globalManager].textColor forState:UIControlStateNormal];
            pasteBtn.enabled = YES;
            [pasteBtn addTarget:self action:@selector(onPaste:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        UIBarButtonItem *pasteItem = [[UIBarButtonItem alloc] initWithCustomView:pasteBtn];
        
        // 同时显示取消和粘贴按钮
        self.navigationItem.rightBarButtonItems = @[pasteItem, cancelItem];
    } else if (self.isCopyMode) {
        // 复制模式：判断是否是原文件夹（同一空间且同一父目录）
        BOOL isSameLocation = (self.space.spaceId == self.sourceCopySpace.spaceId && self.parentId == self.sourceCopyParentId);
        
        // 创建取消按钮
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(onCancelCopy:)];
        
        // 创建粘贴按钮
        UIButton *pasteBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
        [pasteBtn setTitle:WFCString(@"Paste") forState:UIControlStateNormal];
        
        if (isSameLocation) {
            // 在原文件夹，按钮灰色不可点
            [pasteBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            pasteBtn.enabled = NO;
        } else {
            // 在其他位置，按钮可点击
            [pasteBtn setTitleColor:[WFCUConfigManager globalManager].textColor forState:UIControlStateNormal];
            pasteBtn.enabled = YES;
            [pasteBtn addTarget:self action:@selector(onCopyPaste:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        UIBarButtonItem *pasteItem = [[UIBarButtonItem alloc] initWithCustomView:pasteBtn];
        
        // 同时显示取消和粘贴按钮
        self.navigationItem.rightBarButtonItems = @[pasteItem, cancelItem];
    } else {
        // 普通模式，只有进入其他人的公共空间时不显示+按钮
        self.navigationItem.rightBarButtonItems = nil;
        if ([self shouldShowAddButton]) {
            UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAdd:)];
            self.navigationItem.rightBarButtonItem = addItem;
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
    }
}

- (void)onCancelMove:(id)sender {
    // 取消移动，返回到原始查看状态（非移动模式的文件列表）
    [self returnToOriginalView];
}

- (void)onCancelCopy:(id)sender {
    // 取消复制，返回到原始查看状态
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
    // 如果没找到原始文件列表，尝试返回到空间列表（非移动/复制模式）
    for (UIViewController *vc in viewControllers) {
        if ([vc isKindOfClass:[WFCUPanViewController class]]) {
            WFCUPanViewController *panVC = (WFCUPanViewController *)vc;
            if (!panVC.isMoveMode) {
                [self.navigationController popToViewController:vc animated:YES];
                return;
            }
        }
    }
    // 如果还没找到，直接pop到根
    [self.navigationController popToRootViewControllerAnimated:YES];
}

/**
 * 判断是否显示+按钮
 * 只有进入其他人的公共空间时不显示，其他情况都显示
 */
- (BOOL)shouldShowAddButton {
    NSString *currentUserId = [WFCCNetworkService sharedInstance].userId;
    
    if (self.space.spaceType == WFCUPanSpaceTypeUserPublic) {
        if (![self.space.ownerId isEqualToString:currentUserId]) {
            return NO;
        }
    }
    
    return YES;
}

- (void)onPaste:(id)sender {
    // 检查是否有权限写入目标空间
    [[WFCUConfigManager globalManager].panServiceProvider checkSpaceWritePermission:self.space.spaceId success:^(BOOL hasPermission) {
        if (hasPermission) {
            [self executeMove];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:WFCString(@"NoPermission") preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:WFCString(@"CheckPermissionFailed") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }];
}

- (void)executeMove {
    if (!self.fileToMove) return;
    
    [[WFCUConfigManager globalManager].panServiceProvider moveFile:self.fileToMove.fileId toSpace:self.space.spaceId parentId:self.parentId success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // 移动成功，返回到原始查看状态
            [self returnToOriginalView];
        });
    } error:^(int errorCode, NSString *message) {
        NSLog(@"Move file error: %d, %@", errorCode, message);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *errorMsg = message ?: @"操作失败";
            if (errorCode == 403 || [errorMsg containsString:@"权限"]) {
                errorMsg = @"没有权限执行此操作";
            } else if ([errorMsg containsString:@"循环"] || [errorMsg containsString:@"自身"]) {
                errorMsg = @"不能将文件夹移动到自身或其子目录内";
            }
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"提示" message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
            [errorAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:errorAlert animated:YES completion:nil];
        });
    }];
}

- (void)onCopyPaste:(id)sender {
    // 检查是否有权限写入目标空间
    [[WFCUConfigManager globalManager].panServiceProvider checkSpaceWritePermission:self.space.spaceId success:^(BOOL hasPermission) {
        if (hasPermission) {
            [self executeCopy];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:WFCString(@"NoPermission") preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:WFCString(@"CheckPermissionFailed") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }];
}

- (void)executeCopy {
    if (!self.fileToCopy) return;
    
    [[WFCUConfigManager globalManager].panServiceProvider copyFile:self.fileToCopy.fileId toSpace:self.space.spaceId parentId:self.parentId success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // 复制成功，返回到原始查看状态
            [self returnToOriginalView];
        });
    } error:^(int errorCode, NSString *message) {
        NSLog(@"Copy file error: %d, %@", errorCode, message);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *errorMsg = message ?: @"操作失败";
            if (errorCode == 403 || [errorMsg containsString:@"权限"]) {
                errorMsg = @"没有权限执行此操作";
            } else if ([errorMsg containsString:@"容量"]) {
                errorMsg = @"目标空间容量不足";
            }
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"提示" message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
            [errorAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:errorAlert animated:YES completion:nil];
        });
    }];
}

- (void)onAdd:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"Add") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"CreateFolder") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showCreateFolderDialog];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"UploadFile") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showUploadDialog];
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
        if (name.length > 0) {
            [[WFCUConfigManager globalManager].panServiceProvider createFolder:self.space.spaceId parentId:self.parentId name:name success:^(WFCUPanFile *file) {
                [self loadFiles];
            } error:^(int errorCode, NSString *message) {
                NSLog(@"Create folder error: %d, %@", errorCode, message);
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *errorMsg = message ?: @"操作失败";
                    if (errorCode == 403 || [errorMsg containsString:@"权限"]) {
                        errorMsg = @"没有权限执行此操作";
                    }
                    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"提示" message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
                    [errorAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:errorAlert animated:YES completion:nil];
                });
            }];
        }
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showUploadDialog {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"CheckingPermission");
    
    __weak typeof(self) weakSelf = self;
    [[WFCUConfigManager globalManager].panServiceProvider checkUploadPermission:self.space.spaceId success:^(BOOL canUpload) {
        [hud hideAnimated:YES];
        if (canUpload) {
            [weakSelf showFilePicker];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"Tip") message:WFCString(@"NoPermission") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        }
    } error:^(int errorCode, NSString *message) {
        [hud hideAnimated:YES];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"Tip") message:WFCString(@"CheckPermissionFailed") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
        [weakSelf presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)showFilePicker {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data"] inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - Move/Share/Duplicate

- (void)startMoveFile:(WFCUPanFile *)file {
    // 进入全局空间列表选择目标，支持跨空间移动
    // 可以从全局公共空间、部门空间、我的空间中选择
    WFCUPanViewController *vc = [[WFCUPanViewController alloc] init];
    vc.viewMode = WFCUPanViewModeAll; // 显示所有空间（全局/部门/我的）
    vc.isMoveMode = YES;
    vc.fileToMove = file;
    vc.sourceSpace = self.space;
    vc.sourceParentId = self.parentId;
    vc.title = WFCString(@"SelectDestination");
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)startCopyFile:(WFCUPanFile *)file {
    // 进入全局空间列表选择目标，支持跨空间复制
    // 可以从全局公共空间、部门空间、我的空间中选择
    WFCUPanViewController *vc = [[WFCUPanViewController alloc] init];
    vc.viewMode = WFCUPanViewModeAll; // 显示所有空间（全局/部门/我的）
    vc.isCopyMode = YES;
    vc.fileToCopy = file;
    vc.sourceCopySpace = self.space;
    vc.sourceCopyParentId = self.parentId;
    vc.title = WFCString(@"SelectDestination");
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)shareFile:(WFCUPanFile *)file {
    WFCCFileMessageContent *content = [[WFCCFileMessageContent alloc] init];
    content.name = file.name;
    content.size = (NSUInteger)file.size;
    content.remoteUrl = file.storageUrl;
    
    WFCCMessage *message = [[WFCCMessage alloc] init];
    message.content = content;
    
    WFCUForwardViewController *vc = [[WFCUForwardViewController alloc] init];
    vc.message = message;
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navi animated:YES completion:nil];
}

- (void)duplicateFile:(WFCUPanFile *)file {
    [[WFCUConfigManager globalManager].panServiceProvider getMySpacesWithSuccess:^(NSArray<WFCUPanSpace *> *spaces) {
        WFCUPanSpace *myPublicSpace = nil;
        WFCUPanSpace *myPrivateSpace = nil;
        
        for (WFCUPanSpace *space in spaces) {
            if (space.spaceType == WFCUPanSpaceTypeUserPublic) {
                myPublicSpace = space;
            } else if (space.spaceType == WFCUPanSpaceTypeUserPrivate) {
                myPrivateSpace = space;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"DuplicateTo") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            if (myPublicSpace) {
                [alert addAction:[UIAlertAction actionWithTitle:myPublicSpace.name style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self doDuplicate:file toSpace:myPublicSpace];
                }]];
            }
            
            if (myPrivateSpace) {
                [alert addAction:[UIAlertAction actionWithTitle:myPrivateSpace.name style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self doDuplicate:file toSpace:myPrivateSpace];
                }]];
            }
            
            [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
        });
    } error:^(int errorCode, NSString *message) {
        NSLog(@"Get my spaces error: %d, %@", errorCode, message);
    }];
}

- (void)doDuplicate:(WFCUPanFile *)file toSpace:(WFCUPanSpace *)space {
    [[WFCUConfigManager globalManager].panServiceProvider duplicateFile:file.fileId toSpace:space.spaceId parentId:0 success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:WFCString(@"DuplicateSuccess") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kPanSpaceDidUpdateNotification" object:nil];
        });
    } error:^(int errorCode, NSString *message) {
        NSLog(@"Duplicate file error: %d, %@", errorCode, message);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *errorMsg = message ?: @"操作失败";
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count == 0) return;
    
    NSURL *fileURL = urls.firstObject;
    NSString *filePath = fileURL.path;
    NSString *fileName = fileURL.lastPathComponent;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Uploading");
    hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    
    __weak typeof(self) weakSelf = self;
    [[WFCUPanUploadManager sharedManager] uploadFile:filePath progress:^(CGFloat progress) {
        hud.progress = progress;
    } success:^(NSString *storageUrl, int64_t size, NSString *md5) {
        NSString *mimeType = [[WFCUPanUploadManager sharedManager] mimeTypeForFile:filePath];
        [[WFCUConfigManager globalManager].panServiceProvider createFile:self.space.spaceId 
                                                                parentId:weakSelf.parentId 
                                                                    name:fileName 
                                                                    size:size 
                                                                mimeType:mimeType 
                                                                     md5:md5 
                                                              storageUrl:storageUrl 
                                                                 success:^(WFCUPanFile *file) {
            [hud hideAnimated:YES];
            [weakSelf loadFiles];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kPanSpaceDidUpdateNotification" object:nil];
        } error:^(int errorCode, NSString *message) {
            [hud hideAnimated:YES];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"Tip") message:WFCString(@"CreateFileRecordFailed") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        }];
    } error:^(NSString *errorMessage) {
        [hud hideAnimated:YES];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"Tip") message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
        [weakSelf presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUPanFileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fileCell" forIndexPath:indexPath];
    WFCUPanFile *file = self.files[indexPath.row];
    
    cell.nameLabel.text = file.name;
    
    if (file.type == WFCUPanFileTypeFolder) {
        cell.iconView.image = [WFCUImage imageNamed:@"file_folder"];
        cell.infoLabel.text = [NSString stringWithFormat:@"%@: %ld", WFCString(@"Items"), (long)file.childCount];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        NSString *ext = [[file.name pathExtension] lowercaseString];
        cell.iconView.image = [WFCUUtilities imageForExt:ext];
        double size = file.size / 1024.0 / 1024.0;
        cell.infoLabel.text = [NSString stringWithFormat:@"%.2f MB", size];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WFCUPanFile *file = self.files[indexPath.row];
    
    if (file.type == WFCUPanFileTypeFolder) {
        // 移动模式下，不能打开正在移动的文件夹本身（防止循环引用）
        if (self.isMoveMode && self.fileToMove && self.fileToMove.type == WFCUPanFileTypeFolder && file.fileId == self.fileToMove.fileId) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:WFCString(@"CannotMoveToSelf") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        // 复制模式下，不能打开正在复制的文件夹本身（与移动类似）
        if (self.isCopyMode && self.fileToCopy && self.fileToCopy.type == WFCUPanFileTypeFolder && file.fileId == self.fileToCopy.fileId) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:WFCString(@"CannotCopyToSelf") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        WFCUPanFileListViewController *vc = [[WFCUPanFileListViewController alloc] init];
        vc.space = self.space;
        vc.parentId = file.fileId;
        vc.title = file.name;
        
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
    } else {
        [[WFCUConfigManager globalManager].panServiceProvider getFileDownloadUrl:file.fileId success:^(NSString *url) {
            NSLog(@"Download URL: %@", url);
            if (url.length > 0) {
                NSURL *fileURL = [NSURL URLWithString:url];
                if (fileURL) {
                    [[UIApplication sharedApplication] openURL:fileURL options:@{} completionHandler:^(BOOL success) {
                        if (!success) {
                            NSLog(@"无法打开URL: %@", url);
                        }
                    }];
                }
            }
        } error:^(int errorCode, NSString *message) {
            NSLog(@"Get download URL error: %d, %@", errorCode, message);
        }];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // 所有行都可以滑动，显示操作菜单
    // 有权限时显示完整菜单（分享、移动、删除）
    // 无权限时只显示复制菜单
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WFCUPanFile *file = self.files[indexPath.row];
        [[WFCUConfigManager globalManager].panServiceProvider deleteFile:file.fileId success:^{
            [self.files removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kPanSpaceDidUpdateNotification" object:nil];
        } error:^(int errorCode, NSString *message) {
            NSLog(@"Delete file error: %d, %@", errorCode, message);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *errorMsg = message ?: @"操作失败";
                if (errorCode == 403 || [errorMsg containsString:@"权限"]) {
                    errorMsg = @"没有权限执行此操作";
                }
                UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"提示" message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
                [errorAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:errorAlert animated:YES completion:nil];
            });
        }];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0)) {
    WFCUPanFile *file = self.files[indexPath.row];
    return [self createSwipeActionsForFile:file atIndexPath:indexPath];
}

- (UISwipeActionsConfiguration *)createSwipeActionsForFile:(WFCUPanFile *)file atIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0)) {
    NSMutableArray<UIContextualAction *> *actions = [NSMutableArray array];
    
    if (self.space.canManage) {
        // 有写权限：显示完整菜单（分享、移动、复制、删除）
        
        // 分享按钮 - 只有文件可以分享
        if (file.type == WFCUPanFileTypeFile) {
            UIContextualAction *shareAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:WFCString(@"Share") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                [self shareFile:file];
                completionHandler(YES);
            }];
            shareAction.backgroundColor = [UIColor colorWithRed:0.1 green:0.58 blue:0.9 alpha:1];
            [actions addObject:shareAction];
        }
        
        // 移动按钮
        UIContextualAction *moveAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:WFCString(@"Move") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self startMoveFile:file];
            completionHandler(YES);
        }];
        moveAction.backgroundColor = [UIColor colorWithRed:0.3 green:0.6 blue:0.3 alpha:1];
        [actions addObject:moveAction];
        
        // 复制按钮（跨空间复制）
        UIContextualAction *copyAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:WFCString(@"Copy") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self startCopyFile:file];
            completionHandler(YES);
        }];
        copyAction.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.8 alpha:1];
        [actions addObject:copyAction];
        
        // 删除按钮
        UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:WFCString(@"Delete") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self deleteFile:file atIndexPath:indexPath];
            completionHandler(YES);
        }];
        [actions addObject:deleteAction];
        
    } else {
        // 无写权限：只显示复制按钮
        UIContextualAction *copyAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:WFCString(@"Duplicate") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self duplicateFile:file];
            completionHandler(YES);
        }];
        copyAction.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
        [actions addObject:copyAction];
    }
    
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:actions];
    config.performsFirstActionWithFullSwipe = NO;
    return config;
}

- (void)deleteFile:(WFCUPanFile *)file atIndexPath:(NSIndexPath *)indexPath {
    [[WFCUConfigManager globalManager].panServiceProvider deleteFile:file.fileId success:^{
        [self.files removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kPanSpaceDidUpdateNotification" object:nil];
    } error:^(int errorCode, NSString *message) {
        NSLog(@"Delete file error: %d, %@", errorCode, message);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *errorMsg = message ?: @"操作失败";
            if (errorCode == 403 || [errorMsg containsString:@"权限"]) {
                errorMsg = @"没有权限执行此操作";
            }
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"提示" message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
            [errorAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:errorAlert animated:YES completion:nil];
        });
    }];
}

@end
