//
//  WFCUPanFilePickerViewController.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/25.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCUPanFilePickerViewController.h"
#import "WFCUPanService.h"
#import "WFCUPanSpace.h"
#import "WFCUConfigManager.h"
#import "WFCUImage.h"
#import "WFCUUtilities.h"
#import <WFChatClient/WFCChatClient.h>

@interface WFCUPanFilePickerCell : UITableViewCell
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UIImageView *checkImageView;
@end

@implementation WFCUPanFilePickerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 10, 40, 40)];
    [self.contentView addSubview:self.iconImageView];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 8, self.contentView.frame.size.width - 100, 20)];
    self.nameLabel.font = [UIFont systemFontOfSize:16];
    self.nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:self.nameLabel];
    
    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 30, self.contentView.frame.size.width - 100, 16)];
    self.infoLabel.font = [UIFont systemFontOfSize:12];
    self.infoLabel.textColor = [UIColor grayColor];
    self.infoLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:self.infoLabel];
    
    self.checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 40, 15, 24, 24)];
    self.checkImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.contentView addSubview:self.checkImageView];
}

@end

@interface WFCUPanFilePickerViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<WFCUPanSpace *> *spaces;
@property (nonatomic, strong) NSMutableArray<WFCUPanFile *> *files;
@property (nonatomic, strong) NSMutableArray<WFCUPanFile *> *selectedFiles;
@property (nonatomic, strong) WFCUPanSpace *currentSpace;
@property (nonatomic, assign) NSInteger currentParentId;
@property (nonatomic, strong) NSMutableArray *breadcrumbStack; // 存储空间或文件夹
@property (nonatomic, strong) UIBarButtonItem *sendButtonItem;
@end

@implementation WFCUPanFilePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.selectedFiles = [NSMutableArray array];
    self.breadcrumbStack = [NSMutableArray array];
    
    [self updateNavigationBar];
    [self setupTableView];
    
    [self loadMySpaces];
}

