//
//  WFCUFileVideoSource.m
//  WFChatUIKit
//
//  Created by Rain on 2022/8/1.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#import "WFCUFileVideoSource.h"

@interface WFCUFileVideoSource ()
@property(nonatomic, weak)id<WFAVExternalFrameDelegate> frameDelegate;
@property(nonatomic, assign) CMTime lastPresentationTime;
@property(nonatomic, strong) NSURL *fileURL;
@end


typedef NS_ENUM(NSInteger, RTCFileVideoCapturerStatus) {
  RTCFileVideoCapturerStatusNotInitialized,
  RTCFileVideoCapturerStatusStarted,
  RTCFileVideoCapturerStatusStopped
};

@implementation WFCUFileVideoSource{
    AVAssetReader *_reader;
    AVAssetReaderTrackOutput *_outTrack;
    RTCFileVideoCapturerStatus _status;
    dispatch_queue_t _frameQueue;
  }

- (instancetype)initWithFile:(NSString *)filePath {
    self = [super init];
    if(self) {
        self.fileURL = [NSURL fileURLWithPath:filePath];
    }
    return self;
}
- (void)startCapture:(id<WFAVExternalFrameDelegate>_Nonnull)delegate {
    self.frameDelegate = delegate;
    self.lastPresentationTime = CMTimeMake(0, 0);
    [self setupReader];
}

- (void)stopCapture {
    self.frameDelegate = nil;
    _status = RTCFileVideoCapturerStatusStopped;
}

- (void)setupReader {
  AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_fileURL options:nil];

  NSArray *allTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
  NSError *error = nil;

  _reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
  if (error) {
    return;
  }

  NSDictionary *options = @{
    (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
  };
  _outTrack =
      [[AVAssetReaderTrackOutput alloc] initWithTrack:allTracks.firstObject outputSettings:options];
  [_reader addOutput:_outTrack];

  [_reader startReading];
  RTCLog(@"File capturer started reading");
  [self readNextBuffer];
}

- (dispatch_queue_t)frameQueue {
  if (!_frameQueue) {
      if (@available(iOS 10, macOS 10.12, tvOS 10, watchOS 3, *)) {
          _frameQueue = dispatch_queue_create_with_target(
                                                          "org.webrtc.filecapturer.video",
                                                          DISPATCH_QUEUE_SERIAL,
                                                          dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
      } else {
          dispatch_queue_t _frameQueue = dispatch_queue_create(
                                                          "org.webrtc.filecapturer.video",
                                                          DISPATCH_QUEUE_SERIAL);
          dispatch_set_target_queue(_frameQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
      }
      
  }
  return _frameQueue;
}

- (void)readNextBuffer {
  if (_status == RTCFileVideoCapturerStatusStopped) {
    [_reader cancelReading];
    _reader = nil;
    return;
  }

  if (_reader.status == AVAssetReaderStatusCompleted) {
    [_reader cancelReading];
    _reader = nil;
    [self setupReader];
    return;
  }

  CMSampleBufferRef sampleBuffer = [_outTrack copyNextSampleBuffer];
  if (!sampleBuffer) {
    [self readNextBuffer];
    return;
  }
  if (CMSampleBufferGetNumSamples(sampleBuffer) != 1 || !CMSampleBufferIsValid(sampleBuffer) ||
      !CMSampleBufferDataIsReady(sampleBuffer)) {
    CFRelease(sampleBuffer);
    [self readNextBuffer];
    return;
  }

  [self publishSampleBuffer:sampleBuffer];
}

- (void)publishSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
  Float64 presentationDifference =
      CMTimeGetSeconds(CMTimeSubtract(presentationTime, _lastPresentationTime));
  _lastPresentationTime = presentationTime;
  int64_t presentationDifferenceRound = lroundf(presentationDifference * NSEC_PER_SEC);

  __block dispatch_source_t timer = [self createStrictTimer];
  // Strict timer that will fire `presentationDifferenceRound` ns from now and never again.
  dispatch_source_set_timer(timer,
                            dispatch_time(DISPATCH_TIME_NOW, presentationDifferenceRound),
                            DISPATCH_TIME_FOREVER,
                            0);
  dispatch_source_set_event_handler(timer, ^{
    dispatch_source_cancel(timer);
    timer = nil;

    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (!pixelBuffer) {
      CFRelease(sampleBuffer);
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self readNextBuffer];
      });
      return;
    }

    RTC_OBJC_TYPE(RTCCVPixelBuffer) *rtcPixelBuffer =
        [[RTC_OBJC_TYPE(RTCCVPixelBuffer) alloc] initWithPixelBuffer:pixelBuffer];
    NSTimeInterval timeStampSeconds = CACurrentMediaTime();
    int64_t timeStampNs = lroundf(timeStampSeconds * NSEC_PER_SEC);
    RTC_OBJC_TYPE(RTCVideoFrame) *videoFrame =
        [[RTC_OBJC_TYPE(RTCVideoFrame) alloc] initWithBuffer:rtcPixelBuffer
                                                    rotation:0
                                                 timeStampNs:timeStampNs];
    CFRelease(sampleBuffer);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [self readNextBuffer];
    });

    [self.frameDelegate didCaptureVideoFrame:videoFrame];
  });
  dispatch_activate(timer);
}

- (dispatch_source_t)createStrictTimer {
  dispatch_source_t timer = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_TIMER, 0, DISPATCH_TIMER_STRICT, [self frameQueue]);
  return timer;
}

@end
