//
//  FileCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUFileCell.h"
#import <WFChatClient/WFCChatClient.h>

@implementation WFCUFileCell
+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    return CGSizeMake(width*4/5, 50);
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    WFCCFileMessageContent *fileContent = (WFCCFileMessageContent *)model.message.content;
    
    NSString *ext = [[fileContent.name pathExtension] lowercaseString];
    NSString *fileImage = nil;
    if ([ext isEqualToString:@"doc"] || [ext isEqualToString:@"docx"] || [ext isEqualToString:@"pages"]) {
        fileImage = @"doc_image";
    } else if ([ext isEqualToString:@"xls"] || [ext isEqualToString:@"xlsx"] || [ext isEqualToString:@"numbers"]) {
        fileImage = @"xls_image";
    } else if ([ext isEqualToString:@"ppt"] || [ext isEqualToString:@"pptx"] || [ext isEqualToString:@"keynote"]) {
        fileImage = @"ppt_image";
    } else if ([ext isEqualToString:@"pdf"]) {
        fileImage = @"pdf_image";
    } else if([ext isEqualToString:@"html"] || [ext isEqualToString:@"htm"]) {
        fileImage = @"html_image";
    } else if([ext isEqualToString:@"txt"]) {
        fileImage = @"txt_image";
    } else if([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"png"]) {
        fileImage = @"img_image";
    }
    fileImage = @"file";
    
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
    
    self.fileImageView.image = [UIImage imageNamed:fileImage];
    self.fileNameLabel.text = fileContent.name;
    if (fileContent.size < 1024) {
        self.sizeLabel.text = [NSString stringWithFormat:@"%ldB", fileContent.size];
    } else if(fileContent.size < 1024*1024) {
        self.sizeLabel.text = [NSString stringWithFormat:@"%ldK", fileContent.size/1024];
    } else {
        self.sizeLabel.text = [NSString stringWithFormat:@"%.2fM", fileContent.size/1024.f/1024];
    }
    
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
