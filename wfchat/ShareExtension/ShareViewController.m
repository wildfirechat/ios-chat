//
//  ShareViewController.m
//  ShareExtension
//
//  Created by Tom Lee on 2020/10/6.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "ShareViewController.h"
#import "ConversationListViewController.h"

@interface ShareViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, assign)BOOL dataLoaded;
@end

@implementation ShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.dataLoaded = NO;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(onLeftBarBtn:)];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.view addSubview:self.tableView];
    
    self.tableView.tableHeaderView = [self loadTableViewHeader];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
}

- (UIView *)loadTableViewHeader {
    CGFloat width = self.view.bounds.size.width;
    UIView *header = [[UIView alloc] initWithFrame:CGRectZero];
    
    if (self.extensionContext.inputItems.count) {
        NSExtensionItem *item = self.extensionContext.inputItems[0];
        NSLog(@"title: %@", item.attributedTitle);
        NSLog(@"content: %@", item.attributedContentText.string);
        if (item.attachments.count) {
            for (NSItemProvider *provider in item.attachments) {
                NSLog(@"the provider is %@", provider);
                if ([provider hasItemConformingToTypeIdentifier:@"public.url"]) {
                    //链接
                    header.frame = CGRectMake(0, 0, width, 132);
                    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 16, 100, 100)];
                    [header addSubview:iconView];
                    
                    UILabel *titleLabel = [[UILabel alloc] init];
                    titleLabel.text = item.attributedContentText.string;
                    titleLabel.font = [UIFont systemFontOfSize:18];
                    titleLabel.numberOfLines = 0;
                    CGSize titleSize = [self getTextDrawingSize:item.attributedContentText.string font:titleLabel.font constrainedSize:CGSizeMake(width, 48)];
                    titleLabel.frame = CGRectMake(132, 16, width-132-16, titleSize.height);
                    [header addSubview: titleLabel];
                    
                    UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(132, titleSize.height + 16 + 8, width-132-16, 0)];
                    contentLabel.numberOfLines = 0;
                    contentLabel.textColor = [UIColor grayColor];
                    contentLabel.font = [UIFont systemFontOfSize:16];
                    [header addSubview: contentLabel];
                    
                    
                    [provider loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:^(__kindof id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        NSURL *url = (NSURL *)item;
                        if ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]) {
                            NSString *favIcon = [NSString stringWithFormat:@"%@://%@/favicon.ico", url.scheme, url.host];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                contentLabel.text = url.absoluteString;
                                CGSize size = [self getTextDrawingSize:url.absoluteString font:contentLabel.font constrainedSize:CGSizeMake(width, 132 - 16 - titleSize.height - 8 - 8)];
                                CGRect frame = contentLabel.frame;
                                frame.size.height = size.height;
                                contentLabel.frame = frame;
                                self.dataLoaded = YES;
                            });
                            
                            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                                UIImage *portrait = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:favIcon]]];
                                if (portrait) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        iconView.image = portrait;
                                    });
                                }
                            });
                        }
                    }];
                } else if ([provider hasItemConformingToTypeIdentifier:@"public.jpeg"]) {
                    header.frame = CGRectMake(0, 0, width, 400);
                    
                    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, 400)];
                    [header addSubview:imageView];
                    
                    [provider loadItemForTypeIdentifier:@"public.jpeg" options:nil completionHandler:^(__kindof id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        NSLog(@"the value is %@", item);
                        NSURL *url = (NSURL *)item;
                        if ([url.scheme isEqual:@"file"]) {
                            self.dataLoaded = YES;
                            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
                            NSLog(@"the file size is %f,%f", image.size.width, image.size.height);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                imageView.image = image;
                            });
                        }
                    }];
                }
            }
        }
        NSLog(@"userinfo: %@", item.userInfo);
        
    }
    return header;
}

- (void)setDataLoaded:(BOOL)dataLoaded {
    _dataLoaded = dataLoaded;
    [self.tableView reloadData];
}

- (void)onLeftBarBtn:(id)sender {
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (CGSize)getTextDrawingSize:(NSString *)text
                        font:(UIFont *)font
             constrainedSize:(CGSize)constrainedSize {
  if (text.length <= 0) {
    return CGSizeZero;
  }
  
  if ([text respondsToSelector:@selector(boundingRectWithSize:
                                         options:
                                         attributes:
                                         context:)]) {
    return [text boundingRectWithSize:constrainedSize
                              options:(NSStringDrawingTruncatesLastVisibleLine |
                                       NSStringDrawingUsesLineFragmentOrigin |
                                       NSStringDrawingUsesFontLeading)
                           attributes:@{
                                        NSFontAttributeName : font
                                        }
                              context:nil]
    .size;
  } else {
    return [text sizeWithFont:font
            constrainedToSize:constrainedSize
                lineBreakMode:NSLineBreakByTruncatingTail];
  }
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.dataLoaded) {
        return 0;
    }
    return 2;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"发给朋友";
    } else {
        cell.textLabel.text = @"分享到朋友圈";
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"did select row %d", indexPath.row);
    if (indexPath.row == 0) {
        ConversationListViewController *vc = [[ConversationListViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}
@end
