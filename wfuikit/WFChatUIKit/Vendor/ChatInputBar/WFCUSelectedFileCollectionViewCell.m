//
//  SelectedFileCollectionViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//


#import "WFCUSelectedFileCollectionViewCell.h"

@implementation WFCUSelectedFileCollectionViewCell
-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (UIImageView *)backIV {
    if (!_backIV) {
        _backIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 96, 96)];
        [self addSubview:_backIV];
        [_backIV setImage:[UIImage imageNamed:@"file_icon"]];
    }
    return _backIV;
}

- (UIImageView *)selectIV {
    if (!_selectIV) {
        _selectIV = [[UIImageView alloc] initWithFrame:CGRectMake(70, 4, 22, 22)];
        [self.backIV addSubview:_selectIV];
    }
    return _selectIV;
}

- (UILabel *)fileNameLbl {
    if (!_fileNameLbl) {
        _fileNameLbl = [[UILabel alloc] initWithFrame:CGRectMake(4, 98, 88, 22)];
        [_fileNameLbl setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:_fileNameLbl];
    }
    return _fileNameLbl;
}

- (void)setup {

}
@end
