//
//  WFCUJoinGroupRequestTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/23.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUJoinGroupRequestTableViewCell.h"
#import <SDWebImage/SDWebImage.h>
#import <WFChatClient/WFCChatClient.h>
#import "WFCUConfigManager.h"
#import "UILabel+YBAttributeTextTapAction.h"
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "WFCUImage.h"

@interface WFCUJoinGroupRequestTableViewCell()
@property (nonatomic, strong)UIImageView *portraitView;
@property (nonatomic, strong)UILabel *nameLabel;
@property (nonatomic, strong)UILabel *reasonLabel;
@property (nonatomic, strong)UIButton *acceptBtn;
@end

@implementation WFCUJoinGroupRequestTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self initSubViews];
}

- (void)initSubViews {
    for (UIView *view in self.contentView.subviews) {
        [view removeFromSuperview];
    }
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    self.separatorInset = UIEdgeInsetsMake(0, 76, 0, 0);
    self.portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 10, 40, 40)];
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(16 + 40 + 20, 11, width - 128, 16)];
    self.nameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:15];
    self.nameLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
    self.reasonLabel = [[UILabel alloc] initWithFrame:CGRectMake(16 + 40 + 20, 11 + 16 + 8, width - 128, 14)];
    self.reasonLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12];
    self.reasonLabel.textColor = [UIColor colorWithHexString:@"0xb3b3b3"];
    
    self.acceptBtn = [[UIButton alloc] initWithFrame:CGRectMake(width - (46 + 16), 16, 46, 28)];
    [self.acceptBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.acceptBtn setTitle:WFCString(@"Accept") forState:UIControlStateNormal];
    [self.acceptBtn setBackgroundColor:[UIColor colorWithHexString:@"0x4764DC"]];
    self.acceptBtn.layer.cornerRadius = 4.f;
    self.acceptBtn.layer.masksToBounds = YES;
    [self.acceptBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.acceptBtn.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12];
    
    [self.contentView addSubview:self.portraitView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.reasonLabel];
    [self.contentView addSubview:self.acceptBtn];
    
    [self.acceptBtn addTarget:self action:@selector(onAddBtn:) forControlEvents:UIControlEventTouchDown];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
}

- (void)onAddBtn:(id)sender {
    [self.delegate onAcceptBtn:self.joinGroupRequest.memberId inviterId:self.joinGroupRequest.requestUserId];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (WFCCUserInfo *userInfo in userInfoList) {
        if ([self.joinGroupRequest.memberId isEqualToString:userInfo.userId] || [self.joinGroupRequest.requestUserId isEqualToString:userInfo.userId]) {
            self.joinGroupRequest = _joinGroupRequest;
            break;
        }
    }
}

- (void)setJoinGroupRequest:(WFCCJoinGroupRequest *)joinRequest {
    _joinGroupRequest = joinRequest;
    WFCCUserInfo *invitee = [[WFCCIMService sharedWFCIMService] getUserInfo:joinRequest.memberId refresh:NO];
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[invitee.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]  placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
    
    
    NSString *text;
    int startPos = 0;
    if([joinRequest.memberId isEqualToString:joinRequest.requestUserId]) {
        text = [NSString stringWithFormat:@"%@ 请求加入群聊", invitee.readableName];
        startPos = 0;
    } else {
        WFCCUserInfo *inviter = [[WFCCIMService sharedWFCIMService] getUserInfo:joinRequest.requestUserId refresh:NO];
        
        text = [NSString stringWithFormat:@"%@ 邀请 %@ 加入群聊", inviter.readableName, invitee.readableName];
        startPos = (int)inviter.readableName.length+4;
    }
    
    int attrLength = (int)invitee.readableName.length;
    NSMutableAttributedString *attrtext = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16]}];
    [attrtext setAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16],
                          NSForegroundColorAttributeName : [UIColor blueColor]} range:NSMakeRange(startPos, attrLength)];
    
    self.nameLabel.attributedText = attrtext;
    __weak typeof(self) ws = self;
    [self.nameLabel yb_addAttributeTapActionWithRanges:@[NSStringFromRange(NSMakeRange(startPos, attrLength))] tapClicked:^(UILabel *label, NSString *string, NSRange range, NSInteger index) {
        [ws.delegate onViewUserInfo:joinRequest.memberId];
    }];
        
    if([WFCCUtilities isExternalTarget:joinRequest.memberId]) {
        NSString *domainId = [WFCCUtilities getExternalDomain:joinRequest.memberId];
        self.nameLabel.attributedText = [WFCCUtilities getExternal:domainId withName:self.nameLabel.text withColor:[WFCUConfigManager globalManager].externalNameColor withSize:12];
    }
    self.reasonLabel.text = joinRequest.reason;
    BOOL expired = NO;
    NSDate *date = [[NSDate alloc] init];
    if (date.timeIntervalSince1970*1000 - joinRequest.timestamp > 7 * 24 * 60 * 60 * 1000) {
        expired = YES;
    }
    if (joinRequest.status == 0 && !expired) {
        [self.acceptBtn setTitle:WFCString(@"Accept") forState:UIControlStateNormal];
        [self.acceptBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.acceptBtn setBackgroundColor:[UIColor colorWithHexString:@"0x4764DC"]];
        [self.acceptBtn setEnabled:YES];
    } else if (joinRequest.status == 1) {
        [self.acceptBtn setTitle:WFCString(@"Accepted") forState:UIControlStateNormal];
        [self.acceptBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self.acceptBtn setBackgroundColor:self.backgroundColor];
        [self.acceptBtn setEnabled:NO];
    } else if (joinRequest.status == 2) {
        [self.acceptBtn setTitle:WFCString(@"Rejected") forState:UIControlStateNormal];
        [self.acceptBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self.acceptBtn setBackgroundColor:self.backgroundColor];
        [self.acceptBtn setEnabled:NO];
    } else { //expired
        [self.acceptBtn setTitle:WFCString(@"Expired") forState:UIControlStateNormal];
        [self.acceptBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self.acceptBtn setBackgroundColor:self.backgroundColor];
        [self.acceptBtn setEnabled:NO];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
