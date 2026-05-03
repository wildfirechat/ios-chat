//
//  WFCPadModeManager.h
//  Wildfire Chat
//

#import <UIKit/UIKit.h>

@interface WFCPadModeManager : NSObject

+ (BOOL)isPadDevice;
+ (BOOL)isPadMode;
+ (void)setPadMode:(BOOL)padMode;

@end
