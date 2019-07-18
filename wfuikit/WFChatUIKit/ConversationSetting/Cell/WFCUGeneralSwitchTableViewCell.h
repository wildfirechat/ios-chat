//
//  SwitchTableViewCell.h
//  WildFireChat
//
//  Created by heavyrain lee on 27/12/2017.
//  Copyright © 2017 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUGeneralSwitchTableViewCell : UITableViewCell
@property(nonatomic, assign)BOOL on;
@property(nonatomic, strong)void (^onSwitch)(BOOL value, void (^)(BOOL success));
@end
