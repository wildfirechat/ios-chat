//
//  WFCUI420VideoFrame.m
//  WFChatUIKit
//
//  Created by Rain on 2022/10/13.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#import "WFCUI420VideoFrame.h"
#import <libyuv.h>

@interface WFCUI420VideoFrame ()
@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic) int dataLength;

@property (nonatomic) UInt8 *data;
@property (nonatomic) CFMutableDataRef cfData;

@property (nonatomic) UInt8 *dataOfPlaneY;
@property (nonatomic) UInt8 *dataOfPlaneU;
@property (nonatomic) UInt8 *dataOfPlaneV;
@property (nonatomic) int strideY;
@property (nonatomic) int strideU;
@property (nonatomic) int strideV;
@end

@implementation WFCUI420VideoFrame
- (id)initWithWidth:(int)width height:(int)height
{
    if (self = [super init]) {
        self.width = width;
        self.height = height;
        self.dataLength = self.width * self.height * 3 >> 1;
        self.cfData = CFDataCreateMutable(kCFAllocatorDefault, self.dataLength);
        self.data = CFDataGetMutableBytePtr(self.cfData);
        self.dataOfPlaneY = self.data;
        self.dataOfPlaneU = self.dataOfPlaneY + self.width * self.height;
        self.dataOfPlaneV = self.dataOfPlaneU + self.width * self.height / 4;
        self.strideY = self.width;
        self.strideU = self.width >> 1;
        self.strideV = self.width >> 1;
    }
    
    return self;
    
}

- (void)fromBytes:(NSData *)data {
    memcpy(self.data, data.bytes, self.dataLength);
}

- (NSData *)toBytes {
    NSData *data = [NSData dataWithBytes:self.data length:self.dataLength];
    return data;
}

- (CVPixelBufferRef)toPixelBuffer {
    CVPixelBufferRef pixelBuffer = NULL;
    
    
    NSDictionary *pixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSDictionary dictionary], (id)kCVPixelBufferIOSurfacePropertiesKey,
                                           nil];

    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          self.width,
                                          self.height,
                                          kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                          (__bridge CFDictionaryRef)pixelBufferAttributes,
                                          &pixelBuffer);
    
    if (result != kCVReturnSuccess) {
        return NULL;
    }
    
    
    
    result = CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    if (result != kCVReturnSuccess) {
        CFRelease(pixelBuffer);
        return NULL;
    }

    
    uint8 *dstY = (uint8 *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    int dstStrideY = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    uint8* dstUV = (uint8*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    int dstStrideUV = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);

    int ret = libyuv::I420ToNV12(self.dataOfPlaneY, self.strideY,
                                 self.dataOfPlaneU, self.strideU,
                                 self.dataOfPlaneV, self.strideV,
                                     dstY, dstStrideY, dstUV, dstStrideUV,
                                     self.width, self.height);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    if (ret) {
        CFRelease(pixelBuffer);
        return NULL;
    }
    
    return pixelBuffer;
}

- (void) dealloc {
    CFRelease(self.cfData);
}

@end
