//
//  KZVideoViewController.m
//  KZWeChatSmallVideo_OC
//
//  Created by HouKangzhu on 16/7/18.
//  Copyright © 2016年 侯康柱. All rights reserved.
//

#import "KZVideoViewController.h"
#import "KZVideoSupport.h"
#import "KZVideoConfig.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <CoreMotion/CoreMotion.h>
#import "KZVideoListViewController.h"
@interface KZVideoViewController()<KZControllerBarDelegate,AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate> {
    
    KZStatusBar *_topSlideView;
    
    UIView *_videoView;
    KZFocusView *_focusView;
    UILabel *_statusInfo;
    UILabel *_cancelInfo;
    
    KZControllerBar *_ctrlBar;
    
    AVCaptureSession *_videoSession;
    AVCaptureVideoPreviewLayer *_videoPreLayer;
    AVCaptureDevice *_videoDevice;
    
    AVCaptureVideoDataOutput *_videoDataOut;
    AVCaptureAudioDataOutput *_audioDataOut;
    
    AVAssetWriter *_assetWriter;
    AVAssetWriterInputPixelBufferAdaptor *_assetWriterPixelBufferInput;
    AVAssetWriterInput *_assetWriterVideoInput;
    AVAssetWriterInput *_assetWriterAudioInput;
    CMTime _currentSampleTime;
    BOOL _recoding;
    
    dispatch_queue_t _recoding_queue;
//      dispatch_queue_create("com.video.queue", DISPATCH_QUEUE_SERIAL)
    
    KZVideoModel *_currentRecord;
    BOOL _currentRecordIsCancel;
    UIView *_eyeView;
}

@property (nonatomic, assign) KZVideoViewShowType showType;
@property(nonatomic, strong)AVCaptureStillImageOutput *imageOutput;
@property(nonatomic,strong) CMMotionManager *motionManager;
@end

static KZVideoViewController *__currentVideoVC = nil;

@implementation KZVideoViewController


- (void)startAnimationWithType:(KZVideoViewShowType)showType selectExist:(BOOL)selectExist {
    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager startAccelerometerUpdates];
    _showType = showType;
    __currentVideoVC = self;
    
    [self setupSubViews];
    self.view.hidden = YES;
    BOOL videoExist = [KZVideoUtil existVideo];
    UIWindow *keyWindow = [UIApplication sharedApplication].delegate.window;
    [keyWindow addSubview:self.view];
    if (_showType == KZVideoViewShowTypeSingle && videoExist && selectExist) {
        
        [self ctrollVideoOpenVideoList:nil];
        kz_dispatch_after(0.4, ^{
            self.view.hidden = NO;
        });
        
    }
    else {
        self.view.hidden = NO;
        self.actionView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, CGRectGetHeight([KZVideoConfig viewFrameWithType:showType]));
        [UIView animateWithDuration:0.3 delay:0.1 options:UIViewAnimationOptionCurveLinear animations:^{
            self.actionView.transform = CGAffineTransformIdentity;
            self.view.backgroundColor = [UIColor colorWithRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.4];
        } completion:^(BOOL finished) {
            [self viewDidAppear];
        }];
    }
    [self setupVideo];
}

- (void)endAniamtion {
    [self.motionManager stopAccelerometerUpdates];
    [UIView animateWithDuration:0.3 animations:^{
        self.view.backgroundColor = [UIColor clearColor];
        self.actionView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, CGRectGetHeight([KZVideoConfig viewFrameWithType:_showType]));
    } completion:^(BOOL finished) {
        [self closeView];
    }];
}

- (void)closeView {
    [_videoSession stopRunning];
    [_videoPreLayer removeFromSuperlayer];
    _videoPreLayer = nil;
    [_videoView removeFromSuperview];
    _videoView = nil;
    
    _videoDevice = nil;
    _videoDataOut = nil;
    _assetWriter = nil;
    _assetWriterAudioInput = nil;
    _assetWriterVideoInput = nil;
    _assetWriterPixelBufferInput = nil;
    [self.view removeFromSuperview];
    __currentVideoVC = nil;
}

- (void)dealloc {
//    NSLog(@"dalloc videoVC");
}

