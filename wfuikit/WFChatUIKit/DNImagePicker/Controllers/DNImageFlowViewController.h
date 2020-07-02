//
//  DNImageFlowViewController.h
//  ImagePicker
//
//  Created by DingXiao on 15/2/11.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DNAlbum;

@interface DNImageFlowViewController : UIViewController

- (instancetype)initWithAlbumIdentifier:(NSString *)albumIdentifier;

- (instancetype)initWithAblum:(DNAlbum *)album;



@end
