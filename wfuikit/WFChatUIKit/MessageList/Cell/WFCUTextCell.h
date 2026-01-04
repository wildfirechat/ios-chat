//
//  TextCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUMessageCell.h"

@class SelectableTextView;

@interface WFCUTextCell : WFCUMessageCell
@property (strong, nonatomic)SelectableTextView *textLabel;
@end