- (void)setupSubViews {
    _view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor clearColor];
    
    UIPanGestureRecognizer *ges = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveTopBarAction:)];
    [self.view addGestureRecognizer:ges];
    
    _actionView = [[UIView alloc] initWithFrame:[KZVideoConfig viewFrameWithType:_showType]];
    [self.view addSubview:_actionView];
    _actionView.backgroundColor = kzThemeBlackColor;
    _actionView.clipsToBounds = YES;
    
    
    BOOL isSmallStyle = _showType == KZVideoViewShowTypeSmall;
    
    CGSize videoViewSize = [KZVideoConfig videoViewDefaultSize];
    CGFloat topHeight = 64;//isSmallStyle ? 20.0 : 64.0;
    
    CGFloat allHeight = _actionView.frame.size.height;
    CGFloat allWidth = _actionView.frame.size.width;
    
    CGFloat buttomHeight =  280.0;//isSmallStyle ? kzControViewHeight : allHeight - topHeight - videoViewSize.height;
    
    
    _videoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, videoViewSize.width, videoViewSize.height)];
    [self.actionView addSubview:_videoView];
    
    
    _topSlideView = [[KZStatusBar alloc] initWithFrame:CGRectMake(0, 0, allWidth, topHeight) style:_showType];
    
    if (!isSmallStyle) {
        [_topSlideView addCancelTarget:self selector:@selector(endAniamtion)];
    }
    [self.actionView addSubview:_topSlideView];
    
    
    _ctrlBar = [[KZControllerBar alloc] initWithFrame:CGRectMake(0, allHeight - buttomHeight, allWidth, buttomHeight)];
    [_ctrlBar setupSubViewsWithStyle:_showType];
    _ctrlBar.delegate = self;
    [self.actionView addSubview:_ctrlBar];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusAction:)];
    tapGesture.delaysTouchesBegan = YES;
    [_videoView addGestureRecognizer:tapGesture];
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(zoomVideo:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.numberOfTouchesRequired = 1;
    doubleTapGesture.delaysTouchesBegan = YES;
    [_videoView addGestureRecognizer:doubleTapGesture];
    [tapGesture requireGestureRecognizerToFail:doubleTapGesture];
    
    
    _focusView = [[KZFocusView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    _focusView.backgroundColor = [UIColor clearColor];
    
    _statusInfo = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_videoView.frame) - 30, _videoView.frame.size.width, 20)];
    _statusInfo.textAlignment = NSTextAlignmentCenter;
    _statusInfo.font = [UIFont systemFontOfSize:14.0];
    _statusInfo.textColor = [UIColor whiteColor];
    _statusInfo.hidden = YES;
    [self.actionView addSubview:_statusInfo];
    
    _cancelInfo = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 24)];
    _cancelInfo.center = _videoView.center;
    _cancelInfo.textAlignment = NSTextAlignmentCenter;
    _cancelInfo.textColor = kzThemeWhiteColor;
    _cancelInfo.backgroundColor = kzThemeWaringColor;
    _cancelInfo.hidden = YES;
    [self.actionView addSubview:_cancelInfo];
    
    
    [_actionView sendSubviewToBack:_videoView];
}

- (void)setupVideo {
    NSString *unUseInfo = nil;
    if (TARGET_IPHONE_SIMULATOR) {
        unUseInfo = @"模拟器不可以的..";
    }
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(videoAuthStatus == ALAuthorizationStatusRestricted || videoAuthStatus == ALAuthorizationStatusDenied){
        unUseInfo = @"相机访问受限...";
    }
    AVAuthorizationStatus audioAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if(audioAuthStatus == ALAuthorizationStatusRestricted || audioAuthStatus == ALAuthorizationStatusDenied){
        unUseInfo = @"录音访问受限...";
    }
    if (unUseInfo != nil) {
        _statusInfo.text = unUseInfo;
        _statusInfo.hidden = NO;
        _eyeView = [[KZEyeView alloc] initWithFrame:_videoView.bounds];
        [_videoView addSubview:_eyeView];
        return;
    }
    
    _recoding_queue = dispatch_queue_create("com.kzsmallvideo.queue", DISPATCH_QUEUE_SERIAL);
    
    NSArray *devicesVideo = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    NSArray *devicesAudio = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:devicesVideo[0] error:nil];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:devicesAudio[0] error:nil];
    
    _videoDevice = devicesVideo[0];
    
    _videoDataOut = [[AVCaptureVideoDataOutput alloc] init];
    _videoDataOut.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    _videoDataOut.alwaysDiscardsLateVideoFrames = YES;
    [_videoDataOut setSampleBufferDelegate:self queue:_recoding_queue];
    
    _audioDataOut = [[AVCaptureAudioDataOutput alloc] init];
    [_audioDataOut setSampleBufferDelegate:self queue:_recoding_queue];
    
    _videoSession = [[AVCaptureSession alloc] init];
    _videoSession.sessionPreset = AVCaptureSessionPresetHigh;

    if ([_videoSession canAddInput:videoInput]) {
        [_videoSession addInput:videoInput];
    }
    if ([_videoSession canAddInput:audioInput]) {
        [_videoSession addInput:audioInput];
    }
    if ([_videoSession canAddOutput:_videoDataOut]) {
        [_videoSession addOutput:_videoDataOut];
    }
    
    if ([_videoSession canAddOutput:self.imageOutput]) {
        [_videoSession addOutput:self.imageOutput];
    }
    
    if ([_videoSession canAddOutput:_audioDataOut]) {
        [_videoSession addOutput:_audioDataOut];
    }

    CGFloat viewWidth = CGRectGetWidth(_actionView.frame);
    CGFloat viewHeight = CGRectGetHeight(_actionView.frame);
    _videoPreLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_videoSession];
    _videoPreLayer.frame = CGRectMake(0, 0, viewWidth, viewHeight);
    _videoPreLayer.position = CGPointMake(viewWidth/2, viewHeight/2);
    _videoPreLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_videoView.layer addSublayer:_videoPreLayer];
    
    [_videoSession startRunning];
    
    [self viewWillAppear];
}

