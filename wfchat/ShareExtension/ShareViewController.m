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
#import "ShareUtility.h"
#import "MBProgressHUD.h"


@interface ShareViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, assign)BOOL dataLoaded;

//文本
@property(nonatomic, strong)NSString *textMessageContent;

//链接
@property(nonatomic, strong)NSString *urlTitle;
@property(nonatomic, strong)NSString *url;
@property(nonatomic, strong)NSString *urlThumbnail;

//图片
@property(nonatomic, assign)BOOL *fullImage;
@property(nonatomic, strong)NSMutableArray<NSString *> *imageUrls;

@property(nonatomic, strong)UIImage *image;

//文件
@property(nonatomic, strong)NSString *fileUrl;
@end

@implementation ShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (![[ShareAppService sharedAppService] isLogin]) {
        __weak typeof(self)ws = self;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"没有登录" message:@"请先登录野火IM" preferredStyle:UIAlertControllerStyleAlert];
        
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [ws.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
        }];
        
        [alertController addAction:cancel];
        
        [ws presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    
    self.dataLoaded = NO;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(onLeftBarBtn:)];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
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
            __weak typeof(self)ws = self;
            for (NSItemProvider *provider in item.attachments) {
                NSLog(@"the provider is %@", provider);
                header.frame = CGRectMake(0, 0, width, 40);
                UILabel *fileLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, width, 24)];
                [header addSubview:fileLabel];
                if ([provider hasItemConformingToTypeIdentifier:@"public.file-url"]) {
                    [provider loadItemForTypeIdentifier:@"public.file-url" options:nil completionHandler:^(__kindof id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        NSURL *url = (NSURL *)item;
                        NSString *fileName = url.absoluteString.lastPathComponent;
                        NSLog(@"file name is %@", fileName);
                        ws.fileUrl = url.absoluteString;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            fileLabel.text = fileName;
                            ws.dataLoaded = YES;
                        });
                    }];
                } else if ([provider hasItemConformingToTypeIdentifier:@"public.url"]) {
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
                                CGSize size = [ws getTextDrawingSize:url.absoluteString font:contentLabel.font constrainedSize:CGSizeMake(width, 132 - 16 - titleSize.height - 8 - 8)];
                                CGRect frame = contentLabel.frame;
                                frame.size.height = size.height;
                                contentLabel.frame = frame;
                                ws.url = url.absoluteString;
                                ws.dataLoaded = YES;
                                iconView.image = [UIImage imageNamed:@"DefaultLink"];
                            });
                            
                            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                                UIImage *portrait = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:favIcon]]];
                                if (portrait) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        iconView.image = portrait;
                                        ws.urlThumbnail = favIcon;
                                    });
                                }
                            });
                        }
                    }];
                } else if ([provider hasItemConformingToTypeIdentifier:@"public.jpeg"] || [provider hasItemConformingToTypeIdentifier:@"public.png"] || [provider hasItemConformingToTypeIdentifier:@"public.image"]) {
                    header.frame = CGRectMake(0, 0, width, 400);
                    
                    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, 400)];
                    [header addSubview:imageView];
                    
                    self.imageUrls = [[NSMutableArray alloc] init];
                    NSString *typeIdentifier = @"public.jpeg";
                    if ([provider hasItemConformingToTypeIdentifier:@"public.png"]) {
                        typeIdentifier = @"public.png";
                    } else if ([provider hasItemConformingToTypeIdentifier:@"public.image"]) {
                        typeIdentifier = @"public.image";
                    }
                    [provider loadItemForTypeIdentifier:typeIdentifier options:nil completionHandler:^(__kindof id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                        NSLog(@"the value is %@", item);
                        UIImage *image = nil;
                        if ([provider hasItemConformingToTypeIdentifier:@"public.image"] && [item isKindOfClass:[UIImage class]]) {
                            image = (UIImage *)item;
                            ws.dataLoaded = YES;
                            ws.image = image;
                        } else {
                            NSURL *url = (NSURL *)item;
                            if ([url.scheme isEqual:@"file"]) {
                                ws.dataLoaded = YES;
                                [ws.imageUrls addObject:url.absoluteString];
                                image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
                            }
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            imageView.image = image;
                            NSExtensionItem *item = ws.extensionContext.inputItems[0];
                            if (item.attachments.count > 1) {
                                [ws showImageLimit];
                            }
                            [ws.tableView reloadData];
                        });
                     
                    }];
                    
                    break;
                } else if ([provider hasItemConformingToTypeIdentifier:@"public.plain-text"]) {
                    self.textMessageContent = item.attributedContentText.string;
                    header.frame = CGRectMake(0, 0, width, 132);
                    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 132)];
                    label.numberOfLines = 0;
                    label.text = item.attributedContentText.string;
                    [header addSubview:label];
                    self.dataLoaded = YES;
                } else if ([provider hasItemConformingToTypeIdentifier:@"public.jpeg"] || [provider hasItemConformingToTypeIdentifier:@"public.png"]) {
                }
            }
        }
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
        [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
        [MBProgressHUD HUDForView:ws.view].mode = MBProgressHUDModeDeterminate;
        [MBProgressHUD HUDForView:ws.view].label.text = @"正在发送中...";
        if (ws.textMessageContent.length) {
            [[ShareAppService sharedAppService] sendTextMessage:conversation text:ws.textMessageContent success:^(NSDictionary * _Nonnull dict) {
                [ws showSuccess];
            } error:^(NSString * _Nonnull message) {
                [ws showFailure];
            }];
        } else if(ws.url.length) {
            [[ShareAppService sharedAppService] sendLinkMessage:conversation link:ws.url title:ws.urlTitle thumbnailLink:ws.urlThumbnail success:^(NSDictionary * _Nonnull dict) {
                [ws showSuccess];
            } error:^(NSString * _Nonnull message) {
                NSLog(@"send msg failure %@", message);
                [ws showFailure];
            }];
        } else if(ws.imageUrls.count) {
            [[ShareAppService sharedAppService] uploadFiles:ws.imageUrls[0] mediaType:1 fullImage:self.fullImage progress:^(int sentcount, int dataSize) {
                [ws showProgress:sentcount total:dataSize];
            } success:^(NSString *url){
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:ws.imageUrls[0]]]];
                
                UIImage *thumbnail = [ShareUtility generateThumbnail:image withWidth:120 withHeight:120];
                [[ShareAppService sharedAppService] sendImageMessage:conversation
                                                            mediaUrl:url
                                                            thubnail:thumbnail
                                                             success:^(NSDictionary * _Nonnull dict) {
                    [ws showSuccess];
                }
                                                               error:^(NSString * _Nonnull message) {
                    [ws showFailure];
                }];
            } error:^(NSString * _Nonnull errorMsg) {
                [ws showFailure];
            }];
        } else if(ws.fileUrl.length) {
            __block int size = 0;
            [[ShareAppService sharedAppService] uploadFiles:ws.fileUrl mediaType:4 fullImage:YES progress:^(int sentcount, int total) {
                size = total;
                [ws showProgress:sentcount total:total];
            } success:^(NSString * _Nonnull url) {
                NSString *fileName = ws.fileUrl.lastPathComponent;
                [[ShareAppService sharedAppService] sendFileMessage:conversation mediaUrl:url fileName:fileName size:size success:^(NSDictionary * _Nonnull dict) {
                    [ws showSuccess];
                } error:^(NSString * _Nonnull message) {
                    [ws showFailure];
                }];
            } error:^(NSString * _Nonnull errorMsg) {
                [ws showFailure];
            }];
        } else if(ws.image) {
            UIImage *image = [ShareUtility generateThumbnail:ws.image withWidth:1024 withHeight:1024];
            NSData *imgData = UIImageJPEGRepresentation(image, 0.85);
            [[ShareAppService sharedAppService] uploadData:imgData mediaType:1 progress:^(int sentcount, int total) {
                [ws showProgress:sentcount total:total];
            } success:^(NSString * _Nonnull url) {
                UIImage *thumbnail = [ShareUtility generateThumbnail:ws.image withWidth:120 withHeight:120];
                [[ShareAppService sharedAppService] sendImageMessage:conversation
                                                            mediaUrl:url
                                                            thubnail:thumbnail
                                                             success:^(NSDictionary * _Nonnull dict) {
                    [ws showSuccess];
                } error:^(NSString * _Nonnull message) {
                    [ws showFailure];
                }];
            } error:^(NSString * _Nonnull errorMsg) {
                [ws showFailure];
            }];
        }
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    
    [alertController addAction:cancel];
    [alertController addAction:action];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showImageLimit {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"不支持发送多张图片" message:@"每次只能发送一张。如果您需要一次发送多张，请打开野火IM选择图片发送。" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

    }];
    
    
    [alertController addAction:action];
    
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)showProgress:(int)sent total:(int)total {
    NSLog(@"progress %d %d", sent, total);
    __weak typeof(self)ws = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD HUDForView:ws.view].progress = (float)sent/total;
    });
}

- (void)showSuccess {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
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
    if(FILE_TRANSFER_ID) {
        return 2;
    }
    return 1;
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
        vc.imageUrls = self.imageUrls;
        vc.fullImage = self.fullImage;
        vc.fileUrl = self.fileUrl;
        vc.image = self.image;
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
