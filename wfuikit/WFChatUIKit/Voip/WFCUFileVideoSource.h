//
//  WFCUFileVideoSource.h
//  WFChatUIKit
//
//  Created by Rain on 2022/8/1.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WFAVEngineKit/WFAVEngineKit.h>

NS_ASSUME_NONNULL_BEGIN

/*
 外置视频源demo，仅音视频高级版支持。不支持外置音频。使用时需要切换到外置视频源时，参考下面代码
 ```
 
 NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"foreman" ofType:@"mp4"];
 self.fileVideoSource = [[WFCUFileVideoSource alloc] initWithFile:videoPath];
 self.currentSession.externalVideoSource = self.fileVideoSource;
 ```
 */
@interface WFCUFileVideoSource : NSObject <WFAVExternalVideoSource>
- (instancetype)initWithFile:(NSString *)filePath;
@end

NS_ASSUME_NONNULL_END
