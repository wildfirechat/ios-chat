//
//  FileCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUMediaMessageCell.h"

@interface WFCUFileCell : WFCUMediaMessageCell
@property (nonatomic, strong)UIImageView *fileImageView;
@property (nonatomic, strong)UILabel *fileNameLabel;
@property (nonatomic, strong)UILabel *sizeLabel;
@end
