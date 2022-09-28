//
//  ConferenceLabelView.h
//  WFZoom
//
//  Created by Tom Lee on 2021/9/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUConferenceLabelView : UIView
@property(nonatomic, assign)BOOL isMuteAudio;
@property(nonatomic, assign)BOOL isMuteVideo;
/*
 0 - 10
 */
@property(nonatomic, assign)NSInteger volume;
@property(nonatomic, strong)NSString *name;

+ (CGSize)sizeOffView;
@end

NS_ASSUME_NONNULL_END
