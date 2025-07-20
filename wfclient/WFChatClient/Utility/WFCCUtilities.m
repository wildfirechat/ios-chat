//
//  WFCCUtilities.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/7.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCUtilities.h"
#import <CommonCrypto/CommonDigest.h>
#import "WFCCNetworkService.h"

static NSMutableDictionary *wfcUrlImageDict;
static NSLock *wfcImageLock;

@implementation WFCCUtilities
+ (CGSize)imageScaleSize:(CGSize)imageSize targetSize:(CGSize)targetSize thumbnailPoint:(CGPoint *)thumbnailPoint {
    
    if (imageSize.width == 0 && imageSize.height == 0) {
        return targetSize;
    }
    
    CGFloat imageWidth = imageSize.width;
    CGFloat imageHeight = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = 0.0;
    CGFloat scaledHeight = 0.0;
    
    if (imageWidth/imageHeight < 2.4 && imageHeight/imageWidth < 2.4) {
        CGFloat widthFactor = targetWidth / imageWidth;
        CGFloat heightFactor = targetHeight / imageHeight;
        
        if (widthFactor < heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        scaledWidth = imageWidth * scaleFactor;
        scaledHeight = imageHeight * scaleFactor;
        
        if (widthFactor > heightFactor) {
            if (thumbnailPoint) {
                thumbnailPoint->y = (targetHeight - scaledHeight) * 0.5;
            }
        } else if (widthFactor < heightFactor) {
            if (thumbnailPoint) {
                thumbnailPoint->x = (targetWidth - scaledWidth) * 0.5;
            }
        }
    } else {
        if(imageWidth/imageHeight > 2.4) {
            scaleFactor = 100 * targetHeight / imageHeight / 240;
        } else {
            scaleFactor = 100 * targetWidth / imageWidth / 240;
        }
        scaledWidth = imageWidth * scaleFactor;
        scaledHeight = imageHeight * scaleFactor;
    }
    return CGSizeMake(scaledWidth, scaledHeight);
}

+ (UIImage *)generateThumbnail:(UIImage *)image
                     withWidth:(CGFloat)targetWidth
                    withHeight:(CGFloat)targetHeight {
    UIImage *targetImage = nil;
    
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    CGSize targetSize = [WFCCUtilities imageScaleSize:image.size targetSize:CGSizeMake(targetWidth, targetHeight) thumbnailPoint:&thumbnailPoint];
    
    CGFloat scaledWidth = targetSize.width;
    CGFloat scaledHeight = targetSize.height;
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    
    UIGraphicsBeginImageContext(CGSizeMake(scaledWidth, scaledHeight));
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    [image drawInRect:thumbnailRect];
    
    targetImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(imageWidth/imageHeight > 2.4) {
        CGRect rect = CGRectZero;
        rect.origin.x = ( targetImage.size.width - 240)/2;
        rect.size.width = 240;
        rect.origin.y = 0;
        rect.size.height =  targetImage.size.height;
        
        CGImageRef imageRef = CGImageCreateWithImageInRect([ targetImage CGImage], rect);
        targetImage = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
    } else if(imageHeight/imageWidth > 2.4) {
        CGRect rect = CGRectZero;
        rect.origin.y = ( targetImage.size.height - 240)/2;
        rect.size.height = 240;
        rect.origin.x = 0;
        rect.size.width =  targetImage.size.width;
        
        CGImageRef imageRef = CGImageCreateWithImageInRect([ targetImage CGImage], rect);
        targetImage = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
    }
    if ( targetImage == nil)
        NSLog(@"could not scale image");
    
    UIGraphicsEndImageContext();
    return  targetImage;
}

+ (UIImage *)image:(UIImage *)image scaleInSize:(CGSize)size {
    CGFloat originWidth = image.size.width;
    CGFloat originHeight = image.size.height;
    if(originWidth * originHeight < size.width * size.height) {
        return image;
    }
    CGFloat scale = originWidth/size.width < originHeight/size.height ? originHeight/size.height : originWidth/size.width;
    
    CGFloat scaledWidth = originWidth/scale;
    CGFloat scaledHeight = originHeight/scale;
    
    //处理那种长条型图片
    if(originWidth/originHeight > 3 || originHeight/originWidth > 3) {
        scaledWidth *= sqrt(MAX(originWidth/originHeight, originHeight/originWidth));
        scaledHeight *= sqrt(MAX(originWidth/originHeight, originHeight/originWidth));
    }
    
    UIGraphicsBeginImageContext(CGSizeMake(scaledWidth, scaledHeight));
    CGRect rect = CGRectMake(0, 0, scaledWidth, scaledHeight);
    [image drawInRect:rect];
    
    UIImage *targetImage = UIGraphicsGetImageFromCurrentImageContext();
    return targetImage;
}

+ (NSString *)getSendBoxFilePath:(NSString *)localPath {
    if (!localPath.length) {
        return localPath;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        return localPath;
    } else {
        NSUInteger location = [localPath rangeOfString:@"Containers/Data/Application/"].location;
        if (location != NSNotFound) {
            location =
                MIN(MIN([localPath rangeOfString:@"Documents" options:NSCaseInsensitiveSearch range:NSMakeRange(location, localPath.length - location)].location,
                    [localPath rangeOfString:@"Library" options:NSCaseInsensitiveSearch range:NSMakeRange(location, localPath.length - location)].location),
                [localPath rangeOfString:@"tmp" options:NSCaseInsensitiveSearch range:NSMakeRange(location, localPath.length - location)].location);
        }
        
        if (location != NSNotFound) {
            NSString *relativePath = [localPath substringFromIndex:location];
            return [NSHomeDirectory() stringByAppendingPathComponent:relativePath];
        } else {
            return localPath;
        }
    }
}

+ (NSString *)getDocumentPathWithComponent:(NSString *)componentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *path = [documentDirectory stringByAppendingPathComponent:componentPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

+ (UIImage *)imageWithRightOrientation:(UIImage *)aImage {
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
      
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
      
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
              
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
              
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
      
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
              
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
      
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
              
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
      
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

+ (BOOL)isExternalTarget:(NSString *)targetId {
    if([targetId containsString:@"@"]) {
        NSArray *components = [targetId componentsSeparatedByString:@"@"];
        return components.count == 2;
    }
    return false;
}

+ (NSString *)getExternalDomain:(NSString *)targetId {
    if([targetId containsString:@"@"]) {
        NSArray *components = [targetId componentsSeparatedByString:@"@"];
        if(components.count == 2) {
            return components[1];
        }
    }
    return nil;
}
+ (NSString *)getTargetWithoutDomain:(NSString *)targetId {
    if([targetId containsString:@"@"]) {
        NSArray *components = [targetId componentsSeparatedByString:@"@"];
        if(components.count == 2) {
            return components[0];
        }
    }
    return targetId;
}
+ (NSAttributedString *)getExternal:(NSString *)domainId withName:(NSString *)name withColor:(UIColor *)color {
    return [WFCCUtilities getExternal:domainId withName:name withColor:color withSize:0];
}

+ (NSAttributedString *)getExternal:(NSString *)domainId withName:(NSString *)name withColor:(UIColor *)color withSize:(CGFloat)fontSize {
    WFCCDomainInfo *domainInfo = [[WFCCIMService sharedWFCIMService] getDomainInfo:domainId refresh:NO];
    NSString *domainName = domainInfo.name.length?domainInfo.name:domainId;

    NSMutableAttributedString *atts;
    if(name.length) {
        atts = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ @%@", name, domainName]];
        [atts setAttributes:@{NSForegroundColorAttributeName : color} range:NSMakeRange(name.length, domainName.length+2)];
        if(fontSize > 0) {
            [atts addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:fontSize] range:NSMakeRange(name.length, domainName.length+2)];
        }
    } else {
        atts = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"@%@", domainName]];
        [atts setAttributes:@{NSForegroundColorAttributeName : color} range:NSMakeRange(0, domainName.length+1)];
        if(fontSize > 0) {
            [atts addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:fontSize] range:NSMakeRange(0, domainName.length+1)];
        }
    }
    return atts;
}

