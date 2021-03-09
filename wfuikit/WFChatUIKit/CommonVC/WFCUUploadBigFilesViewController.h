//
//  WFCUUploadBigFilesViewController.h
//  WFChatUIKit
//
//  Created by heavyrain.lee on 2021/3/6.
//  Copyright © 2021 Wildfire Chat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCCFileMessageContent;
@class WFCCConversation;

@interface WFCUUploadFileModel : NSObject
@property(nonatomic, strong)WFCCFileMessageContent *bigFileContent;
@property(nonatomic, assign)int state; //0 未上传, 1 上传中，2 上传成功，3 取消发送，4 上传失败，5 消息发送成功
@property(nonatomic, assign)float uploadProgress;
@property(nonatomic, strong)NSURLSessionUploadTask *uploadTask;
@end

@interface WFCUUploadBigFilesViewController : UIViewController
@property(nonatomic, strong)NSMutableArray<WFCCFileMessageContent *> *bigFileContents;
@property (nonatomic, strong)WFCCConversation *conversation;
@end

NS_ASSUME_NONNULL_END
