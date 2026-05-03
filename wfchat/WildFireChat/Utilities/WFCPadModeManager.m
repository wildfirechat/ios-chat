//
//  WFCPadModeManager.m
//  Wildfire Chat
//

#import "WFCPadModeManager.h"

static NSString * const kWFCPadModeKey = @"WFCUsePadMode";

@implementation WFCPadModeManager

+ (BOOL)isPadDevice {
    return UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

+ (BOOL)isPadMode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:kWFCPadModeKey]) {
        return [WFCPadModeManager isPadDevice];
    }
    return [defaults boolForKey:kWFCPadModeKey];
}

+ (void)setPadMode:(BOOL)padMode {
    [[NSUserDefaults standardUserDefaults] setBool:padMode forKey:kWFCPadModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
