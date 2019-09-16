//
//  SelectFileViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUSelectFileViewController.h"
#import "WFCUSelectedFileCollectionViewCell.h"

#define DocumentPath [NSString stringWithFormat:@"%@",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]]


@interface WFCUSelectFileViewController ()<UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>
@property (strong ,nonatomic)UICollectionView *fileCV;
@property (strong ,nonatomic)NSMutableArray *fileArray;
@property (strong ,nonatomic)NSMutableArray *selectedFiles;
@property (nonatomic, strong)NSString *currentPath;
@property (nonatomic, strong)NSString *documentPath;
@end

@implementation WFCUSelectFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(onCancel:)];
    self.navigationItem.leftBarButtonItem = cancel;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    flowLayout.itemSize = CGSizeMake(144, 144);
    self.fileCV = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-60) collectionViewLayout:flowLayout];
    [self.view addSubview:self.fileCV];
    
    [self.fileCV registerClass:[WFCUSelectedFileCollectionViewCell class] forCellWithReuseIdentifier:@"fileCellID"];
    self.fileCV.delegate = self;
    self.fileCV.dataSource = self;
    self.fileCV.backgroundColor = [UIColor whiteColor];
    
    self.documentPath = DocumentPath;
    self.currentPath = self.documentPath;
    
    [self loadDatas];
}

- (void)updateRightButton {
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"确定(%d/10)", (int)self.selectedFiles.count] style:UIBarButtonItemStyleDone target:self action:@selector(onSelect:)];
    if (self.selectedFiles.count == 0) {
        rightItem.enabled = NO;
    }
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)onCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onSelect:(id)sender {
    if (self.selectResult) {
        self.selectResult(self.selectedFiles);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)loadDatas {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    self.fileArray = [[NSMutableArray alloc]initWithArray:[fileManager contentsOfDirectoryAtPath:self.currentPath error:nil]];
    NSLog(@"%@",self.fileArray);
    
    if (![self.currentPath isEqualToString:self.documentPath]) {
        NSMutableArray *tmp = [self.fileArray mutableCopy];
        [tmp insertObject:@".." atIndex:0];
        self.fileArray = tmp;
    }

    [self.fileCV reloadData];
    [self updateRightButton];
    self.title = [self.currentPath lastPathComponent];
}

- (NSMutableArray *)selectedFiles {
    if (!_selectedFiles) {
        _selectedFiles = [NSMutableArray array];
    }
    return _selectedFiles;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    WFCUSelectedFileCollectionViewCell *fileCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"fileCellID" forIndexPath:indexPath];
    fileCell.fileNameLbl.text = self.fileArray[indexPath.row];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fileManager fileExistsAtPath:[self.currentPath stringByAppendingPathComponent:self.fileArray[indexPath.row]] isDirectory:&isDir]) {
        isDir = NO;
    }
    
    if (isDir) {
        fileCell.backIV.image = [UIImage imageNamed:@"dir_icon"];
        fileCell.selectIV.hidden = YES;
    } else {
        fileCell.backIV.image = [UIImage imageNamed:@"file_icon"];
        fileCell.selectIV.hidden = NO;
        
        NSString *fullPath = [self.currentPath stringByAppendingPathComponent:self.fileArray[indexPath.row]];
        if (![self.selectedFiles containsObject:fullPath]) {
            fileCell.selectIV.image = [UIImage imageNamed:@"multi_unselected"];
        }else{
            fileCell.selectIV.image = [UIImage imageNamed:@"multi_selected"];
        }
        
    }
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressAction:)];
    [fileCell.contentView addGestureRecognizer:longPress];
    
    return fileCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.fileArray[indexPath.row] isEqualToString:@".."]) {
        self.currentPath = [self.currentPath stringByDeletingLastPathComponent];
    } else {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = NO;
        if (![fileManager fileExistsAtPath:[self.currentPath stringByAppendingPathComponent:self.fileArray[indexPath.row]] isDirectory:&isDir]) {
            isDir = NO;
        }
        
        if (isDir) {
            self.currentPath =[self.currentPath stringByAppendingPathComponent:self.fileArray[indexPath.row]];
        } else {
            NSString *fullPath = [self.currentPath stringByAppendingPathComponent:self.fileArray[indexPath.row]];
            if ([self.selectedFiles containsObject:fullPath]) {
                [self.selectedFiles removeObject:fullPath];
            } else {
                [self.selectedFiles addObject:fullPath];
            }
        }
    }
    [self loadDatas];
}

- (void)longPressAction:(UILongPressGestureRecognizer *)longPress {
    __weak typeof(self)weakSelf = self;
    if ([longPress state] == UIGestureRecognizerStateBegan) {
        CGPoint p = [longPress locationInView:self.fileCV];
        NSIndexPath *indexPath = [self.fileCV indexPathForItemAtPoint:p];
        
        if ([self.currentPath isEqualToString:self.documentPath] && indexPath.row == 0) {
            return;
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"警告" message:@"您要删除这个文件吗？" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[NSFileManager defaultManager]removeItemAtPath:[weakSelf.currentPath stringByAppendingPathComponent:weakSelf.fileArray[indexPath.row]] error:nil];
            [weakSelf.selectedFiles removeObject:[weakSelf.currentPath stringByAppendingPathComponent:weakSelf.fileArray[indexPath.row]]];
            [weakSelf.fileArray removeObjectAtIndex:indexPath.row];

            [weakSelf.fileCV reloadData];
        }];
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

        }];
        
        [alert addAction:action1];
        [alert addAction:action2];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.fileArray.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(96, 120);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(8, 8, 8, 8);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 12;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 8;
}
@end
