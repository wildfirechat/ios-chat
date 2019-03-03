//
//  QrCodeHelper.m
//  WFChatUIKit
//
//  Created by heavyrain lee on 2019/3/3.
//  Copyright © 2019 heavyrain lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QrCodeHelper.h"

id<QrCodeDelegate> gQrCodeDelegate = nil;

void setQrCodeDelegate(id<QrCodeDelegate> delegate) {
    gQrCodeDelegate = delegate;
}
