//
//  MediaMessageCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUMediaMessageCell.h"
#import "WFCUMediaMessageDownloader.h"

@interface WFCUMediaMessageCell ()
@property (nonatomic, strong)UIView *maskView;
@property (nonatomic, strong)UIActivityIndicatorView *activityView;
@end

@implementation WFCUMediaMessageCell

- (void)setModel:(WFCUMessageModel *)model {
    if (self.model.message.messageUid != 0) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kMediaMessageStartDownloading object:@(self.model.message.messageUid)];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kMediaMessageDownloadFinished object:@(self.model.message.messageUid)];
    }
    [super setModel:model];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStartDownloading:) name:kMediaMessageStartDownloading object:@(model.message.messageUid)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDownloadFinished:) name:kMediaMessageDownloadFinished object:@(model.message.messageUid)];
    
    if (model.mediaDownloading) {
        [self onStartDownloading:self];
    } else {
        [self onDownloadFinished:self];
    }
}

- (void)onStartDownloading:(id)sender {
    if (!_maskView) {
        _maskView = [[UIView alloc] init];
        [self.bubbleView addSubview:_maskView];
        [_maskView setBackgroundColor:[UIColor grayColor]];
        [_maskView setAlpha:0.5];
        [_maskView setClipsToBounds:YES];
    }
    _maskView.frame = self.bubbleView.bounds;
    [self.bubbleView bringSubviewToFront:_maskView];
    
    if (!_activityView) {
        _activityView = [[UIActivityIndicatorView alloc] init];
        [_maskView addSubview:_activityView];
    }
    _activityView.center = CGPointMake(self.maskView.bounds.size.width/2, self.maskView.bounds.size.height/2);
    [_activityView startAnimating];
    
}

- (void)onDownloadFinished:(id)sender {
    if (_maskView) {
        [_maskView removeFromSuperview];
        _maskView = nil;
    }

    if (_activityView) {
        [_activityView removeFromSuperview];
        [_activityView stopAnimating];
        _activityView = nil;
    }
    
    if ([sender isKindOfClass:[NSNotification class]]) {
        NSNotification *noti = (NSNotification *)sender;
        if ([noti.userInfo[@"result"] boolValue]) {
            [self setModel:self.model];
        }
    }
}
@end
