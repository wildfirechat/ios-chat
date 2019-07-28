//
//  MediaMessageDownloader.h
//  WildFireChat
//
//  Created by heavyrain lee on 2018/8/29.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMediaMessageStartDownloading @"kMediaMessageStartDownloading"
#define kMediaMessageDownloadingProgress @"kMediaMessageDownloadingProgress"
#define kMediaMessageDownloadFinished @"kMediaMessageDownloadFinished"

typedef NS_ENUM(NSInteger, DownloadMediaType) {
    DownloadMediaType_Image,
    DownloadMediaType_Voice,
    DownloadMediaType_Video,
    DownloadMediaType_File,
};

@class WFCCMessage;

@interface WFCUMediaMessageDownloader : NSObject
+ (instancetype)sharedDownloader;

/*
 * @return YES 可以下载； NO 已经在下载了
 */
- (BOOL)tryDownload:(WFCCMessage *)msg
            success:(void(^)(long long messageUid, NSString *localPath))successBlock
              error:(void(^)(long long messageUid, int error_code))errorBlock;


- (BOOL)tryDownload:(NSString *)mediaPath
                uid:(long long)uid
          mediaType:(DownloadMediaType)mediaType
            success:(void(^)(long long messageUid, NSString *localPath))successBlock
              error:(void(^)(long long messageUid, int error_code))errorBlock;
@end
