//
//  PanService.h
//  WildFireChat
//
//  Created by WF Chat on 2025/2/24.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WFChatUIKit/WFChatUIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PanService : NSObject <WFCUPanService>

+ (PanService *)sharedService;

@end

NS_ASSUME_NONNULL_END
