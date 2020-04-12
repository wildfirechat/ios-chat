

#import <UIKit/UIKit.h>
#ifndef BMLOG
#define BMLOG(fmt, ...) NSLog((@"\n\n\nBMLOG:\n%s [Line %d] \n" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#endif

@interface UIColor (YH)

+ (UIColor *)colorWithHexString:(NSString *)hexString;

+ (UIColor *)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

@end