- (void)viewWillAppear {
    _eyeView = [[KZEyeView alloc] initWithFrame:_videoView.bounds];
    [_videoView addSubview:_eyeView];
}

- (void)viewDidAppear {
    
    if (TARGET_IPHONE_SIMULATOR)  return;
    
    UIView *sysSnapshot = [_eyeView snapshotViewAfterScreenUpdates:NO];
    CGFloat videoViewHeight = CGRectGetHeight(_videoView.frame);
    CGFloat viewViewWidth = CGRectGetWidth(_videoView.frame);
    _eyeView.alpha = 0;
    UIView *topView = [sysSnapshot resizableSnapshotViewFromRect:CGRectMake(0, 0, viewViewWidth, videoViewHeight/2) afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
    CGRect btmFrame = CGRectMake(0, videoViewHeight/2, viewViewWidth, videoViewHeight/2);
    UIView *btmView = [sysSnapshot resizableSnapshotViewFromRect:btmFrame afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
    btmView.frame = btmFrame;
    [_videoView addSubview:topView];
    [_videoView addSubview:btmView];
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        topView.transform = CGAffineTransformMakeTranslation(0,-videoViewHeight/2);
        btmView.transform = CGAffineTransformMakeTranslation(0, videoViewHeight);
        topView.alpha = 0.3;
        btmView.alpha = 0.3;
    } completion:^(BOOL finished) {
        [topView removeFromSuperview];
        [btmView removeFromSuperview];
        [_eyeView removeFromSuperview];
        _eyeView = nil;
        [self focusInPointAtVideoView:CGPointMake(_videoView.bounds.size.width/2, _videoView.bounds.size.height/2)];
    }];
    
    __block UILabel *zoomLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
    zoomLab.center = CGPointMake(_videoView.center.x, CGRectGetMaxY(_videoView.frame) - 16);
    zoomLab.font = [UIFont boldSystemFontOfSize:14];
    zoomLab.text = @"双击放大";
    zoomLab.textColor = [UIColor whiteColor];
    zoomLab.textAlignment = NSTextAlignmentCenter;
    [_videoView addSubview:zoomLab];
    [_videoView bringSubviewToFront:zoomLab];
    
    kz_dispatch_after(1.6, ^{
        [zoomLab removeFromSuperview];
    });
}

