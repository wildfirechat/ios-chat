//
//  KZVideoConfig.h
//  KZWeChatSmallVideo_OC
//
//  Created by HouKangzhu on 16/7/19.
//  Copyright © 2016年 侯康柱. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kzSCREEN_WIDTH      [UIScreen mainScreen].bounds.size.width
#define kzSCREEN_HEIGHT     [UIScreen mainScreen].bounds.size.height


#define kzThemeBlackColor   [UIColor blackColor]
#define kzThemeTineColor    [UIColor greenColor]

#define kzThemeWaringColor  [UIColor redColor]
#define kzThemeWhiteColor   [UIColor whiteColor]
#define kzThemeGraryColor   [UIColor grayColor]

// 视频保存路径
#define kzVideoDicName      @"kzSmailVideo"

// 视频录制 时长
#define kzRecordTime        10.0

// 视频的长宽按比例
#define kzVideo_w_h (4.0/3)

// 视频默认 宽的分辨率  高 = kzVideoWidthPX / kzVideo_w_h
#define kzVideoWidthPX  200.0

//控制条高度 小屏幕时
#define kzControViewHeight  120.0
// 是否保存到手机相册
//#define saveToLibrary   (0)


extern void kz_dispatch_after(float time, dispatch_block_t block);

typedef NS_ENUM(NSUInteger, KZVideoViewShowType) {
    KZVideoViewShowTypeSmall,  // 小屏幕 ...聊天界面的
    KZVideoViewShowTypeSingle, // 全屏 ... 朋友圈界面的
};

@interface KZVideoConfig : NSObject
// 录像 的 View 大小
+ (CGRect)viewFrameWithType:(KZVideoViewShowType)type;

//视频View的尺寸
+ (CGSize)videoViewDefaultSize;

// 默认视频分辨率
+ (CGSize)defualtVideoSize;
// 渐变色
+ (NSArray *)gradualColors;

// 模糊View
+ (void)motionBlurView:(UIView *)superView;


+ (void)showHinInfo:(NSString *)text inView:(UIView *)superView frame:(CGRect)frame timeLong:(NSTimeInterval)time;

@end

/*!
 *  视频对象 Model类
 */
@interface KZVideoModel : NSObject
/// 完整视频 本地路径
@property (nonatomic, copy) NSString *videoAbsolutePath;
/// 缩略图 路径
@property (nonatomic, copy) NSString *thumAbsolutePath;
// 录制时间
@property (nonatomic, strong) NSDate *recordTime;

@end

@interface KZVideoUtil : NSObject

/*!
 *  有视频的存在
 */
+ (BOOL)existVideo;

/*!
 *  时间倒序 后的视频列表
 */
+ (NSArray *)getSortVideoList;

/*!
 *  保存缩略图
 *
 *  @param videoUrl 视频路径
 *  @param second   第几秒的缩略图
 */
+ (void)saveThumImageWithVideoURL:(NSURL *)videoUrl second:(int64_t)second;

/*!
 *  产生新的对象
 */
+ (KZVideoModel *)createNewVideo;

/*!
 *  删除视频
 */
+ (void)deleteVideo:(NSString *)videoPath;

@end