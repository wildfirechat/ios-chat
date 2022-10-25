//
//  SampleHandler.m
//  Broadcast
//
//  Created by Rain on 2022/10/11.
//  Copyright © 2022 WildFireChat. All rights reserved.
//


#import "SampleHandler.h"
#import "GCDAsyncSocket.h"
#import <libyuv.h>
#import "WFCUI420VideoFrame.h"
#import "WFCUBroadcastDefine.h"

@interface SampleHandler () <GCDAsyncSocketDelegate>
@property (nonatomic, strong) dispatch_queue_t sampleHadlerQueue;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) dispatch_queue_t socketQueue;
@property(nonatomic, strong)NSMutableData *receivedData;

@property (nonatomic, assign) CGFloat cropRate;
@property (nonatomic, assign) CGSize  targetSize;
@property (nonatomic, assign) int orientation; //0 竖屏，1转90，2转180，3转270
@property (nonatomic, assign) BOOL audio; //0 竖屏，1转90，2转180，3转270

@property (nonatomic, assign) int64_t lastTimeStampNs;

@property(nonatomic, assign)BOOL stoped;
@end

@implementation SampleHandler

- (instancetype)init {
    self = [super init];
    if(self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.receivedData = [[NSMutableData alloc] init];
    self.cropRate = 3.f/4;
    self.targetSize = CGSizeMake(480, 640);
    self.sampleHadlerQueue = dispatch_queue_create("cn.wildfirechat.conference.broadcast.sample", DISPATCH_QUEUE_SERIAL);
}

- (void)setupSocket {
    self.socketQueue = dispatch_queue_create("cn.wildfirechat.conference.broadcast.client", DISPATCH_QUEUE_SERIAL);
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.socketQueue];
    NSError *error;
    [self.socket connectToHost:@"127.0.0.1" onPort:36622 error:&error];
    [self.socket readDataWithTimeout:-1 tag:0];
    if(!error) {
        NSLog(@"服务监听开启成功");
    } else {
        NSLog(@"服务监听开启失败");
    }
}

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    [self setupSocket];
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
    if (self.connected) {
        NSString * str =@"Paused";
        NSData *data =[str dataUsingEncoding:NSUTF8StringEncoding];
        [self sendType:0 data:data tag:0];
    }
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
    if (self.connected) {
        NSString * str =@"Resumed";
        NSData *data =[str dataUsingEncoding:NSUTF8StringEncoding];
        [self sendType:0 data:data tag:0];
    }
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    if (!self.stoped && self.connected) {
        NSString * str =@"Finish";
        NSData *data =[str dataUsingEncoding:NSUTF8StringEncoding];
        [self sendType:0 data:data tag:0];
        __weak typeof(self) ws = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [ws disconnect];
        });
        self.stoped = YES;
    }
}

- (void)sendType:(uint16_t)type data:(NSData *)data tag:(int)tag {
    PacketHeader header;
    header.dataType = type;
    header.dataLen = (int)data.length;
    NSMutableData *md = [[NSMutableData alloc] initWithBytes:&header length:sizeof(PacketHeader)];
    [md appendData:data];
    [self.socket writeData:md withTimeout:5 tag:tag];
}

- (void)sendAudioDataToContainerApp:(CMSampleBufferRef)ref {
    CFRetain(ref);
    dispatch_async(self.sampleHadlerQueue, ^{
        @autoreleasepool {
            AudioBufferList audioBufferList;
            NSMutableData *data=[[NSMutableData alloc] init];
            CMBlockBufferRef blockBuffer;
            OSStatus status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(ref, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);

            for(int y=0; y < audioBufferList.mNumberBuffers; y++) {
                AudioBuffer audioBuffer = audioBufferList.mBuffers[y];
                Float32 *frame = (Float32*)audioBuffer.mData;
                [data appendBytes:frame length:audioBuffer.mDataByteSize];
            }
         
            SampleInfo sampleInfo;
            sampleInfo.width = 0;
            sampleInfo.height = 0;
            sampleInfo.dataLen = (int)data.length;
            sampleInfo.type = 1;

            NSMutableData *dataWithHeader = [[NSMutableData alloc] initWithBytes:&sampleInfo length:sizeof(SampleInfo)];
            [dataWithHeader appendData:data];
            
            [self sendType:1 data:[dataWithHeader copy] tag:1];
            CFRelease(blockBuffer);
            CFRelease(ref);
        }
    });
}