- (void)focusInPointAtVideoView:(CGPoint)point {
    CGPoint cameraPoint= [_videoPreLayer captureDevicePointOfInterestForPoint:point];
    _focusView.center = point;
    [_videoView addSubview:_focusView];
    [_videoView bringSubviewToFront:_focusView];
    [_focusView focusing];
    
    NSError *error = nil;
    if ([_videoDevice lockForConfiguration:&error]) {
        if ([_videoDevice isFocusPointOfInterestSupported]) {
            _videoDevice.focusPointOfInterest = cameraPoint;
        }
        if ([_videoDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            _videoDevice.focusMode = AVCaptureFocusModeAutoFocus;
        }
        if ([_videoDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            _videoDevice.exposureMode = AVCaptureExposureModeAutoExpose;
        }
        if ([_videoDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            _videoDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeAutoWhiteBalance;
        }
        [_videoDevice unlockForConfiguration];
    }
    if (error) {
        NSLog(@"聚焦失败:%@",error);
    }
    kz_dispatch_after(1.0, ^{
        [_focusView removeFromSuperview];
    });
}

#pragma mark - Actions --
- (void)focusAction:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:_videoView];
    [self focusInPointAtVideoView:point];
}

- (void)zoomVideo:(UITapGestureRecognizer *)gesture {
    NSError *error = nil;
    if ([_videoDevice lockForConfiguration:&error]) {
        CGFloat zoom = _videoDevice.videoZoomFactor == 2.0?1.0:2.0;
        _videoDevice.videoZoomFactor = zoom;
        [_videoDevice unlockForConfiguration];
    }
}

- (void)moveTopBarAction:(UIPanGestureRecognizer *)gesture {
    CGPoint pointAtView = [gesture locationInView:self.view];
    CGRect dafultFrame = [KZVideoConfig viewFrameWithType:_showType];
    
    if (pointAtView.y < dafultFrame.origin.y) {
        return;
    }
    
    CGPoint pointAtTop = [gesture locationInView:_topSlideView];
    if (pointAtTop.y > -10 && pointAtTop.y < 30) {
        CGRect actionFrame = _actionView.frame;
        actionFrame.origin.y = pointAtView.y;
        _actionView.frame = actionFrame;
        
        CGFloat alpha = 0.4*(kzSCREEN_HEIGHT - pointAtView.y)/CGRectGetHeight(_actionView.frame);
        self.view.backgroundColor = [UIColor colorWithRed: 0.0 green: 0.0 blue: 0.0 alpha: alpha];
    }
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (pointAtView.y >= CGRectGetMidY(dafultFrame)) {
            [self endAniamtion];
        }
        else {
            [UIView animateWithDuration:0.3 animations:^{
                _actionView.frame = dafultFrame;
                self.view.backgroundColor = [UIColor colorWithRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.4];
            }];
        }
    }
}

#pragma mark - controllerBarDelegate 

- (void)ctrollVideoDidStart:(KZControllerBar *)controllerBar {
    _currentRecord = [KZVideoUtil createNewVideo];
    _currentRecordIsCancel = NO;
    NSURL *outURL = [NSURL fileURLWithPath:_currentRecord.videoAbsolutePath];
    [self createWriter:outURL];
    
    _topSlideView.isRecoding = YES;
    
    _statusInfo.textColor = kzThemeTineColor;
    _statusInfo.text = @"↑上移取消";
    _statusInfo.hidden = NO;
    kz_dispatch_after(0.5, ^{
        _statusInfo.hidden = YES;
    });
    
    _recoding = YES;
//    NSLog(@"视频开始录制");
}

- (void)ctrollVideoDidEnd:(KZControllerBar *)controllerBar {
    _topSlideView.isRecoding = NO;
    _recoding = NO;
    [self saveVideo:^(NSURL *outFileURL) {
        if (_delegate) {
            [_delegate videoViewController:self didRecordVideo:_currentRecord];
            [self endAniamtion];
        }
    }];
    
//    NSLog(@"视频录制结束");
}
AVCaptureVideoOrientation orientationBaseOnAcceleration(CMAcceleration acceleration) {
    AVCaptureVideoOrientation result;
    if (acceleration.x >= 0.75) {  /// UIDeviceOrientationLandscapeRight
        result = AVCaptureVideoOrientationLandscapeLeft;
    }
    else if (acceleration.x <= -0.75) { /// UIDeviceOrientationLandscapeLeft
        result = AVCaptureVideoOrientationLandscapeRight;
    }
    else if (acceleration.y <= -0.75) { /// UIDeviceOrientationPortrait
        result = AVCaptureVideoOrientationPortrait;
    }
    else if (acceleration.y >= 0.75) { ///UIDeviceOrientationPortraitUpsideDown
        result = AVCaptureVideoOrientationPortraitUpsideDown;
    }
    else {
        result = AVCaptureVideoOrientationPortrait;
        
    }
    return result;
}

- (void)ctrollImageDidCapture:(KZControllerBar *)controllerBar {
    __weak typeof(self) ws = self;
    CMAcceleration acceleration = self.motionManager.accelerometerData.acceleration;
    AVCaptureVideoOrientation orientation = orientationBaseOnAcceleration(acceleration);
    [self captureStillImage:orientation completion:^(UIImage *image) {
        [ws.delegate videoViewController:self didCaptureImage:image];
        [ws endAniamtion];
    }];
}

