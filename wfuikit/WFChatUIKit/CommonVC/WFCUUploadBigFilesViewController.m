//
//  WFCUUploadBigFilesViewController.m
//  WFChatUIKit
//
//  Created by heavyrain.lee on 2021/3/6.
//  Copyright © 2021 Wildfire Chat. All rights reserved.
//

#import "WFCUUploadBigFilesViewController.h"
#import "WFCUConfigManager.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUploadFileTableViewCell.h"
#import "AFNetworking.h"

@implementation WFCUUploadFileModel
@end

@interface WFCUUploadBigFilesViewController () <UITableViewDataSource, UITableViewDelegate, WFCUUploadFileTableViewCellDelegate, NSURLSessionDelegate>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSMutableArray<WFCUUploadFileModel *> *models;
@property(nonatomic, strong)WFCUUploadFileModel *uploadingModel;
@end

@implementation WFCUUploadBigFilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView registerClass:[WFCUUploadFileTableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];

    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.title = @"上传大文件";
}

- (void)setBigFileContents:(NSMutableArray<WFCCFileMessageContent *> *)bigFileContents {
    _bigFileContents = bigFileContents;
    self.models = [[NSMutableArray alloc] initWithCapacity:bigFileContents.count];
    for (WFCCFileMessageContent *content in bigFileContents) {
        WFCUUploadFileModel *model = [[WFCUUploadFileModel alloc] init];
        model.bigFileContent = content;
        model.state = 0;
        [self.models addObject:model];
    }
}

#pragma mark - WFCUUploadFileTableViewCellDelegate
- (void)didTapUpload:(WFCUUploadFileTableViewCell *)cell model:(WFCUUploadFileModel *)model {
    if(!self.uploadingModel) {
        self.uploadingModel = model;
    } else {
        return;
    }
    
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] getUploadUrl:model.bigFileContent.name mediaType:0 success:^(NSString *uploadUrl, NSString *downloadUrl, NSString *backupUploadUrl, int type) {
        if(type == 1) {
            [ws uploadQiniu:uploadUrl file:model.bigFileContent.localPath model:model remoteUrl:downloadUrl];
        } else {
            [ws upload:uploadUrl file:model.bigFileContent.localPath model:model remoteUrl:downloadUrl];
        }
    } error:^(int error_code) {
        ws.uploadingModel = nil;
    }];
}

- (void)upload:(NSString *)url file:(NSString *)file model:(WFCUUploadFileModel *)model remoteUrl:(NSString *)remoteUrl {
    NSURL *presignedURL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [request setHTTPMethod:@"PUT"];
    NSString *fileContentTypeString = @"application/octet-stream";
    [request setValue:fileContentTypeString forHTTPHeaderField:@"Content-Type"];

    __weak typeof(self)ws = self;
    model.uploadTask = [[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil] uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:file] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error) {
                NSLog(@"error %@", error.localizedDescription);
                model.state = 4;
            } else {
                NSLog(@"done");
                if(((NSHTTPURLResponse *)response).statusCode != 200) {
                    model.state = 4;
                } else {
                    model.state = 2;
                    model.bigFileContent.remoteUrl = remoteUrl;
                }
            }
            ws.uploadingModel = nil;
        });
    }];
    model.state = 1;
    [model.uploadTask resume];
}

- (void)uploadQiniu:(NSString *)url file:(NSString *)file model:(WFCUUploadFileModel *)model remoteUrl:(NSString *)remoteUrl {
    NSArray *array = [url componentsSeparatedByString:@"?"];
    url = array[0];
    NSString *token = array[1];
    NSString *key = array[2];
    
    AFHTTPSessionManager *manage = [AFHTTPSessionManager manager];
    [manage.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    manage.requestSerializer = [AFHTTPRequestSerializer serializer];
    manage.responseSerializer = [AFHTTPResponseSerializer serializer];
    manage.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/javascript",@"text/plain", nil];

    __weak typeof(self)ws = self;
    model.state = 1;
    [manage POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFormData:[key dataUsingEncoding:NSUTF8StringEncoding] name:@"key"];
        [formData appendPartWithFormData:[token dataUsingEncoding:NSUTF8StringEncoding] name:@"token"];
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:file] name:@"file" fileName:@"fileName" mimeType:@"application/octet-stream" error:nil];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(ws.uploadingModel) {
                ws.uploadingModel.uploadProgress = uploadProgress.completedUnitCount * 1.f / uploadProgress.totalUnitCount;
                NSLog(@"upload progress %f", ws.uploadingModel.uploadProgress);
            }
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            model.state = 2;
            model.bigFileContent.remoteUrl = remoteUrl;
            ws.uploadingModel = nil;
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"error %@", error.localizedDescription);
            model.state = 4;
            ws.uploadingModel = nil;
        });
    }];
}

- (void)didTapCancelUpload:(WFCUUploadFileTableViewCell *)cell model:(WFCUUploadFileModel *)model {
    if(model.state == 1) {
        [model.uploadTask cancel];
        model.state = 3;
    }
}

- (void)didTapSend:(WFCUUploadFileTableViewCell *)cell model:(WFCUUploadFileModel *)model {
    model.state = 5;
    [[WFCCIMService sharedWFCIMService] send:self.conversation content:model.bigFileContent success:^(long long messageUid, long long timestamp) {
            
        } error:^(int error_code) {
            
        }];
}

- (void)didTapForward:(WFCUUploadFileTableViewCell *)cell model:(WFCUUploadFileModel *)model {
    
}

#pragma mark - UITableViewDataSource
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    WFCUUploadFileTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.bigFileModel = self.models[indexPath.row];
    cell.conversation = self.conversation;
    cell.delegate = self;
    return cell;;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.bigFileContents.count;
}

#pragma mark - UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                                didSendBodyData:(int64_t)bytesSent
                                 totalBytesSent:(int64_t)totalBytesSent
                       totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.uploadingModel) {
            self.uploadingModel.uploadProgress = totalBytesSent * 1.f / self.uploadingModel.bigFileContent.size;
            NSLog(@"upload progress %f", self.uploadingModel.uploadProgress);
        }
    });
}
@end
