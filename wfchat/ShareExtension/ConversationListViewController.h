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
@property(nonatomic, strong)NSString *textMessageContent;
@property(nonatomic, strong)NSString *urlTitle;
@property(nonatomic, strong)NSString *url;
@property(nonatomic, strong)NSString *urlThumbnail;
@property(nonatomic, strong)NSMutableArray<NSString *> *imageUrls;
@property(nonatomic, strong)NSString *fileUrl;
@end

NS_ASSUME_NONNULL_END
