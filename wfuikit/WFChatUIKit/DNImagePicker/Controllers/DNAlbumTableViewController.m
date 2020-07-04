//
//  DNAlbumTableViewController.m
//  ImagePicker
//
//  Created by DingXiao on 15/2/10.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import "DNAlbumTableViewController.h"
#import "DNImagePickerController.h"
#import "DNImageFlowViewController.h"
#import "DNAlbumCell.h"
#import "DNUnAuthorizedTipsView.h"
#import "DNImagePickerHelper.h"
#import "DNAlbum.h"

static NSString* const dnalbumTableViewCellReuseIdentifier = @"dnalbumTableViewCellReuseIdentifier";

@interface DNAlbumTableViewController ()
@property (nonatomic, strong) NSArray *albumArray;
@end

@implementation DNAlbumTableViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    [self reloadTableView];
}

#pragma mark - public

- (void)reloadTableView {
    [DNImagePickerHelper requestAlbumListWithCompleteHandler:^(NSArray<DNAlbum *> * _Nonnull anblumList) {
        if (anblumList) {
            self.albumArray = [anblumList copy];
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - mark setup Data and View
- (void)setupView {
    self.title = WFCString(@"albumTitle");

    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"cancel") style:UIBarButtonItemStyleDone target:self action:@selector(cancelAction:)];
    
    [self.tableView registerClass:[DNAlbumCell class] forCellReuseIdentifier:dnalbumTableViewCellReuseIdentifier];
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = view;
}


#pragma mark - ui actions
- (void)cancelAction:(id)sender {
    DNImagePickerController *navController = [self dnImagePickerController];
    if (navController && [navController.imagePickerDelegate respondsToSelector:@selector(dnImagePickerControllerDidCancel:)]) {
        [navController.imagePickerDelegate dnImagePickerControllerDidCancel:navController];
    }
}

#pragma mark - getter/setter

- (DNImagePickerController *)dnImagePickerController {
    if (!self.navigationController
        ||
        ![self.navigationController isKindOfClass:[DNImagePickerController class]])
    {
        NSAssert(false, @"check the navigation controller");
    }
    return (DNImagePickerController *)self.navigationController;
}

- (void)showUnAuthorizedTipsView {
    DNUnAuthorizedTipsView *view  = [[DNUnAuthorizedTipsView alloc] initWithFrame:self.tableView.frame];
    self.tableView.backgroundView = view;
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.albumArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DNAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:dnalbumTableViewCellReuseIdentifier forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    DNAlbum *album = self.albumArray[indexPath.row];
    cell.titleLabel.attributedText = album.albumAttributedString;
    [album fetchPostImageWithSize:CGSizeMake(60, 60) imageResutHandler:^(UIImage * _Nullable postImage) {
        if (postImage) {
            cell.postImageView.image = postImage;
        } else {
            cell.postImageView.image = [UIImage imageNamed:@"assets_placeholder_picture"];
        }
    }];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

#pragma mark - tableView delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DNAlbum *album = self.albumArray[indexPath.row];
    DNImageFlowViewController *imageFlowViewController = [[DNImageFlowViewController alloc] initWithAblum:album];
    [self.navigationController pushViewController:imageFlowViewController animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
