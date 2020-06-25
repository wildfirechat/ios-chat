//
//  InformationCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUMessageCellBase.h"

@interface WFCURecallCell : WFCUMessageCellBase
@property (nonatomic, strong)UILabel *infoLabel;
@property (nonatomic, strong)UIButton *reeditButton;
@property (nonatomic, strong)UIView *recallContainer;
@end
