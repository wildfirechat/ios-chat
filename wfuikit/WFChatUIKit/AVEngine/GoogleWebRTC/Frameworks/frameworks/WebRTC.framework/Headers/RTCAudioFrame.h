/*
 *  Copyright 2015 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

#import <WebRTC/RTCMacros.h>

NS_ASSUME_NONNULL_BEGIN


// RTCVideoFrame is an ObjectiveC version of webrtc::VideoFrame.
RTC_OBJC_EXPORT
@interface RTC_OBJC_TYPE (RTCAudioFrame) : NSObject

/** The number of bytes per audio sample. For example, each PCM audio sample
 usually takes up 16 bits (2 bytes).
 */
@property(assign, nonatomic) NSInteger bytesPerSample;

/** The number of audio channels. If the channel uses stereo, the data is
 interleaved.

- 1: Mono.
- 2: Stereo.
 */
@property(assign, nonatomic) NSInteger channels;

@property(assign, nonatomic) NSInteger numberOfFrames;

/** The buffer of the sample audio data. When the audio frame uses a stereo
 channel, the data buffer is interleaved. The size of the data buffer is as
 follows: `buffer` = `samplesPerChannel` × `channels` × `bytesPerSample`.
 */
@property(strong, nonatomic) NSData* _Nullable audioData;

/** The sample rate.
 */
@property(assign, nonatomic) NSInteger samplesPerSec;

@end

NS_ASSUME_NONNULL_END
