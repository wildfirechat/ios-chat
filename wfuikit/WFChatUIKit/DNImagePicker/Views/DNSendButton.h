//
//  DNSendButton.h
//  ImagePicker
//
//  Created by DingXiao on 15/2/24.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DNSendButton : UIView

@property (nonatomic, copy) NSString *badgeValue;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)addTaget:(id)target action:(SEL)action;

@end