- (void)ctrollVideoDidCancel:(KZControllerBar *)controllerBar reason:(KZRecordCancelReason)reason{
    _currentRecordIsCancel = YES;
    _topSlideView.isRecoding = NO;
    _recoding = NO;
    if (reason == KZRecordCancelReasonTimeShort) {
        [KZVideoConfig showHinInfo:@"录制时间过短" inView:_videoView frame:CGRectMake(0,CGRectGetHeight(_videoView.frame)/3*2,CGRectGetWidth(_videoView.frame),20) timeLong:1.0];
    }
//    NSLog(@"当前视频录制取消");
}

- (void)ctrollVideoWillCancel:(KZControllerBar *)controllerBar {
    if (!_cancelInfo.hidden) {
        return;
    }
    _cancelInfo.text = @"松手取消";
    _cancelInfo.hidden = NO;
    kz_dispatch_after(0.5, ^{
        _cancelInfo.hidden = YES;
    });
}

- (void)ctrollVideoDidRecordSEC:(KZControllerBar *)controllerBar {
    _topSlideView.isRecoding = YES;
//    NSLog(@"视频录又过了 1 秒");
}

- (void)ctrollVideoDidClose:(KZControllerBar *)controllerBar {
//    NSLog(@"录制界面关闭");
    if (_delegate && [_delegate respondsToSelector:@selector(videoViewControllerDidCancel:)]) {
        [_delegate videoViewControllerDidCancel:self];
    }
    [self endAniamtion];
}

- (void)ctrollVideoOpenVideoList:(KZControllerBar *)controllerBar {
//    NSLog(@"查看视频列表");
    KZVideoListViewController *listVC = [[KZVideoListViewController alloc] init];
    __weak typeof(self) blockSelf = self;
    listVC.selectBlock = ^(KZVideoModel *selectModel) {
        _currentRecord = selectModel;
        if (_delegate) {
            [_delegate videoViewController:blockSelf didRecordVideo:_currentRecord];
        }
        [blockSelf closeView];
    };
    
    listVC.didCloseBlock = ^{
        if (_showType == KZVideoViewShowTypeSingle) {
            [blockSelf viewDidAppear];
        }
    };
    [listVC showAnimationWithType:_showType];
}

- (UIImage *)fixOrientationOfImage:(UIImage*)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

- (void)captureStillImage:(AVCaptureVideoOrientation)orientation
               completion:(void (^)(UIImage *image))completion{
    
    AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];

    static NSUInteger tryCount = 0;
    if (connection.isVideoOrientationSupported) {
        connection.videoOrientation = orientation;
    }
    
    __weak typeof(self) weakSelf = self;
    id handler = ^(CMSampleBufferRef sampleBuffer, NSError *error) {
        if (sampleBuffer != NULL) {
            
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
            /// 以 Camera 坐标系存储的图片
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            /// 转化以屏幕坐标系存储
            image = [weakSelf fixOrientationOfImage:image];
            tryCount = 0;
            if (completion) {
                completion(image);
            }
            
        } else {
            tryCount++;
            if (tryCount > 3) {
                tryCount = 0;
                completion(nil);
                return;
            }
            NSLog(@"NULL sampleBuffer: %@", [error localizedDescription]);
            [weakSelf captureStillImage:orientation completion:completion];
        }
    };
    // Capture still image
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:handler];
}

