//
//  WFCUCreateCollectionViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCUCreateCollectionViewController;
@class WFCUCollection;

@protocol WFCUCreateCollectionViewControllerDelegate <NSObject>
- (void)createCollectionViewController:(WFCUCreateCollectionViewController *)controller didCreateCollection:(WFCUCollection *)collection;
- (void)createCollectionViewControllerDidCancel:(WFCUCreateCollectionViewController *)controller;
@end

@interface WFCUCreateCollectionViewController : UIViewController

@property (nonatomic, strong)WFCCConversation *conversation;
@property (nonatomic, weak, nullable)id<WFCUCreateCollectionViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
