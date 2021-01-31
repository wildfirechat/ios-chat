//
//  FileRecordTableViewCell.m
//  WFChatUIKit
//
//  Created by dali on 2020/10/29.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import "WFCUFileRecordTableViewCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"


@interface WFCUFileRecordTableViewCell ()
@property(nonatomic, strong)UIImageView *iconView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UILabel *infoLabel;
@end

@implementation WFCUFileRecordTableViewCell

+ (CGFloat)sizeOfRecord:(WFCCFileRecord *)record withCellWidth:(CGFloat)width {
    CGSize size1 = [WFCUUtilities getTextDrawingSize:record.name font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake(width - 74, 48)];
    
    NSString *info = [NSString stringWithFormat:@"%@ 来自%@ %@", [WFCUUtilities formatTimeLabel:record.timestamp], [[WFCCIMService sharedWFCIMService] getUserInfo:record.userId inGroup:record.conversation.type == Group_Type ? record.conversation.target : nil refresh:NO].displayName, [WFCUUtilities formatSizeLable:record.size]];
    
    
    CGSize size2 = [WFCUUtilities getTextDrawingSize:info font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(width - 74, 40)];
    
    return 8 + size1.height + 8 + size2.height + 8;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}

- (void)setFileIcon:(NSString *)fileName {
    NSString *ext = [[fileName pathExtension] lowercaseString];
    self.iconView.image = [WFCUUtilities imageForExt:ext];
}

- (void)setFileRecord:(WFCCFileRecord *)fileRecord {
    _fileRecord = fileRecord;
    
    [self setFileIcon:fileRecord.name];
    self.nameLabel.text = self.fileRecord.name;
    CGSize size = [WFCUUtilities getTextDrawingSize:self.fileRecord.name font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake([UIScreen mainScreen].bounds.size.width - 74, 48)];
    self.nameLabel.frame = CGRectMake(66, 8, size.width, size.height);
    
    NSString *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:fileRecord.userId inGroup:fileRecord.conversation.type == Group_Type ? fileRecord.conversation.target : nil refresh:NO].displayName;
    
    NSString *info = [NSString stringWithFormat:@"%@ 来自", [WFCUUtilities formatTimeLabel:fileRecord.timestamp]];
    
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:info];
    [attStr appendAttributedString:[[NSAttributedString alloc] initWithString:sender attributes:@{NSForegroundColorAttributeName : [UIColor blueColor]}]];
    [attStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", [WFCUUtilities formatSizeLable:fileRecord.size]]]];
    
    self.infoLabel.attributedText = attStr;
    
    size = [WFCUUtilities getTextDrawingSize:attStr.string font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(self.bounds.size.width - 74, 40)];
    self.infoLabel.frame = CGRectMake(66, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 8, size.width, size.height);
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UIImageView *)iconView {
    if (!_iconView) {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 50, 50)];
        [self.contentView addSubview:_iconView];
    }
    return _iconView;;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:18];
        _nameLabel.numberOfLines = 0;
        [self.contentView addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (UILabel *)infoLabel {
    if (!_infoLabel) {
        _infoLabel = [[UILabel alloc] init];
        _infoLabel.font = [UIFont systemFontOfSize:14];
        _infoLabel.numberOfLines = 0;
        _infoLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:_infoLabel];
    }
    return _infoLabel;
}
@end