- (AVCaptureStillImageOutput *)imageOutput {
    if (!_imageOutput) {
        _imageOutput = [[AVCaptureStillImageOutput alloc] init];
        _imageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
    }
    return _imageOutput;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (!_recoding) return;
    
    @autoreleasepool {
        _currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        if (_assetWriter.status != AVAssetWriterStatusWriting) {
            [_assetWriter startWriting];
            [_assetWriter startSessionAtSourceTime:_currentSampleTime];
        }
        if (captureOutput == _videoDataOut) {
            if (_assetWriterPixelBufferInput.assetWriterInput.isReadyForMoreMediaData) {
                CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                BOOL success = [_assetWriterPixelBufferInput appendPixelBuffer:pixelBuffer withPresentationTime:_currentSampleTime];
                if (!success) {
                    NSLog(@"Pixel Buffer没有append成功");
                }
            }
        }
        if (captureOutput == _audioDataOut) {
            [_assetWriterAudioInput appendSampleBuffer:sampleBuffer];
        }
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
}

- (void)createWriter:(NSURL *)assetUrl {
    _assetWriter = [AVAssetWriter assetWriterWithURL:assetUrl fileType:AVFileTypeQuickTimeMovie error:nil];
    int videoWidth = [KZVideoConfig defualtVideoSize].width;
    int videoHeight = [KZVideoConfig defualtVideoSize].height;
    /*
    NSDictionary *videoCleanApertureSettings = @{
                                               AVVideoCleanApertureWidthKey:@(videoHeight),
                                               AVVideoCleanApertureHeightKey:@(videoWidth),
                                            AVVideoCleanApertureHorizontalOffsetKey:@(200),
                                            AVVideoCleanApertureVerticalOffsetKey:@(0)
                                               };
    NSDictionary *videoAspectRatioSettings = @{
                                               AVVideoPixelAspectRatioHorizontalSpacingKey:@(3),
                                               AVVideoPixelAspectRatioVerticalSpacingKey:@(3)
                                               };
    NSDictionary *codecSettings = @{
                                    AVVideoAverageBitRateKey:@(960000),
                                    AVVideoMaxKeyFrameIntervalKey:@(1),
                                    AVVideoProfileLevelKey:AVVideoProfileLevelH264Main30,
                                    AVVideoCleanApertureKey: videoCleanApertureSettings,
                                    AVVideoPixelAspectRatioKey:videoAspectRatioSettings
                                    };
     */
    NSDictionary *outputSettings = @{
                          AVVideoCodecKey : AVVideoCodecH264,
                          AVVideoWidthKey : @(videoHeight),
                          AVVideoHeightKey : @(videoWidth),
                          AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,
//                          AVVideoCompressionPropertiesKey:codecSettings
                          };
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    
    
    NSDictionary *audioOutputSettings = @{
                                         AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                                         AVEncoderBitRateKey:@(64000),
                                         AVSampleRateKey:@(44100),
                                         AVNumberOfChannelsKey:@(1),
                                         };
    
    _assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
    _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    
    
    NSDictionary *SPBADictionary = @{
                                     (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                     (__bridge NSString *)kCVPixelBufferWidthKey : @(videoWidth),
                                     (__bridge NSString *)kCVPixelBufferHeightKey  : @(videoHeight),
                                     (__bridge NSString *)kCVPixelFormatOpenGLESCompatibility : ((__bridge NSNumber *)kCFBooleanTrue)
                                     };
    _assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:SPBADictionary];
    if ([_assetWriter canAddInput:_assetWriterVideoInput]) {
        [_assetWriter addInput:_assetWriterVideoInput];
    }else {
        NSLog(@"不能添加视频writer的input \(assetWriterVideoInput)");
    }
    if ([_assetWriter canAddInput:_assetWriterAudioInput]) {
        [_assetWriter addInput:_assetWriterAudioInput];
    }else {
        NSLog(@"不能添加视频writer的input \(assetWriterVideoInput)");
    }

}

- (void)saveVideo:(void(^)(NSURL *outFileURL))complier {
    
    if (_recoding) return;
    
    if (!_recoding_queue){
        complier(nil);
        return;
    };
    
    dispatch_async(_recoding_queue, ^{
        NSURL *outputFileURL = [NSURL fileURLWithPath:_currentRecord.videoAbsolutePath];
        [_assetWriter finishWritingWithCompletionHandler:^{
 
            if (_currentRecordIsCancel) return ;
            
            [KZVideoUtil saveThumImageWithVideoURL:outputFileURL second:1];
            
            if (complier) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    complier(outputFileURL);
                });
            }
            if (_savePhotoAlbum) {
                BOOL ios8Later = [[[UIDevice currentDevice] systemVersion] floatValue] >= 8;
                if (ios8Later) {
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputFileURL];
                    } completionHandler:^(BOOL success, NSError * _Nullable error) {
                        if (!error && success) {
                            NSLog(@"保存相册成功!");
                        }
                        else {
                            NSLog(@"保存相册失败! :%@",error);
                        }
                    }];
                    
                }
                else {
                    [[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
                        if (!error) {
                            NSLog(@"保存相册成功!");
                        }
                        else {
                            NSLog(@"保存相册失败!");
                        }
                    }];
                    
                }
                
            }
        }];
    });
    
}

@end