+ (NSString *)rf_EncryptMD5:(NSString *)str {
    if (str.length<=0) return nil;

    const char *cStr = [str UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (unsigned int)strlen(cStr), digest );

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }

    return  output;
}

+ (UIImage *)getUserImage:(NSString *)url {
    if (!url.length) {
        return nil;
    }
    [wfcImageLock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    UIImage *image = [wfcUrlImageDict objectForKey:url];
    if (!image) {
        image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
        if (wfcUrlImageDict.count > 50) {
            [wfcUrlImageDict removeAllObjects];
        }
        if (image) {
            [wfcUrlImageDict setObject:image forKey:url];
        }
    }
    [wfcImageLock unlock];
    
    return image;
}

+ (void)generateNewGroupPortrait:(NSString *)groupId
                           width:(int)PortraitWidth
            defaultUserPortrait:(UIImage *(^)(NSString *userId))defaultUserPortraitBlock {
    NSNumber *createTime = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"wfc_group_generate_portrait_time_%@_%d", groupId, PortraitWidth]];
    long now = [[[NSDate alloc] init] timeIntervalSince1970];
    if ((now - [createTime longLongValue]) < 10) {//防止连续刷新时，多次生成
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:@(now) forKey:[NSString stringWithFormat:@"wfc_group_generate_portrait_time_%@_%d", groupId, PortraitWidth]];

    UIView *combineHeadView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PortraitWidth, PortraitWidth)];
    [combineHeadView setBackgroundColor:[UIColor colorWithRed:219.f/255 green:223.f/255 blue:224.f/255 alpha:1.f]];
    
    [[WFCCIMService sharedWFCIMService] getGroupMembers:groupId refresh:NO success:^(NSString *groupId, NSArray<WFCCGroupMember *> *members) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            if (!members.count) {
                return;
            }
             
            NSMutableArray *memberIds = [[NSMutableArray alloc] init];
            for (WFCCGroupMember *member in members) {
                [memberIds addObject:member.memberId];
            }
             
            long long now = [[[NSDate alloc] init] timeIntervalSince1970];

            int gridMemberCount = MIN((int)memberIds.count, 9);
            
            CGFloat padding = 3;

            int numPerRow = 3;

            if (gridMemberCount <= 4) {
                numPerRow = 2;
            }
            int row = (int)(gridMemberCount - 1) / numPerRow + 1;
            int column = numPerRow;
            int firstCol = (int)(gridMemberCount - (row - 1)*column);
                
            CGFloat width = (PortraitWidth - padding) / numPerRow - padding;
                
            CGFloat Y = (PortraitWidth - (row * (width + padding) + padding))/2;

            NSString *fullPath = @"";
            for (int i = 0; i < row; i++) {
                int c = column;
                if (i == 0) {
                    c = firstCol;
                }
                CGFloat X = (PortraitWidth - (c * (width + padding) + padding))/2;
                for (int j = 0; j < c; j++) {
                    __block UIImageView *imageView;
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(X + j *(width + padding) + padding, Y + i * (width + padding) + padding, width, width)];
                    });
                     
                    int index;
                    if (i == 0) {
                        index = j;
                    } else {
                        index = j + (i-1)*column + firstCol;
                    }
                    NSString *userId = [memberIds objectAtIndex:index];
                    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
                    
                    
                    __block WFCCUserInfo *user = nil;
                    [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO success:^(WFCCUserInfo *userInfo) {
                        user = userInfo;
                        dispatch_semaphore_signal(sema);
                    } error:^(int errorCode) {
                        dispatch_semaphore_signal(sema);
                    }];
                    
                    dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)));
                    
                    fullPath = [NSString stringWithFormat:@"%@%@", fullPath, user.portrait?user.portrait:userId];
                    
                    UIImage *image;
                    if (user.portrait.length) {
                        image = [WFCCUtilities getUserImage:user.portrait];
                        if (!image) {
                            image = defaultUserPortraitBlock(user.userId);
                        }
                    } else {
                        image = defaultUserPortraitBlock(user.userId);
                    }
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        imageView.image = image;
                        [combineHeadView addSubview:imageView];
                    });
                }
            }
             
            __block UIImage *image;
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIGraphicsBeginImageContextWithOptions(combineHeadView.frame.size, NO, 2.0);
                [combineHeadView.layer renderInContext:UIGraphicsGetCurrentContext()];
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            });
             
             
            NSString *mdt = [WFCCUtilities rf_EncryptMD5:fullPath];
            NSString *fileName = [NSString stringWithFormat:@"%@-%lld-%d-%@", groupId, now, PortraitWidth, mdt];

            NSString *path = [[WFCCUtilities getDocumentPathWithComponent:@"/group_portrait"] stringByAppendingPathComponent:fileName];

            NSData *imgData = UIImageJPEGRepresentation(image, 0.85);

            [imgData writeToFile:path atomically:YES];


            [[NSUserDefaults standardUserDefaults] setObject:path forKey:[NSString stringWithFormat:@"wfc_group_generated_portrait_%@_%d", groupId, PortraitWidth]];
            [[NSUserDefaults standardUserDefaults] synchronize];
             
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"GroupPortraitChanged" object:groupId userInfo:@{@"path":path}];
            });
            
        });
    } error:^(int errorCode) {
        
    }];
}

