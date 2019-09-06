//
//  UIKit+Pods.h
//  WFChatUIKit
//
//  Created by dklinzh on 2019/7/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (Pods)

+ (instancetype)wf_bundle;

@end

@interface UIImage (Pods)

+ (nullable instancetype)wf_imageNamed:(NSString *)name;

@end

@interface UIView (Pods)

+ (instancetype)wf_createViewFromNibName:(NSString *)nibName;

+ (instancetype)wf_createViewFromNib;

@end

NS_ASSUME_NONNULL_END
