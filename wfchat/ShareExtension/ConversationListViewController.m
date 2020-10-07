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
}
@end