#define FPS 10
- (void)sendVideoDataToContainerApp:(CMSampleBufferRef)sampleBuffer {
    NSTimeInterval timeStampSeconds = CACurrentMediaTime();
    int64_t timeStampNs = lroundf(timeStampSeconds * NSEC_PER_SEC);
    if(timeStampNs - self.lastTimeStampNs < 100000000) { //1000000000 / FPS = 100000000
        return;
    }
    self.lastTimeStampNs = timeStampNs;
    
    CFRetain(sampleBuffer);
    dispatch_async(self.sampleHadlerQueue, ^{
        @autoreleasepool {
            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            
            WFCUI420VideoFrame *i420Frame = [self resizeAndConvert:imageBuffer];
            
            if(!i420Frame) {
                return;
            }
            
            NSData *frameData = [i420Frame toBytes];
         
            SampleInfo sampleInfo;
            sampleInfo.width = i420Frame.width;
            sampleInfo.height = i420Frame.height;
            sampleInfo.dataLen = (int)frameData.length;
            sampleInfo.type = 0;

            NSMutableData *dataWithHeader = [[NSMutableData alloc] initWithBytes:&sampleInfo length:sizeof(SampleInfo)];
            [dataWithHeader appendData:frameData];
            
            [self sendType:1 data:[dataWithHeader copy] tag:1];
        }
        CFRelease(sampleBuffer);
    });
}

- (WFCUI420VideoFrame *)resizeAndConvert:(CVImageBufferRef)pixelBuffer {
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    
    OSType sourcePixelFormat = CVPixelBufferGetPixelFormatType( pixelBuffer );

    size_t bufferWidth = 0;
    size_t bufferHeight = 0;
    size_t rowSize = 0;
    uint8_t *pixel = NULL;
    
    if (CVPixelBufferIsPlanar(pixelBuffer)) {
        int basePlane = 0;
        pixel = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, basePlane);
        bufferHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, basePlane);
        bufferWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, basePlane);
        rowSize = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, basePlane);
        
    } else {
        pixel = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
        bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
        bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
        rowSize = CVPixelBufferGetBytesPerRow(pixelBuffer);
    }
    
    WFCUI420VideoFrame *convertedI420Frame = [[WFCUI420VideoFrame alloc] initWithWidth:(int)bufferWidth height:(int)bufferHeight];
    
    int error = -1;
    
    if (kCVPixelFormatType_32BGRA == sourcePixelFormat) {
        error = libyuv::ARGBToI420(pixel, (int)rowSize,
                                   convertedI420Frame.dataOfPlaneY, convertedI420Frame.strideY,
                                   convertedI420Frame.dataOfPlaneU, convertedI420Frame.strideU,
                                   convertedI420Frame.dataOfPlaneV, convertedI420Frame.strideV,
                                   (int)bufferWidth,
                                   (int)bufferHeight);
    } else if (kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange == sourcePixelFormat || kCVPixelFormatType_420YpCbCr8BiPlanarFullRange == sourcePixelFormat) {
        error = libyuv::NV12ToI420(pixel, (int)rowSize,
                                   (const uint8 *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1),
                                   (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1),
                                   convertedI420Frame.dataOfPlaneY, convertedI420Frame.strideY,
                                   convertedI420Frame.dataOfPlaneU, convertedI420Frame.strideU,
                                   convertedI420Frame.dataOfPlaneV, convertedI420Frame.strideV,
                                   (int)bufferWidth,
                                   (int)bufferHeight);
    }
    
    
    if (error) {
        CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
        NSLog(@"error convert pixel buffer to i420 with error %d", error);
        return nil;
    } else {
        rowSize = convertedI420Frame.strideY;
        pixel = convertedI420Frame.data;
    }

    
//屏幕分享不能裁边，裁边后对方收到图片不全。
#define NO_CROP 1

#ifdef NO_CROP
    int cropedWidth = bufferWidth;
    int cropedHeight = bufferHeight;
    WFCUI420VideoFrame *croppedI420Frame = convertedI420Frame;
#else
    int cropX, cropY;
    int cropedWidth, cropedHeight;
    if(bufferWidth*1.f/bufferHeight > self.cropRate) {
        cropedWidth = bufferHeight * self.cropRate;
        cropedHeight = bufferHeight;
    } else {
        cropedWidth = bufferWidth;
        cropedHeight = bufferWidth/self.cropRate;
    }
    
    cropX = (bufferWidth-cropedWidth)/2;
    cropY = (bufferHeight-cropedHeight)/2;
    cropedWidth = cropedWidth>>1<<1;
    cropedHeight = cropedHeight>>1<<1;
    cropX = cropX>>1<<1;
    cropY = cropY>>1<<1;

    WFCUI420VideoFrame *croppedI420Frame = [[WFCUI420VideoFrame alloc] initWithWidth:cropedWidth height:cropedHeight];
    
    error = libyuv::ConvertToI420(pixel, bufferHeight * rowSize * 1.5,
                                      croppedI420Frame.dataOfPlaneY, croppedI420Frame.strideY,
                                      croppedI420Frame.dataOfPlaneU, croppedI420Frame.strideU,
                                      croppedI420Frame.dataOfPlaneV, croppedI420Frame.strideV,
                                      cropX, cropY,
                                      (int)bufferWidth, (int)bufferHeight,
                                      croppedI420Frame.width, croppedI420Frame.height,
                                      libyuv::kRotate0, libyuv::FOURCC_I420);
        
    if (error) {
        CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
        NSLog(@"error convert pixel buffer to i420 with error %d", error);
        return nil;
    }
