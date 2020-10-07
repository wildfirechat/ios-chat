//
//  ShareViewController.m
//  ShareExtension
//
//  Created by Tom Lee on 2020/10/6.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "ShareViewController.h"
#import "ConversationListViewController.h"
#import "ShareAppService.h"
#import "WFCConfig.h"

@interface ShareViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, assign)BOOL dataLoaded;

//data
@property(nonatomic, strong)NSString *textMessageContent;
@property(nonatomic, strong)NSString *urlTitle;
@property(nonatomic, strong)NSString *url;
@property(nonatomic, strong)NSString *urlThumbnail;
@property(nonatomic, strong)NSArray<NSURL *> *imagesURLs;
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
                    
                    self.urlTitle = item.attributedContentText.string;
                    
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
                                self.url = url.absoluteString;
                                self.dataLoaded = YES;
                                iconView.image = [UIImage imageNamed:@"DefaultLink"];
                            });
                            
                            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                                UIImage *portrait = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:favIcon]]];
                                if (portrait) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        iconView.image = portrait;
                                        self.urlThumbnail = favIcon;
                                    });
                                }
                            });
                        }
                    }];
                } else if ([provider hasItemConformingToTypeIdentifier:@"public.jpeg"]) {
                    header.frame = CGRectMake(0, 0, width, 400);
                    
                    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, 400)];
                    [header addSubview:imageView];
                    
                    NSMutableArray *imageUrls = [[NSMutableArray alloc] init];
                    [provider loadItemForTypeIdentifier:@"public.jpeg" options:nil completionHandler:^(__kindof id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        NSLog(@"the value is %@", item);
                        NSURL *url = (NSURL *)item;
                        if ([url.scheme isEqual:@"file"]) {
                            self.dataLoaded = YES;
                            [imageUrls addObject:url.absoluteString];
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

- (void)sendTo:(SharedConversation *)conversation {
    __weak typeof(self)ws = self;

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认发送给" message:conversation.title preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[ShareAppService sharedAppService] sendLinkMessage:conversation link:self.url title:self.urlTitle thumbnailLink:self.urlThumbnail success:^(NSDictionary * _Nonnull dict) {
            [ws showSuccess];
        } error:^(NSString * _Nonnull message) {
            NSLog(@"send msg failure %@", message);
            [ws showFailure];
        }];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    
    [alertController addAction:cancel];
    [alertController addAction:action];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)showSuccess {
    __weak typeof(self)ws = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"已发送" message:@"您可以在野火IM中查看" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [ws.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    }];
    
    
    [alertController addAction:action];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showFailure {
    __weak typeof(self)ws = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"网络错误" message:@"糟糕！网络出问题了！" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"算了吧" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [ws.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    }];
    
    
    [alertController addAction:action];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.dataLoaded) {
        return 0;
    }
    return 3;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"发给朋友";
    } else if(indexPath.row == 1) {
        cell.textLabel.text = @"发给自己";
    } else {
        cell.textLabel.text = @"分享到朋友圈";
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"did select row %ld", indexPath.row);
    if (indexPath.row == 0) {
        ConversationListViewController *vc = [[ConversationListViewController alloc] init];
        vc.url = self.url;
        vc.urlThumbnail = self.urlThumbnail;
        vc.urlTitle = self.urlTitle;
        vc.textMessageContent = self.textMessageContent;
        vc.imagesURLs = self.imagesURLs;
        [self.navigationController pushViewController:vc animated:YES];
    } else if(indexPath.row == 1) {
        SharedConversation *conversation = [[SharedConversation alloc] init];
        conversation.type = 0;//Single_Type;
        conversation.target = FILE_TRANSFER_ID;
        conversation.line = 0;
        conversation.title = @"自己";
        [self sendTo:conversation];
    }
}
@end
