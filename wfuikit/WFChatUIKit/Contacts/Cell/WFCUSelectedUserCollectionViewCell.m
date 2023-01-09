//
//  SelectedUserCollectionViewCell.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUSelectedUserCollectionViewCell.h"
#import <SDWebImage/SDWebImage.h>
#import "WFCUImage.h"
#import "WFCUOrganization.h"
#import "WFCUEmployee.h"

@implementation WFCUSelectedUserCollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.imgV];
    }
    return self;
}

- (void)setModel:(WFCUSelectModel *)model {
    if(model.userInfo) {
        [self.imgV sd_setImageWithURL:[NSURL URLWithString:[model.userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
    } else if(model.organization) {
        [self.imgV sd_setImageWithURL:[NSURL URLWithString:[model.organization.portraitUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [WFCUImage imageNamed:@"organization_icon"]];
    } else if(model.employee) {
        [self.imgV sd_setImageWithURL:[NSURL URLWithString:[model.employee.portraitUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [WFCUImage imageNamed:@"employee"]];
    }
}

- (void)setIsSmall:(BOOL)isSmall {
    if (isSmall) {
        self.imgV.layer.cornerRadius = 4;
    }
}



- (void)layoutSubviews {
    [super layoutSubviews];
    self.imgV.frame = self.bounds;
}

- (UIImageView *)imgV {
    if (!_imgV) {
        _imgV = [UIImageView new];
        _imgV.layer.cornerRadius = 8;
        _imgV.layer.masksToBounds = YES;
    }
    return _imgV;
}
@end
