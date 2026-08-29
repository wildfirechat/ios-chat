//
//  SwitchTableViewCell.m
//  WildFireChat
//
//  Created by heavyrain lee on 27/12/2017.
//  Copyright © 2017 WildFireChat. All rights reserved.
//

#import "WFCUGeneralSwitchTableViewCell.h"
#import "MBProgressHUD.h"


@interface WFCUGeneralSwitchTableViewCell()
@end

@implementation WFCUGeneralSwitchTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        self.valueSwitch = [[UISwitch alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 72, 8, 64, 40)];
        [self.contentView addSubview:self.valueSwitch];
        [self.valueSwitch addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

//开关是在 init 里按屏幕宽定的位置，双栏下 cell 比屏幕窄，它会跑到栏外看不见。
//这里按 cell 自己的宽度纠回来 —— iPhone 上 cell 宽恒等于表宽、表宽恒等于屏幕宽，与原来同一个数。
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.valueSwitch.frame;
    frame.origin.x = self.bounds.size.width - 72;
    self.valueSwitch.frame = frame;
}

- (void)onSwitch:(id)sender {
    BOOL value = _valueSwitch.on;
    __weak typeof(self)ws = self;
    if (self.onSwitch) {
        self.onSwitch(value, self.type, ^(BOOL success) {
            if (success) {
                [ws.valueSwitch setOn:value];
            } else {
                [ws.valueSwitch setOn:!value];
            }
        });
    }
}

- (void)setOn:(BOOL)on {
    _on = on;
    [self.valueSwitch setOn:on];
}
@end
