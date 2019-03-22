//
//  UILabel+LinkUrl.h
//  WildFireChat
//
//  Created by heavyrain.lee on 2018/5/15.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AttributedLabelDelegate <NSObject>
@optional
- (void)didSelectUrl:(NSString *)urlString;
- (void)didSelectPhoneNumber:(NSString *)phoneNumberString;
@end

@interface AttributedLabel : UILabel
@property(nonatomic, weak)id<AttributedLabelDelegate> attributedLabelDelegate;
- (void)setText:(NSString *)text;
@end
