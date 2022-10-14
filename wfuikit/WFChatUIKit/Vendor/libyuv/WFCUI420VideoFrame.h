//
//  WFCUI420VideoFrame.h
//  WFChatUIKit
//
//  Created by Rain on 2022/10/13.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMSampleBuffer.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUI420VideoFrame : NSObject
@property (nonatomic, readonly) int width;
@property (nonatomic, readonly) int height;
@property (nonatomic, readonly) int dataLength;
@property (nonatomic, readonly) UInt8 *data;

@property (nonatomic, readonly) UInt8 *dataOfPlaneY;
@property (nonatomic, readonly) UInt8 *dataOfPlaneU;
@property (nonatomic, readonly) UInt8 *dataOfPlaneV;
@property (nonatomic, readonly) int strideY;
@property (nonatomic, readonly) int strideU;
@property (nonatomic, readonly) int strideV;

- (NSData *)toBytes;

- (void)fromBytes:(NSData *)data;
- (id)initWithWidth:(int)width height:(int)height;
- (CVPixelBufferRef)toPixelBuffer;
@end

NS_ASSUME_NONNULL_END
