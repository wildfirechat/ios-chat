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
    [super setModel:model];
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kMediaMessageStartDownloading object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([note.object longLongValue] == ws.model.message.messageUid) {
            [ws onStartDownloading:ws];
        }
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:kMediaMessageDownloadFinished object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([note.object longLongValue] == ws.model.message.messageUid) {
            [ws onDownloadFinished:ws];
        }
    }];
    
    
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
