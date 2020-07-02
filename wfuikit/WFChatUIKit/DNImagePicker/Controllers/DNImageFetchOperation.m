//
//  DNImageFetchOperation.m
//  DNImagePicker
//
//  Created by dingxiao on 2018/10/9.
//  Copyright © 2018 Dennis. All rights reserved.
//

#import "DNImageFetchOperation.h"
#import <Photos/PHAsset.h>
#import <Photos/PHImageManager.h>

typedef void(^DNImageResultHandler)(UIImage *image);

@interface DNImageFetchOperation ()
@property (nonatomic, assign) PHImageRequestID requestID;
@property (nonatomic, assign) CGSize targetSize;
@property (nonatomic, assign) BOOL isHighQuality;
@property (nonatomic, copy) DNImageResultHandler resultHandler;
@end

@implementation DNImageFetchOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithAsset:(PHAsset *)asset {
    self = [super init];
    if (self) {
        _asset = asset;
        _executing = NO;
        _finished = NO;
    }
    return self;
}

- (void)fetchImageWithTargetSize:(CGSize)size
                 needHighQuality:(BOOL)isHighQuality
               imageResutHandler:(void (^)(UIImage * _Nonnull))handler {
    self.targetSize = size;
    self.isHighQuality = isHighQuality;
    self.resultHandler = handler;
}

- (void)start {
    @synchronized (self) {
        if (self.isCancelled) {
            self.finished = YES;
            [self reset];
            return;
        }
        if (!self.asset) {
            self.finished = YES;
            [self reset];
            return;
        }
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        if (self.isHighQuality) {
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        } else {
            options.resizeMode = PHImageRequestOptionsResizeModeExact;
        }
        [[PHImageManager defaultManager] requestImageForAsset:self.asset targetSize:self.targetSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.resultHandler) {
                    self.resultHandler(result);
                }
                [self done];
            });
        }];
        self.executing = YES;
    }
}

- (void)cancel {
    @synchronized (self) {
        if (self.isFinished) return;
        [super cancel];
        
        if (self.asset && self.requestID != PHInvalidImageRequestID) {
            [[PHCachingImageManager defaultManager] cancelImageRequest:self.requestID];
            if (self.isExecuting) self.executing = NO;
            if (!self.isFinished) self.finished = YES;
        }
        [self reset];
    }
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

- (void)reset {
    self.asset = nil;
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent {
    return YES;
}


@end