#endif
    
    WFCUI420VideoFrame *i420Frame;
    float scale = MIN(self.targetSize.width*1.0/cropedWidth, self.targetSize.height*1.0/cropedHeight);
    if (scale == 1.0) {
        i420Frame = croppedI420Frame;
    }else {
        int width = cropedWidth * scale;
        int height = cropedHeight * scale;
        
        i420Frame = [[WFCUI420VideoFrame alloc] initWithWidth:width  height:height];
        
        libyuv::I420Scale(croppedI420Frame.dataOfPlaneY, croppedI420Frame.strideY,
                              croppedI420Frame.dataOfPlaneU, croppedI420Frame.strideU,
                              croppedI420Frame.dataOfPlaneV, croppedI420Frame.strideV,
                              croppedI420Frame.width, croppedI420Frame.height,
                              i420Frame.dataOfPlaneY, i420Frame.strideY,
                              i420Frame.dataOfPlaneU, i420Frame.strideU,
                              i420Frame.dataOfPlaneV, i420Frame.strideV,
                              i420Frame.width, i420Frame.height,
                              libyuv::kFilterBilinear);
    }
    
    
    int dstWidth, dstHeight;
    libyuv::RotationModeEnum rotateMode = (libyuv::RotationModeEnum)(self.orientation*90);
    
    if (rotateMode != libyuv::kRotateNone) {
        if (rotateMode == libyuv::kRotate270 || rotateMode == libyuv::kRotate90) {
            dstWidth = i420Frame.height;
            dstHeight = i420Frame.width;
        }
        else {
            dstWidth = i420Frame.width;
            dstHeight = i420Frame.height;
        }
        WFCUI420VideoFrame *rotatedI420Frame = [[WFCUI420VideoFrame alloc]initWithWidth:dstWidth height:dstHeight];
        
        libyuv::I420Rotate(i420Frame.dataOfPlaneY, i420Frame.strideY,
                               i420Frame.dataOfPlaneU, i420Frame.strideU,
                               i420Frame.dataOfPlaneV, i420Frame.strideV,
                               rotatedI420Frame.dataOfPlaneY, rotatedI420Frame.strideY,
                               rotatedI420Frame.dataOfPlaneU, rotatedI420Frame.strideU,
                               rotatedI420Frame.dataOfPlaneV, rotatedI420Frame.strideV,
                               i420Frame.width, i420Frame.height,
                               rotateMode);
        i420Frame = rotatedI420Frame;
    }
    
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
    return i420Frame;
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            if(self.connected && !self.stoped) {
                [self sendVideoDataToContainerApp:sampleBuffer];
            }
            break;
        case RPSampleBufferTypeAudioApp:
            if(self.connected && self.audio && !self.stoped) {
                [self sendAudioDataToContainerApp:sampleBuffer];
            }
            break;
        case RPSampleBufferTypeAudioMic:
            // Handle audio sample buffer for mic audio
            break;
            
        default:
            break;
    }
}

- (void)disconnect {
    _connected = NO;
    
    if (_socket) {
        [_socket disconnect];
        _socket = nil;
    }
}

- (void)onReceiveCommandFromContainerApp:(int)command value:(int)value {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (command) {
            case 0: //rotation
                self.orientation = value;
                break;
                
            case 1:  //audio
                self.audio = value>0;
                break;
                
            case 2:  //resulation
            {
                int width = value >> 16;
                int height = (value - (width<<16)) & 0xFFFF;
                if(width > height) {
                    self.targetSize = CGSizeMake(width, height);
                } else {
                    self.targetSize = CGSizeMake(height, width);
                }
                break;
            }
                
            case 3:
            {
                [self finishBroadcastWithError:nil];
                if (@available(iOS 14.0, *)) {
                    NSLog(@"broadcast will finished");
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self broadcastFinished];
                    });
                }
                
                break;
            }
            default:
                break;
        }
    });
}
#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToUrl:(NSURL *)url {
    [self.socket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [self.socket readDataWithTimeout:-1 tag:0];
    self.connected = YES;

    NSString * str =@"Start";
    NSData *data =[str dataUsingEncoding:NSUTF8StringEncoding];
    [self sendType:0 data:data tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {

    [self.receivedData appendData:data];
    
    while(self.receivedData.length >= sizeof(Command)) {
        Command command;
        memcpy(&command, self.receivedData.bytes, sizeof(Command));
        [self onReceiveCommandFromContainerApp:command.type value:command.value];
        [self.receivedData replaceBytesInRange:NSMakeRange(0, sizeof(Command)) withBytes:NULL length:0];
    }
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    if(!self.stoped) {
        self.connected = NO;
        [self.socket disconnect];
        self.socket = nil;
        [self setupSocket];
        [self.socket readDataWithTimeout:-1 tag:0];
    }
}
@end
