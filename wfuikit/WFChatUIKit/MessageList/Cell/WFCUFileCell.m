//
//  FileCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUFileCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"

@implementation WFCUFileCell
+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    return CGSizeMake(width*4/5, 50);
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    WFCCFileMessageContent *fileContent = (WFCCFileMessageContent *)model.message.content;
    
    NSString *ext = [[fileContent.name pathExtension] lowercaseString];
    
    
    CGRect bounds = self.contentArea.bounds;
    if (model.message.direction == MessageDirection_Send) {
        self.fileImageView.frame = CGRectMake(bounds.size.width - 40, 4, 36, 42);
        self.fileNameLabel.frame = CGRectMake(4, 4, bounds.size.width - 48, 22);
        self.sizeLabel.frame = CGRectMake(4, 30, bounds.size.width - 48, 15);
        self.sizeLabel.textAlignment = NSTextAlignmentLeft;
    } else {
        self.fileImageView.frame = CGRectMake(4, 4, 36, 42);
        self.fileNameLabel.frame = CGRectMake(44, 4, bounds.size.width - 48, 22);
        self.sizeLabel.frame = CGRectMake(44, 30, bounds.size.width - 48, 15);
        self.sizeLabel.textAlignment = NSTextAlignmentRight;
    }
    
    self.fileImageView.image = [WFCUUtilities imageForExt:ext];
    self.fileNameLabel.text = fileContent.name;
    self.sizeLabel.text = [WFCUUtilities formatSizeLable:fileContent.size];
}

- (UIView *)getProgressParentView {
    return self.fileImageView;
}

- (UIImageView *)fileImageView {
    if (!_fileImageView) {
        _fileImageView = [[UIImageView alloc] init];
        [self.contentArea addSubview:_fileImageView];
    }
    return _fileImageView;
}

- (UILabel *)fileNameLabel {
    if (!_fileNameLabel) {
        _fileNameLabel = [[UILabel alloc] init];
        _fileNameLabel.font = [UIFont systemFontOfSize:20];
        [_fileNameLabel setTextColor:[UIColor blackColor]];
        [self.contentArea addSubview:_fileNameLabel];
    }
    return _fileNameLabel;
}
- (UILabel *)sizeLabel {
    if (!_sizeLabel) {
        _sizeLabel = [[UILabel alloc] init];
        _sizeLabel.font = [UIFont systemFontOfSize:15];
        [self.contentArea addSubview:_sizeLabel];
    }
    return _sizeLabel;
}
@end
