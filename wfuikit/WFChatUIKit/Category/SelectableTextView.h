//
//  SelectableTextView.h
//  WFChat UIKit
//
//  Created by WildFire Chat on 2025/01/04.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SelectableTextViewDelegate <NSObject>
@optional
- (void)didSelectUrl:(NSString *)urlString;
- (void)didSelectPhoneNumber:(NSString *)phoneNumberString;
@end

/**
 * 可选择的文本视图
 * 继承 UITextView，支持：
 * 1. 文本选择和复制
 * 2. URL 和电话号码检测
 * 3. 点击链接和电话号码回调
 * 4. 外观类似 UILabel（无边框、不可编辑）
 */
@interface SelectableTextView : UITextView

@property(nonatomic, weak)id<SelectableTextViewDelegate> selectableTextViewDelegate;

/**
 * 设置文本内容
 * @param text 要显示的文本
 */
- (void)setText:(NSString *)text;

@end
