//
//  PttUIKit.h
//  PttUIKit
//
//  Created by Tom Lee on 2021/10/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


//! Project version number for PttUIKit.
FOUNDATION_EXPORT double PttUIKitVersionNumber;

//! Project version string for PttUIKit.
FOUNDATION_EXPORT const unsigned char PttUIKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <PttUIKit/PublicHeader.h>


@protocol WFPttKitDelegate <NSObject>
- (void)willShareChannel:(NSString *)channelId channelName:(NSString *)channelName owner:(NSString *)owner portrait:(NSString *)portrait navController:(UINavigationController *)navController;
@end

__attribute__((visibility("default"))) @interface WFPttKit : NSObject
+ (instancetype)sharedKit;
@property(nonatomic, weak)id<WFPttKitDelegate> delegate;
@end
