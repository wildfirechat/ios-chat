//
//  SelectableTextView.h
//  WFChat UIKit
//
//  Created by WildFire Chat on 2025/01/04.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SelectableTextView;
@protocol SelectableTextViewDelegate <NSObject>
@optional
- (void)didSelectUrl:(NSString *)urlString;
- (void)didSelectPhoneNumber:(NSString *)phoneNumberString;
- (void)didSelectEmail:(NSString *)emailString;
- (void)didLongPressTextView:(SelectableTextView *)textView;
@end

/**
 * 可选择的文本视图
 * 继承 UITextView，支持：
 * 1. 文本选择和复制
 * 2. URL、电话号码和邮箱检测
 * 3. 点击链接、电话号码和邮箱回调
 * 4. 外观类似 UILabel（无边框、不可编辑）
 * 5. 长按事件通知
 */
@interface SelectableTextView : UITextView

@property(nonatomic, weak)id<SelectableTextViewDelegate> selectableTextViewDelegate;

/**
 * 设置文本内容
 * @param text 要显示的文本
 */
- (void)setText:(NSString *)text;

@end
