//
//  KZVideoConfig.m
//  KZWeChatSmallVideo_OC
//
//  Created by HouKangzhu on 16/7/19.
//  Copyright © 2016年 侯康柱. All rights reserved.
//

#import "KZVideoConfig.h"
#import <AVFoundation/AVFoundation.h>


void kz_dispatch_after(float time, dispatch_block_t block)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

@implementation KZVideoConfig

+ (CGRect)viewFrameWithType:(KZVideoViewShowType)type {
    if (type == KZVideoViewShowTypeSingle) {
        return [UIScreen mainScreen].bounds;
    }
    CGFloat viewHeight = kzSCREEN_WIDTH/kzVideo_w_h + 20 + kzControViewHeight;
    return CGRectMake(0, kzSCREEN_HEIGHT - viewHeight, kzSCREEN_WIDTH, viewHeight);
}

+ (CGSize)videoViewDefaultSize {
    return [UIScreen mainScreen].bounds.size;
}

+ (CGSize)defualtVideoSize {
    CGSize size = [UIScreen mainScreen].bounds.size;
    return CGSizeMake(kzVideoWidthPX, kzVideoWidthPX * size.height / size.width);
}

+ (NSArray *)gradualColors {
    return @[(__bridge id)[UIColor greenColor].CGColor,(__bridge id)[UIColor yellowColor].CGColor,];
}

+ (void)motionBlurView:(UIView *)superView {
    superView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    UIToolbar *bar = [[UIToolbar alloc] initWithFrame:superView.bounds];
    [bar setBarStyle:UIBarStyleBlackTranslucent];
    bar.clipsToBounds = YES;
    [superView addSubview:bar];
}

+ (void)showHinInfo:(NSString *)text inView:(UIView *)superView frame:(CGRect)frame timeLong:(NSTimeInterval)time {
    __block UILabel *zoomLab = [[UILabel alloc] initWithFrame:frame];
    zoomLab.font = [UIFont boldSystemFontOfSize:15.0];
    zoomLab.text = text;
    zoomLab.textColor = [UIColor whiteColor];
    zoomLab.textAlignment = NSTextAlignmentCenter;
    [superView addSubview:zoomLab];
    [superView bringSubviewToFront:zoomLab];
    kz_dispatch_after(1.6, ^{
        [zoomLab removeFromSuperview];
    });
}

@end

@implementation KZVideoModel

+ (instancetype)modelWithPath:(NSString *)videoPath thumPath:(NSString *)thumPath recordTime:(NSDate *)recordTime {
    KZVideoModel *model = [[KZVideoModel alloc] init];
    model.videoAbsolutePath = videoPath;
    model.thumAbsolutePath = thumPath;
    model.recordTime = recordTime;
    return model;
}

@end



@implementation KZVideoUtil

+ (BOOL)existVideo {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *nameList = [fileManager subpathsAtPath:[self getVideoPath]];
    return nameList.count > 0;
}


+ (NSMutableArray *)getVideoList {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *modelList = [NSMutableArray array];
    NSArray *nameList = [fileManager subpathsAtPath:[self getVideoPath]];
    for (NSString *name in nameList) {
        if ([name hasSuffix:@".jpg"]) {
            KZVideoModel *model = [[KZVideoModel alloc] init];
            NSString *thumAbsolutePath = [[self getVideoPath] stringByAppendingPathComponent:name];
            model.thumAbsolutePath = thumAbsolutePath;
            
            NSString *totalVideoPath = [thumAbsolutePath stringByReplacingOccurrencesOfString:@"jpg" withString:@"mp4"];
            if ([fileManager fileExistsAtPath:totalVideoPath]) {
                model.videoAbsolutePath = totalVideoPath;
            }
            NSString *timeString = [name substringToIndex:(name.length-4)];
            NSDateFormatter *dateformate = [[NSDateFormatter alloc]init];
            dateformate.dateFormat = @"yyyy-MM-dd_HH:mm:ss";
            NSDate *date = [dateformate dateFromString:timeString];
            model.recordTime = date;
            
            [modelList addObject:model];
        }
    }
    return modelList;
}

+ (NSArray *)getSortVideoList {
    NSArray *oldList = [self getVideoList];
    NSArray *sortList = [oldList sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        KZVideoModel *model1 = obj1;
        KZVideoModel *model2 = obj2;
        NSComparisonResult compare = [model1.recordTime compare:model2.recordTime];
        switch (compare) {
            case NSOrderedDescending:
                return NSOrderedAscending;
            case NSOrderedAscending:
                return NSOrderedDescending;
            default:
                return compare;
        }
    }];
    return sortList;
}

+ (void)saveThumImageWithVideoURL:(NSURL *)videoUrl second:(int64_t)second {
    AVURLAsset *urlSet = [AVURLAsset assetWithURL:videoUrl];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlSet];
    
    CMTime time = CMTimeMake(second, 10);
    NSError *error = nil;
    CGImageRef cgimage = [imageGenerator copyCGImageAtTime:time actualTime:nil error:&error];
    if (error) {
        NSLog(@"缩略图获取失败!:%@",error);
        return;
    }
    UIImage *image = [UIImage imageWithCGImage:cgimage scale:0.6 orientation:UIImageOrientationRight];
    NSData *imgData = UIImageJPEGRepresentation(image, 1.0);
    NSString *videoPath = [videoUrl.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString: @""];
    NSString *thumPath = [videoPath stringByReplacingOccurrencesOfString:@"mp4" withString: @"jpg"];
    BOOL isok = [imgData writeToFile:thumPath atomically: YES];
    NSLog(@"缩略图获取结果:%d",isok);
    CGImageRelease(cgimage);
}

+ (KZVideoModel *)createNewVideo {
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *formate = [[NSDateFormatter alloc] init];
    formate.dateFormat = @"yyyy-MM-dd_HH:mm:ss";
    NSString *videoName = [formate stringFromDate:currentDate];
    NSString *videoPath = [self getVideoPath];
    
    KZVideoModel *model = [[KZVideoModel alloc] init];
    model.videoAbsolutePath = [videoPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",videoName]];
    model.thumAbsolutePath = [videoPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",videoName]];
    model.recordTime = currentDate;
    return model;
}

+ (void)deleteVideo:(NSString *)videoPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager removeItemAtPath:videoPath error:&error];
    if (error) {
        NSLog(@"删除视频失败:%@",error);
    }
    NSString *thumPath = [videoPath stringByReplacingOccurrencesOfString:@"mp4" withString:@"jpg"];
    NSError *error2 = nil;
    [fileManager removeItemAtPath:thumPath error:&error2];
    if (error2) {
        NSLog(@"删除缩略图失败:%@",error);
    }
}

+ (NSString *)getVideoPath {
    return [self getDocumentSubPath:kzVideoDicName];
}

+ (NSString *)getDocumentSubPath:(NSString *)dirName {
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) firstObject];
    return [documentPath stringByAppendingPathComponent:dirName];
}

+ (void)initialize {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dirPath = [self getVideoPath];
    
    NSError *error = nil;
    [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"创建文件夹失败:%@",error);
    }
}

@end
