//
//  TYHWaterMark.h
//
//  Created by yuhua Tang on 2022/8/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TYHWaterMarkView : UIView
+ (void)setCharacter:(NSString *)str;
+ (void)setTimeFormat:(NSString *)format;
+ (void)setFont:(UIFont *)font;
+ (void)setColor:(UIColor *)color;
+ (void)updateDate;
+ (void)autoUpdateDate:(BOOL)enable;
@end

NS_ASSUME_NONNULL_END
