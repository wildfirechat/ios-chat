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
@property(nonatomic, strong)UISwitch *valueSwitch;
@end

@implementation WFCUGeneralSwitchTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        self.valueSwitch = [[UISwitch alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 56, 8, 40, 40)];
        [self addSubview:self.valueSwitch];
        [self.valueSwitch addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)onSwitch:(id)sender {
    BOOL value = _valueSwitch.on;
    __weak typeof(self)ws = self;
    self.onSwitch(value, ^(BOOL success) {
        if (success) {
            [ws.valueSwitch setOn:value];
        } else {
            [ws.valueSwitch setOn:!value];
        }
    });
}

- (void)setOn:(BOOL)on {
    _on = on;
    [self.valueSwitch setOn:on];
}
@end
