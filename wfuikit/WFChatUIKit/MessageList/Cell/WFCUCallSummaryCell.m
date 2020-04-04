//
//  InformationCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUCallSummaryCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"


#define TEXT_TOP_PADDING 6
#define TEXT_BUTTOM_PADDING 6
#define TEXT_LEFT_PADDING 8
#define TEXT_RIGHT_PADDING 8


#define TEXT_LABEL_TOP_PADDING TEXT_TOP_PADDING + 4
#define TEXT_LABEL_BUTTOM_PADDING TEXT_BUTTOM_PADDING + 4
#define TEXT_LABEL_LEFT_PADDING 30
#define TEXT_LABEL_RIGHT_PADDING 30

#if WFCU_SUPPORT_VOIP
#import <WFAVEngineKit/WFAVEngineKit.h>
#endif
@implementation WFCUCallSummaryCell

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    NSString *text = [WFCUCallSummaryCell getCallText:msgModel.message.content];
    CGSize textSize = [WFCUUtilities getTextDrawingSize:text font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake(width, 8000)];
    return CGSizeMake(textSize.width + 25, 30);
}

+ (NSString *)getCallText:(WFCCCallStartMessageContent *)startContent {
    NSString *text = WFCString(@"VOIPCall");
    if (startContent.connectTime > 0 && startContent.endTime > 0) {
        long long duration = startContent.endTime - startContent.connectTime;
        if (duration <= 0) {
            return text;
        }
        duration = duration/1000; //转化成s
        if (duration == 0) {
            return text;
        }
        
        long long hour = duration/3600; //小时数
        duration = duration - hour * 3600; //去除小时
        long long mins = duration/60;  //分钟数
        duration = duration - mins*60;
        long long second = duration;
        
        if (hour) {
            text = [text stringByAppendingFormat:@"%lld:", hour];
        }
        
        text = [text stringByAppendingFormat:@"%02lld:", mins];
        text = [text stringByAppendingFormat:@"%02lld", second];
    } else {
#if WFCU_SUPPORT_VOIP
        switch (startContent.status) {
            case kWFAVCallEndReasonAcceptByOtherClient:
                text = @"其它端已接听";
                break;
            case kWFAVCallEndReasonBusy:
            case kWFAVCallEndReasonRemoteBusy:
                text = @"线路忙";
                break;
            case kWFAVCallEndReasonRemoteTimeout:
                text = @"对方未接听";
                break;
            case kWFAVCallEndReasonRemoteNetworkError:
                text = @"网络错误";
                break;
                
            default:
                break;
        }
        if ([WFAVEngineKit sharedEngineKit].supportMultiCall && (startContent.status == kWFAVCallEndReasonRemoteHangup)) {
            text = @"对方已拒绝";
        }
#endif
    }
    
    return text;
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    CGFloat width = self.contentArea.bounds.size.width;
    
    self.infoLabel.text = [WFCUCallSummaryCell getCallText:model.message.content];
    self.infoLabel.layoutMargins = UIEdgeInsetsMake(TEXT_TOP_PADDING, TEXT_LEFT_PADDING, TEXT_BUTTOM_PADDING, TEXT_RIGHT_PADDING);
    
    CGSize textSize = [WFCUUtilities getTextDrawingSize:self.infoLabel.text font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake(width, 8000)];
    
    if (model.message.direction == MessageDirection_Send) {
        self.infoLabel.frame = CGRectMake(0, 0, width - 25, 30);
        self.modeImageView.frame = CGRectMake(width - 25, 3, 25, 25);
    } else {
        self.infoLabel.frame = CGRectMake(0, 0, width-25, 30);
        self.modeImageView.frame = CGRectMake(width-25, 3, 25, 25);
    }
    if ([self.model.message.content isKindOfClass:[WFCCCallStartMessageContent class]]) {
        WFCCCallStartMessageContent *startContent = (WFCCCallStartMessageContent *)self.model.message.content;
        if (startContent.isAudioOnly) {
            self.modeImageView.image = [UIImage imageNamed:@"msg_audio_call"];
        } else {
            self.modeImageView.image = [UIImage imageNamed:@"msg_video_call"];
        }
    }
}

- (UILabel *)infoLabel {
    if (!_infoLabel) {
        _infoLabel = [[UILabel alloc] init];
        _infoLabel.numberOfLines = 0;
        _infoLabel.font = [UIFont systemFontOfSize:14];
        
        _infoLabel.textColor = [UIColor whiteColor];
        _infoLabel.numberOfLines = 0;
        _infoLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.font = [UIFont systemFontOfSize:14.f];
        _infoLabel.layer.masksToBounds = YES;
        _infoLabel.layer.cornerRadius = 5.f;
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.textColor = [UIColor blackColor];
        _infoLabel.userInteractionEnabled = YES;
        
        [self.contentArea addSubview:_infoLabel];
    }
    return _infoLabel; 
}
- (UIImageView *)modeImageView {
    if (!_modeImageView) {
        _modeImageView = [[UIImageView alloc] init];
        [self.contentArea addSubview:_modeImageView];
    }
    return _modeImageView;
}
@end