- (void)updateNavigationBar {
    // 更新标题
    if (self.currentSpace) {
        id lastObject = self.breadcrumbStack.lastObject;
        if ([lastObject isKindOfClass:[WFCUPanFile class]]) {
            // 在文件夹内
            WFCUPanFile *folder = lastObject;
            self.navigationItem.title = folder.name;
        } else {
            // 在空间根目录
            self.navigationItem.title = self.currentSpace.name;
        }
    } else {
        self.navigationItem.title = WFCString(@"Pan");
    }
    
    // 更新左侧按钮
    if (self.currentSpace) {
        UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
        [backBtn setTitle:WFCString(@"Back") forState:UIControlStateNormal];
        [backBtn setTitleColor:[WFCUConfigManager globalManager].textColor forState:UIControlStateNormal];
        [backBtn addTarget:self action:@selector(onBack:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    } else {
        UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
        [cancelBtn setTitle:WFCString(@"Cancel") forState:UIControlStateNormal];
        [cancelBtn setTitleColor:[WFCUConfigManager globalManager].textColor forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(onCancel:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cancelBtn];
    }
    
    // 更新右侧发送按钮
    [self updateSendButton];
}

- (void)updateSendButton {
    // 创建发送按钮
    UIButton *sendBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 44)];
    
    // 设置按钮文字
    NSString *title;
    if (self.selectedFiles.count > 0) {
        title = [NSString stringWithFormat:@"%@(%d)", WFCString(@"Send"), (int)self.selectedFiles.count];
    } else {
        title = WFCString(@"Send");
    }
    [sendBtn setTitle:title forState:UIControlStateNormal];
    
    // 根据是否有选中文件设置颜色和状态
    if (self.selectedFiles.count > 0) {
        [sendBtn setTitleColor:[UIColor colorWithRed:0.1 green:0.58 blue:0.9 alpha:1] forState:UIControlStateNormal];
        sendBtn.enabled = YES;
    } else {
        [sendBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        sendBtn.enabled = NO;
    }
    
    [sendBtn addTarget:self action:@selector(onConfirm:) forControlEvents:UIControlEventTouchUpInside];
    
    self.sendButtonItem = [[UIBarButtonItem alloc] initWithCustomView:sendBtn];
    self.navigationItem.rightBarButtonItem = self.sendButtonItem;
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.tableView registerClass:[WFCUPanFilePickerCell class] forCellReuseIdentifier:@"pickerCell"];
    [self.view addSubview:self.tableView];
}

#pragma mark - Data Loading
- (void)loadMySpaces {
    self.spaces = [NSMutableArray array];
    self.files = [NSMutableArray array];
    
    NSString *currentUserId = [WFCCNetworkService sharedInstance].userId;
    
    // 获取所有可访问的空间，筛选只显示我的空间和公共空间
    [[WFCUConfigManager globalManager].panServiceProvider getSpacesWithSuccess:^(NSArray<WFCUPanSpace *> *spaces) {
        NSMutableArray *publicSpaces = [NSMutableArray array];   // 公共空间
        NSMutableArray *mySpaces = [NSMutableArray array];       // 我的空间
        
        for (WFCUPanSpace *space in spaces) {
            // 公共空间（全局公共空间）
            if (space.spaceType == WFCUPanSpaceTypeGlobalPublic) {
                [publicSpaces addObject:space];
            }
            // 我的空间（公共+私有）
            else if ((space.spaceType == WFCUPanSpaceTypeUserPublic || 
                       space.spaceType == WFCUPanSpaceTypeUserPrivate) && 
                       [space.ownerId isEqualToString:currentUserId]) {
                [mySpaces addObject:space];
            }
        }
        
        // 公共空间排在最上面，然后是我的空间
        NSMutableArray *sortedSpaces = [NSMutableArray array];
        [sortedSpaces addObjectsFromArray:publicSpaces];
        [sortedSpaces addObjectsFromArray:mySpaces];
        
        self.spaces = sortedSpaces;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } error:^(int errorCode, NSString *message) {
        NSLog(@"Load spaces error: %d, %@", errorCode, message);
    }];
}

- (void)loadFilesInSpace:(WFCUPanSpace *)space parentId:(NSInteger)parentId {
    self.currentSpace = space;
    self.currentParentId = parentId;
    
    [[WFCUConfigManager globalManager].panServiceProvider getSpaceFiles:space.spaceId parentId:parentId success:^(NSArray<WFCUPanFile *> *files) {
        self.files = [files mutableCopy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } error:^(int errorCode, NSString *message) {
        NSLog(@"Load files error: %d, %@", errorCode, message);
    }];
}

#pragma mark - Actions
- (void)onCancel:(id)sender {
    if (self.cancelBlock) {
        self.cancelBlock();
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onBack:(id)sender {
    if (self.breadcrumbStack.count > 0) {
        [self.breadcrumbStack removeLastObject];
        if (self.breadcrumbStack.count == 0) {
            // 返回到空间列表
            self.currentSpace = nil;
            self.files = [NSMutableArray array];
            [self loadMySpaces];
        } else {
            // 返回到上级
            id parent = self.breadcrumbStack.lastObject;
            if ([parent isKindOfClass:[WFCUPanSpace class]]) {
                // 在空间根目录
                self.currentSpace = parent;
                [self loadFilesInSpace:self.currentSpace parentId:0];
            } else if ([parent isKindOfClass:[WFCUPanFile class]]) {
                // 在文件夹内
                WFCUPanFile *parentFolder = parent;
                [self loadFilesInSpace:self.currentSpace parentId:parentFolder.fileId];
            }
        }
    }
    [self updateNavigationBar];
    [self.tableView reloadData];
}

- (void)onConfirm:(id)sender {
    if (self.completionBlock && self.selectedFiles.count > 0) {
        self.completionBlock([self.selectedFiles copy]);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)isFileSelected:(WFCUPanFile *)file {
    for (WFCUPanFile *selectedFile in self.selectedFiles) {
        if (selectedFile.fileId == file.fileId) {
            return YES;
        }
    }
    return NO;
}

- (void)toggleFileSelection:(WFCUPanFile *)file {
    BOOL isSelected = [self isFileSelected:file];
    if (isSelected) {
        // 取消选择
        for (NSInteger i = 0; i < self.selectedFiles.count; i++) {
            if (self.selectedFiles[i].fileId == file.fileId) {
                [self.selectedFiles removeObjectAtIndex:i];
                break;
            }
        }
    } else {
        // 添加选择
        if (self.selectedFiles.count >= 9) {
            // 最多选择9个文件
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:WFCString(@"MaxFilesSelected") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        [self.selectedFiles addObject:file];
    }
    [self updateSendButton];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.currentSpace) {
        return 1;
    }
    return self.spaces.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.currentSpace) {
        return self.files.count;
    }
    return 1; // 每个空间一个cell
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUPanFilePickerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pickerCell" forIndexPath:indexPath];
    
    if (self.currentSpace) {
        // 显示文件列表
        WFCUPanFile *file = self.files[indexPath.row];
        cell.nameLabel.text = file.name;
        
        if (file.type == WFCUPanFileTypeFolder) {
            cell.iconImageView.image = [WFCUImage imageNamed:@"chat_input_plugin_file"];
            cell.infoLabel.text = [NSString stringWithFormat:WFCString(@"FolderItemCount"), (int)file.childCount];
            cell.checkImageView.hidden = YES;
        } else {
            NSString *ext = [file.name pathExtension];
            cell.iconImageView.image = [WFCUUtilities imageForExt:ext];
            double size = file.size / 1024.0 / 1024.0;
            cell.infoLabel.text = [NSString stringWithFormat:@"%.2f MB", size];
            
            // 显示选择状态
            cell.checkImageView.hidden = NO;
            BOOL isSelected = [self isFileSelected:file];
            cell.checkImageView.image = [WFCUImage imageNamed:isSelected ? @"multi_selected" : @"multi_unselected"];
        }
    } else {
        // 显示空间列表
        WFCUPanSpace *space = self.spaces[indexPath.section];
        cell.nameLabel.text = space.name;
        cell.iconImageView.image = [WFCUImage imageNamed:@"chat_input_plugin_file"];
        cell.infoLabel.text = nil;
        cell.checkImageView.hidden = YES;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.currentSpace) {
        WFCUPanFile *file = self.files[indexPath.row];
        if (file.type == WFCUPanFileTypeFolder) {
            // 进入文件夹
            [self.breadcrumbStack addObject:file];
            [self loadFilesInSpace:self.currentSpace parentId:file.fileId];
            [self updateNavigationBar];
        } else {
            // 选择/取消选择文件
            [self toggleFileSelection:file];
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    } else {
        // 进入空间
        WFCUPanSpace *space = self.spaces[indexPath.section];
        [self.breadcrumbStack addObject:space];
        [self loadFilesInSpace:space parentId:0];
        [self updateNavigationBar];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.currentSpace) {
        return nil;
    }
    WFCUPanSpace *space = self.spaces[section];
    return space.name;
}

@end
