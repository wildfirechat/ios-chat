//
//  MediaMessageGridViewCell.m
//  WFChatUIKit
//
//  Created by dali on 2020/7/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "MediaMessageGridViewCell.h"
#import <WFChatClient/WFCChatClient.h>

@interface MediaMessageGridViewCell ()
@property(nonatomic, strong)UIImageView *imageView;
@property(nonatomic, strong)UIImageView *videoFlag;
@property(nonatomic, strong)UILabel *videoDuration;

@property(nonatomic, strong)UILabel *fileName;
@property(nonatomic, strong)UILabel *fileSize;
@end

@implementation MediaMessageGridViewCell
-(void)setMediaMessage:(WFCCMessage *)mediaMessage {
    _mediaMessage = mediaMessage;
    if ([mediaMessage.content isKindOfClass:[WFCCImageMessageContent class]]) {
        WFCCImageMessageContent *imgCnt = (WFCCImageMessageContent *)mediaMessage.content;
        self.imageView.image = imgCnt.thumbnail;
        
        self.imageView.hidden = NO;
        self.videoFlag.hidden = YES;
        self.videoDuration.hidden = YES;
        self.fileSize.hidden = YES;
        self.fileName.hidden = YES;
    } else if([mediaMessage.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        WFCCVideoMessageContent *videoCnt = (WFCCVideoMessageContent *)mediaMessage.content;
        self.imageView.image = videoCnt.thumbnail;
        if (videoCnt.duration == 0) {
            self.videoDuration.text = nil;
        } else if(videoCnt.duration > 60) {
            self.videoDuration.text = [NSString stringWithFormat:@"%ld:%2ld", videoCnt.duration/60, videoCnt.duration%60];
        } else {
            self.videoDuration.text = [NSString stringWithFormat:@"0:%2ld", videoCnt.duration];
        }
        
        
        self.imageView.hidden = NO;
        self.videoFlag.hidden = NO;
        self.videoDuration.hidden = NO;
        self.fileSize.hidden = YES;
        self.fileName.hidden = YES;
    } else if([mediaMessage.content isKindOfClass:[WFCCFileMessageContent class]]) {
        WFCCFileMessageContent *fileCnt = (WFCCFileMessageContent *)mediaMessage.content;
        self.fileName.text = fileCnt.name;
        if (fileCnt.size > 1024 * 1024) {
            self.fileSize.text = [NSString stringWithFormat:@"%ldM", fileCnt.size/1024/1024];
        } else if(fileCnt.size > 1024) {
            self.fileSize.text = [NSString stringWithFormat:@"%ldK", fileCnt.size/1024];
        } else {
            self.fileSize.text = [NSString stringWithFormat:@"%ldB", fileCnt.size];
        }
        
        self.backgroundColor = [UIColor grayColor];
        
        self.imageView.hidden = YES;
        self.videoFlag.hidden = YES;
        self.videoDuration.hidden = YES;
        self.fileSize.hidden = NO;
        self.fileName.hidden = NO;
    }
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:_imageView];
    }
    return _imageView;
}
- (UIImageView *)videoFlag {
    if (!_videoFlag) {
        _videoFlag = [[UIImageView alloc] initWithFrame:CGRectMake(8, self.bounds.size.height-24, 15, 12)];
        _videoFlag.image = [UIImage imageNamed:@"video"];
        [self addSubview:_videoFlag];
    }
    return _videoFlag;
}
-(UILabel *)videoDuration {
    if (!_videoDuration) {
        _videoDuration = [[UILabel alloc] initWithFrame:CGRectMake(28, self.bounds.size.height-24-2, 40, 16)];
        _videoDuration.font = [UIFont systemFontOfSize:12];
        _videoDuration.lineBreakMode = NSLineBreakByTruncatingHead;
        [self addSubview:_videoDuration];
    }
    return _videoDuration;
}
-(UILabel *)fileName {
    if (!_fileName) {
        _fileName = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, self.bounds.size.width-16, 40)];
        _fileName.font = [UIFont systemFontOfSize:14];
        _fileName.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _fileName.numberOfLines = 2;
        [self addSubview:_fileName];
    }
    return _fileName;
}
-(UILabel *)fileSize {
    if (!_fileSize) {
        _fileSize = [[UILabel alloc] initWithFrame:CGRectMake(8, self.bounds.size.height-24, self.bounds.size.width-16, 16)];
        _fileSize.font = [UIFont systemFontOfSize:14];
        _fileSize.lineBreakMode = NSLineBreakByTruncatingHead;
        [self addSubview:_fileSize];
    }
    return _fileSize;
}
@end