//如果已经生成了，会立即返回地址。如果没有生成，会返回空，然后生成之后通知GroupPortraitChanged
+ (NSString *)getGroupGridPortrait:(NSString *)groupId
                             width:(int)width
                generateIfNotExist:(BOOL)generateIfNotExist
               defaultUserPortrait:(UIImage *(^)(NSString *userId))defaultUserPortraitBlock {
    //Setp1 检查是否有此群组的记录
    NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"wfc_group_generated_portrait_%@_%d", groupId, width]];
    
    if (!path.length) { //记录不存在，生成
        if (generateIfNotExist) {
            [WFCCUtilities generateNewGroupPortrait:groupId width:width defaultUserPortrait:defaultUserPortraitBlock];
        }
    } else { //记录存在
        //修正沙盒路径
        path = [WFCCUtilities getSendBoxFilePath:path];
        
        //检查文件是否存在
        NSFileManager* fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:path]) { //文件存在
            if (generateIfNotExist) {
                [[WFCCIMService sharedWFCIMService] getGroupInfo:groupId refresh:NO success:^(WFCCGroupInfo *groupInfo) {
                    //分析文件名，获取更新时间，hash值
                    //Path 格式为 groupId-updatetime-width-hash
                    NSString *str = path.lastPathComponent;
                    str = [str substringFromIndex:groupId.length];
                    NSArray *arr = [str componentsSeparatedByString:@"-"];
                    long long timestamp = [arr[1] longLongValue];
                    
                    
                    //检查群组日期，超过7天，或生成之后群组有更新，检查头像是否有变化是否需要重新生成
                    long long now = [[[NSDate alloc] init] timeIntervalSince1970];
                    if (timestamp + 7 * 24 * 3600 < now || timestamp*1000 < groupInfo.updateDt) {
                        [[WFCCIMService sharedWFCIMService] getGroupMembers:groupId refresh:NO success:^(NSString *groupId, NSArray<WFCCGroupMember *> *members) {
                            if (!members.count) {
                                return;
                            }
                            
                            NSString *fullPath = @"";
                            for (int i = 0; i < MIN(members.count, 9); i++) {
                                NSString *userId = members[i].memberId;
                                WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
                                fullPath = [NSString stringWithFormat:@"%@%@", fullPath, userInfo.portrait ? userInfo.portrait : userId];
                            }
                            
                            NSString *mdt = [WFCCUtilities rf_EncryptMD5:fullPath];
                            if (![mdt isEqualToString:arr[3]]) {
                                [WFCCUtilities generateNewGroupPortrait:groupId width:width defaultUserPortrait:defaultUserPortraitBlock];
                            }
                        } error:^(int errorCode) {
                            //log here
                        }];
                    }
                    
                } error:^(int errorCode) {
                }];
            }
            return path;
        } else { //文件不存在
            if (generateIfNotExist) {
                [WFCCUtilities generateNewGroupPortrait:groupId width:width defaultUserPortrait:defaultUserPortraitBlock];
            }
        }
    }
    return nil;
}

