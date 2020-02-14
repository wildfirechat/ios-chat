//
//  ViewController.h
//  WFDemo
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WFAVCallSession;
@class WFCCConversation;
@interface WFCUMultiVideoViewController : UIViewController
- (instancetype)initWithSession:(WFAVCallSession *)session;
- (instancetype)initWithTargets:(NSArray<NSString *> *)targetIds conversation:(WFCCConversation *)conversation audioOnly:(BOOL)audioOnly;
@end

