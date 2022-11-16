//
//  WFCUSearchGroupTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/13.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUSearchGroupTableViewCell.h"
#import <SDWebImage/SDWebImage.h>
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "WFCUImage.h"

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
    WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:groupSearchInfo.groupInfo.target refresh:NO];
    self.haveMember.attributedText = nil;
    self.name.text = nil;
    
    if ((groupSearchInfo.marchType & GroupSearchMarchTypeMask_Member_Name) || (groupSearchInfo.marchType & GroupSearchMarchTypeMask_Member_Alias)) {
        NSMutableAttributedString *string;
        for (NSString *memberId in groupSearchInfo.marchedMemberNames) {
            if (groupSearchInfo.marchType & GroupSearchMarchTypeMask_Member_Alias) {
                WFCCGroupMember *member = [[WFCCIMService sharedWFCIMService] getGroupMember:groupSearchInfo.groupInfo.target memberId:memberId];
                if (member && [member.alias rangeOfString:groupSearchInfo.keyword].location != NSNotFound) {
                    string = [[NSMutableAttributedString alloc] initWithString:member.alias];
                    [string addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(0, string.length)];
                    [string addAttribute:NSUnderlineStyleAttributeName value:@YES range:NSMakeRange(0, string.length)];
                    break;
                }
            }
            
            if(string == nil && (groupSearchInfo.marchType & GroupSearchMarchTypeMask_Member_Name)) {
                WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:memberId refresh:NO];
                if (userInfo && [userInfo.displayName rangeOfString:groupSearchInfo.keyword].location != NSNotFound) {
                    string = [[NSMutableAttributedString alloc] initWithString:userInfo.displayName];
                    [string addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(0, string.length)];
                    [string addAttribute:NSUnderlineStyleAttributeName value:@YES range:NSMakeRange(0, string.length)];
                    break;
                }
            }
        }
        
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:WFCString(@"GroupMemberNameMatch")];
        if(string.length) {
            [attrStr appendAttributedString:string];
            if (groupSearchInfo.marchedMemberNames.count > 1) {
                [attrStr appendAttributedString:[[NSAttributedString alloc] initWithString:WFCString(@"Etc")]];
            }
        }
        self.haveMember.attributedText = attrStr;
    }
    
    if ((groupSearchInfo.marchType & GroupSearchMarchTypeMask_Group_Name) || (groupSearchInfo.marchType & GroupSearchMarchTypeMask_Group_Remark)) {
        NSString *groupName = groupSearchInfo.groupInfo.name;
        if(groupSearchInfo.groupInfo.remark.length) {
            if([groupSearchInfo.groupInfo.remark rangeOfString:groupSearchInfo.keyword].location != NSNotFound) {
                groupName = groupSearchInfo.groupInfo.remark;
            } else {
                groupName = [NSString stringWithFormat:@"%@(%@)", groupSearchInfo.groupInfo.remark, groupSearchInfo.groupInfo.name];
            }
        }
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:groupName];
        NSRange range = [groupName rangeOfString:groupSearchInfo.keyword];
        if(range.location != NSNotFound) {
            [string addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:range];
            [string addAttribute:NSUnderlineStyleAttributeName value:@YES range:range];
            self.name.attributedText = string;
        }
    } else {
        if (groupInfo.displayName.length == 0) {
            self.name.text = WFCString(@"GroupChat");
        } else {
            self.name.text = [NSString stringWithFormat:@"%@(%d)", groupInfo.displayName, (int)groupInfo.memberCount];
        }
    }
    
    if (groupInfo.portrait.length) {
        [self.portrait sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[WFCUImage imageNamed:@"group_default_portrait"]];
    } else {
        NSString *path = [WFCCUtilities getGroupGridPortrait:groupInfo.target width:80 generateIfNotExist:YES defaultUserPortrait:^UIImage *(NSString *userId) {
            return [WFCUImage imageNamed:@"PersonalChat"];
        }];
        
        if (path) {
            [self.portrait sd_setImageWithURL:[NSURL fileURLWithPath:path] placeholderImage:[WFCUImage imageNamed:@"group_default_portrait"]];
        }
    }
}

@end
