//
//  ConversationListViewController.m
//  ShareExtension
//
//  Created by Tom Lee on 2020/10/6.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "ConversationListViewController.h"
#import "SharedConversation.h"
#import <SDWebImage/SDWebImage.h>
#import "SharePredefine.h"
#import "ShareAppService.h"
#import "ShareUtility.h"


@interface ConversationListViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)NSData *cookiesData;
@property(nonatomic, strong)NSArray<SharedConversation *> *sharedConversations;
@property(nonatomic, strong)UITableView *tableView;
@end

@implementation ConversationListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self prepardDataFromContainer];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
}

- (void)prepardDataFromContainer {
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WFC_SHARE_APP_GROUP_ID];//此处id要与开发者中心创建时一致
        
    NSError *error = nil;
    self.sharedConversations = [NSKeyedUnarchiver unarchivedArrayOfObjectsOfClass:[SharedConversation class] fromData:[sharedDefaults objectForKey:WFC_SHARE_BACKUPED_CONVERSATION_LIST] error:&error];
}

- (NSURL *)getSavedGroupGridPortrait:(NSString *)groupId {
    NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:WFC_SHARE_APP_GROUP_ID];
    NSURL *portraitURL = [groupURL URLByAppendingPathComponent:WFC_SHARE_BACKUPED_GROUP_GRID_PORTRAIT_PATH];
    NSURL *fileURL = [portraitURL URLByAppendingPathComponent:groupId];
    
    return fileURL;
}

- (void)sendTo:(SharedConversation *)conversation {
    __weak typeof(self)ws = self;
    if (self.textMessageContent.length) {
        [[ShareAppService sharedAppService] sendTextMessage:conversation text:self.textMessageContent success:^(NSDictionary * _Nonnull dict) {
            [ws showSuccess];
        } error:^(NSString * _Nonnull message) {
            [ws showFailure];
        }];
    } else if(self.url.length) {
        [[ShareAppService sharedAppService] sendLinkMessage:conversation link:self.url title:self.urlTitle thumbnailLink:self.urlThumbnail success:^(NSDictionary * _Nonnull dict) {
            [ws showSuccess];
        } error:^(NSString * _Nonnull message) {
            NSLog(@"send msg failure %@", message);
            [ws showFailure];
        }];
    } else if(self.imageUrls.count){
        [[ShareAppService sharedAppService] uploadFiles:self.imageUrls[0] mediaType:1 progress:^(int sentcount, int dataSize) {
            
        } success:^(NSString *url){
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.imageUrls[0]]]];
            
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
    } else if(self.fileUrl.length) {
        [[ShareAppService sharedAppService] uploadFiles:self.fileUrl mediaType:4 progress:^(int sentcount, int total) {
            
        } success:^(NSString * _Nonnull url) {
            long long size = 0;
            NSFileManager* manager = [NSFileManager defaultManager];
            if ([manager fileExistsAtPath:self.fileUrl]){
                size = [[manager attributesOfItemAtPath:self.fileUrl error:nil] fileSize];
            }
            NSString *fileName = self.fileUrl.lastPathComponent;
            [[ShareAppService sharedAppService] sendFileMessage:conversation mediaUrl:url fileName:fileName size:size success:^(NSDictionary * _Nonnull dict) {
                [ws showSuccess];
            } error:^(NSString * _Nonnull message) {
                [ws showFailure];
            }];
        } error:^(NSString * _Nonnull errorMsg) {
            [ws showFailure];
        }];
    }
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
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sharedConversations.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        
    }
    SharedConversation *sc = self.sharedConversations[indexPath.row];
    cell.textLabel.text = sc.title;
    if (sc.type == 0) { //Single_Type
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:sc.portraitUrl] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    } else if(sc.type == 1) {  //Group_Type
        if (sc.portraitUrl) {
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:sc.portraitUrl] placeholderImage:[UIImage imageNamed:@"GroupChat"]];
        } else {
            [cell.imageView sd_setImageWithURL:[self getSavedGroupGridPortrait:sc.target] placeholderImage:[UIImage imageNamed:@"GroupChat"]];
        }
    } else if(sc.type == 3) { //Channel_Type
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:sc.portraitUrl] placeholderImage:[UIImage imageNamed:@"ChannelChat"]];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 46;
}
#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SharedConversation *sc = self.sharedConversations[indexPath.row];
    
    __weak typeof(self)ws = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认发送给" message:sc.title preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [ws sendTo:sc];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    
    [alertController addAction:cancel];
    [alertController addAction:action];
    
    [self presentViewController:alertController animated:YES completion:nil];
}
@end
