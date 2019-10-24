//
//  WFCUSearchGroupTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/13.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUSearchGroupTableViewCell.h"
#import "SDWebImage.h"

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

- (UIImageView *)portrait {
    if (!_portrait) {
        _portrait = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 52, 52)];
        [self.contentView addSubview:_portrait];
    }
    return _portrait;
}

- (UILabel *)name {
    if (!_name) {
        _name = [[UILabel alloc] initWithFrame:CGRectMake(72, 12, [UIScreen mainScreen].bounds.size.width - 64, 20)];
        [_name setFont:[UIFont systemFontOfSize:18]];
        [self.contentView addSubview:_name];
    }
    return _name;
}

- (UILabel *)haveMember {
    if (!_haveMember) {
        _haveMember = [[UILabel alloc] initWithFrame:CGRectMake(72, 36, [UIScreen mainScreen].bounds.size.width - 64, 19)];
        [_haveMember setFont:[UIFont systemFontOfSize:14]];
        _haveMember.textColor = [UIColor grayColor];
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
        
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:WFCString(@"GroupNameMatch")];
        [attrStr appendAttributedString:string];
        self.haveMember.attributedText = attrStr;
    }
    [self.portrait sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"group_default_portrait"]];
}

@end
