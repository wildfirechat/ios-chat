//
//  ConversationListViewController.h
//  ShareExtension
//
//  Created by Tom Lee on 2020/10/6.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ConversationListViewController : UIViewController
//文本
@property(nonatomic, strong)NSString *textMessageContent;

//链接
@property(nonatomic, strong)NSString *urlTitle;
@property(nonatomic, strong)NSString *url;
@property(nonatomic, strong)NSString *urlThumbnail;

//图片
@property(nonatomic, assign)BOOL *fullImage;
@property(nonatomic, strong)NSMutableArray<NSString *> *imageUrls;

//文件
@property(nonatomic, strong)NSString *fileUrl;
@end

NS_ASSUME_NONNULL_END
