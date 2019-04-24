//
//  QrCodeHelper.h
//  WFChatUIKit
//
//  Created by heavyrain lee on 2019/3/3.
//  Copyright © 2019 heavyrain lee. All rights reserved.
//


#ifndef QrCodeHelper_h
#define QrCodeHelper_h
#import <UIKit/UIKit.h>

#define QRType_User  0
#define QRType_Group 1
#define QRType_Channel 2
#define QRType_Chatroom 3
#define QRType_PC_Session 4

@protocol QrCodeDelegate <NSObject>
- (void)showQrCodeViewController:(UINavigationController *)navigator type:(int)type target:(NSString *)target;
- (void)scanQrCode:(UINavigationController *)navigator;
@end

extern id<QrCodeDelegate> gQrCodeDelegate;

extern void setQrCodeDelegate(id<QrCodeDelegate> delegate);
#endif /* QrCodeHelper_h */
