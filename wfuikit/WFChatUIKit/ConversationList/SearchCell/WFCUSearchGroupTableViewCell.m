//
//  WFCUSearchGroupTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/13.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUSearchGroupTableViewCell.h"
#import "SDWebImage.h"
#import "UIFont+YH.h"
#import "UIColor+YH.h"
@interface WFCUSearchGroupTableViewCell()
@property (strong, nonatomic) UIImageView *portrait;
@property (strong, nonatomic) UILabel *name;
@property (strong, nonatomic) UILabel *haveMember;

@end

@implementation WFCUSearchGroupTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat postionY = (self.frame.size.height - 40) / 2.0;
    self.portrait.frame = CGRectMake(16, postionY, 40, 40);
    self.name.frame = CGRectMake(10 + 40 + 20, postionY, [UIScreen mainScreen].bounds.size.width - (10 + 40 + 20), 20);
    postionY += 15 + 8;
    self.haveMember.frame  = CGRectMake(10 + 40 + 20, postionY, [UIScreen mainScreen].bounds.size.width - (10 + 40 + 20), 19);

}

- (UIImageView *)portrait {
    if (!_portrait) {
        _portrait = [UIImageView new];
        _portrait.layer.cornerRadius = 4;
        _portrait.layer.masksToBounds = YES;
        [self.contentView addSubview:_portrait];
    }
    return _portrait;
}

- (UILabel *)name {
    if (!_name) {
        _name = [UILabel new];
        [_name setFont:[UIFont pingFangSCWithWeight:FontWeightStyleRegular size:15]];
        _name.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
        [self.contentView addSubview:_name];
    }
    return _name;
}

- (UILabel *)haveMember {
    if (!_haveMember) {
        _haveMember = [UILabel new];
        [_haveMember setFont:[UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12]];
        _haveMember.textColor = [UIColor colorWithHexString:@"0xb3b3b3"];
        [self.contentView addSubview:_haveMember];
    }
    return _haveMember;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setGroupSearchInfo:(WFCCGroupSearchInfo *)groupSearchInfo {
    _groupSearchInfo = groupSearchInfo;
    WFCCGroupInfo *groupInfo = groupSearchInfo.groupInfo;
    if (groupInfo.name.length == 0) {
        self.name.text = WFCString(@"GroupChat");
    } else {
        self.name.text = [NSString stringWithFormat:@"%@(%d)", groupInfo.name, (int)groupInfo.memberCount];
    }
    if (groupSearchInfo.marchType > 0) {
        NSMutableAttributedString *string;
        for (NSString *memberId in groupSearchInfo.marchedMemberNames) {
            WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:memberId refresh:NO];
            if (userInfo) {
                string = [[NSMutableAttributedString alloc] initWithString:userInfo.displayName];
                [string addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(0, string.length)];
                [string addAttribute:NSUnderlineStyleAttributeName value:@YES range:NSMakeRange(0, string.length)];
                break;
            }
        }
        if (string == nil) {
            string = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@<%@>", WFCString(@"User"), groupSearchInfo.marchedMemberNames[0]]] mutableCopy];
        }
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:WFCString(@"GroupMemberNameMatch")];
        [attrStr appendAttributedString:string];
        if (groupSearchInfo.marchedMemberNames.count > 1) {
            [attrStr appendAttributedString:[[NSAttributedString alloc] initWithString:WFCString(@"Etc")]];
        }
        self.haveMember.attributedText = attrStr;
    } else {
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:groupSearchInfo.keyword];
        [string addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(0, string.length)];
        [string addAttribute:NSUnderlineStyleAttributeName value:@YES range:NSMakeRange(0, string.length)];
        
        [string addAttribute:NSFontAttributeName value:[UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12] range:NSMakeRange(0, string.length)];
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:WFCString(@"GroupNameMatch")];
        [attrStr appendAttributedString:string];
        self.haveMember.attributedText = attrStr;
    }
    [self.portrait sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"group_default_portrait"]];
}

@end