+ (NSString *)getGroupGridPortrait:(NSString *)groupId
                   memberPortraits:(NSArray<NSDictionary<NSString*, NSString*>*> *)groupMembers
                             width:(int)PortraitWidth
               defaultUserPortrait:(UIImage *(^)(NSString *userId))defaultUserPortraitBlock {
    __block UIView *combineHeadView;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        combineHeadView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PortraitWidth, PortraitWidth)];
        [combineHeadView setBackgroundColor:[UIColor colorWithRed:219.f/255 green:223.f/255 blue:224.f/255 alpha:1.f]];
    });
    
    long long now = [[[NSDate alloc] init] timeIntervalSince1970];

    int gridMemberCount = MIN((int)groupMembers.count, 9);
    
    CGFloat padding = 3;

    int numPerRow = 3;

    if (gridMemberCount <= 4) {
        numPerRow = 2;
    }
    int row = (int)(gridMemberCount - 1) / numPerRow + 1;
    int column = numPerRow;
    int firstCol = (int)(gridMemberCount - (row - 1)*column);
        
    CGFloat width = (PortraitWidth - padding) / numPerRow - padding;
        
    CGFloat Y = (PortraitWidth - (row * (width + padding) + padding))/2;

    NSString *fullPath = @"";
    for (int i = 0; i < row; i++) {
        int c = column;
        if (i == 0) {
            c = firstCol;
        }
        CGFloat X = (PortraitWidth - (c * (width + padding) + padding))/2;
        for (int j = 0; j < c; j++) {
            __block UIImageView *imageView;
            dispatch_sync(dispatch_get_main_queue(), ^{
                imageView = [[UIImageView alloc] initWithFrame:CGRectMake(X + j *(width + padding) + padding, Y + i * (width + padding) + padding, width, width)];
            });
             
            int index;
            if (i == 0) {
                index = j;
            } else {
                index = j + (i-1)*column + firstCol;
            }
            NSDictionary *dict = [groupMembers objectAtIndex:index];
            NSString *userId = dict[@"userId"];
            NSString *portrait = dict[@"portrait"];
            
            fullPath = [NSString stringWithFormat:@"%@%@", fullPath, portrait?portrait:userId];
            
            UIImage *image;
            if (portrait.length) {
                image = [WFCCUtilities getUserImage:portrait];
                if (!image) {
                    image = defaultUserPortraitBlock(userId);
                }
            } else {
                image = defaultUserPortraitBlock(userId);
            }
            dispatch_sync(dispatch_get_main_queue(), ^{
                imageView.image = image;
                [combineHeadView addSubview:imageView];
            });
        }
    }
     
    __block UIImage *image;
    dispatch_sync(dispatch_get_main_queue(), ^{
        UIGraphicsBeginImageContextWithOptions(combineHeadView.frame.size, NO, 2.0);
        [combineHeadView.layer renderInContext:UIGraphicsGetCurrentContext()];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
     
     
    NSString *mdt = [WFCCUtilities rf_EncryptMD5:fullPath];
    NSString *fileName = [NSString stringWithFormat:@"%@-%lld-%d-%@", groupId, now, PortraitWidth, mdt];

    NSString *path = [[WFCCUtilities getDocumentPathWithComponent:@"/group_portrait"] stringByAppendingPathComponent:fileName];

    NSData *imgData = UIImageJPEGRepresentation(image, 0.85);

    [imgData writeToFile:path atomically:YES];
    
    return path;
}

+ (void)load {
    wfcUrlImageDict = [[NSMutableDictionary alloc] init];
    wfcImageLock = [[NSLock alloc] init];
}

+ (NSString *)getGroupMemberExtra:(WFCCGroupMemberSourceType)sourceType sourceTargetId:(NSString *)sourceTargetId {
    NSDictionary *extraDict;
    if(sourceTargetId.length) {
        extraDict = @{@"s"/*source*/:@{@"t"/*type*/:@(sourceType), @"i"/*targetId*/:sourceTargetId}};
    } else {
        extraDict = @{@"s"/*source*/:@{@"t"/*type*/:@(sourceType)}};
    }
    
    NSData *extraData = [NSJSONSerialization dataWithJSONObject:extraDict
                                                        options:kNilOptions
                                                          error:nil];
    return [[NSString alloc] initWithData:extraData encoding:NSUTF8StringEncoding];
}

+ (WFCCGroupMemberSourceType)getGroupMemberSourceType:(NSString *)memberExtra sourceTargetId:(NSMutableString *)sourceTargetId {
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[memberExtra dataUsingEncoding:NSUTF8StringEncoding]
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error && dictionary[@"s"] && [dictionary[@"s"] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *source = dictionary[@"s"];
        if(source[@"t"]) {
            int sourceType = [[source valueForKey:@"t"] intValue];
            if(sourceType > 0) {
                if(source[@"i"] && [[source valueForKey:@"i"] isKindOfClass:NSString.class]) {
                    [sourceTargetId setString:[source valueForKey:@"i"]];
                }
                return sourceType;
            }
        }
    }
    return GroupMemberSource_Unknown;
}

+ (NSString *)getUserDisplayName:(NSString *)userId inGroup:(NSString *)groupId {
    if ([[WFCCNetworkService sharedInstance].userId isEqualToString:userId]) {
        return @"你";
    } else {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId inGroup:groupId refresh:NO];
        if(userInfo) {
            return userInfo.readableName;
        } else {
            return userId;
        }
    }
}

+ (NSTimeInterval)startSecondOf:(NSUInteger)year month:(NSUInteger)month {
    // 创建日历对象（使用默认时区）
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    [calendar setTimeZone:[NSTimeZone defaultTimeZone]];
    
    // 提取年份和月份组件
    NSDateComponents *components = [[NSDateComponents alloc] init];
    
    // 设置为当月第一天的开始时间（00:00:00 UTC）
    components.year = year;
    components.month = month;
    components.day = 1;
    components.hour = 0;
    components.minute = 0;
    components.second = 0;
    components.timeZone = [NSTimeZone defaultTimeZone];
    components.calendar = calendar;
    
    // 生成当月开始的日期
    NSDate *startOfMonth = [calendar dateFromComponents:components];
    
    // 返回UTC时间戳（秒）
    return [startOfMonth timeIntervalSince1970];
}

+ (NSTimeInterval)endSendOf:(NSUInteger)year month:(NSUInteger)month {
    // 取下个月的时间
    if(month == 12) {
        year++;
        month = 1;
    } else {
        month += 1;
    }
    
    //返回下个月开头时间减一秒。
    return [WFCCUtilities startSecondOf:year month:month] -1;
}
@end
