//
//  WFCUPadWorkspaceWelcomeViewController.m
//  WFChat UIKit
//

#import "WFCUPadWorkspaceWelcomeViewController.h"
#import "WFCUPadUtility.h"
#import "WFCUConfigManager.h"
#import "WFCUImage.h"
#import "Predefine.h"
#import "UIFont+YH.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>

@interface WFCUPadWorkspaceWelcomeViewController ()
@property (nonatomic, strong) UIViewController *workspaceViewController;

@property (nonatomic, strong) UIImageView *portraitView;
@property (nonatomic, strong) UILabel *greetingLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

@property (nonatomic, strong) UIView *dateCard;
@property (nonatomic, strong) UILabel *dayLabel;
@property (nonatomic, strong) UIView *dayBadge;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *hintLabel;
@end

@implementation WFCUPadWorkspaceWelcomeViewController

- (instancetype)initWithWorkspaceViewController:(UIViewController *)workspaceViewController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _workspaceViewController = workspaceViewController;
        //网页压在本页上面时（单栏形态），返回键只留一个光秃秃的箭头，与右栏欢迎页一致
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                                style:UIBarButtonItemStylePlain
                                                                               target:nil
                                                                               action:nil];
    }
    return self;
}

- (UIViewController *)wfcu_padDetailRootViewController {
    return self.workspaceViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;

    self.portraitView = [[UIImageView alloc] init];
    self.portraitView.layer.cornerRadius = 22;
    self.portraitView.layer.masksToBounds = YES;
    self.portraitView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.portraitView];

    self.greetingLabel = [[UILabel alloc] init];
    self.greetingLabel.font = [UIFont scaledBoldSystemFontOfSize:18];
    self.greetingLabel.textColor = [UIColor darkTextColor];
    [self.view addSubview:self.greetingLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.font = [UIFont scaledSystemFontOfSize:12];
    self.subtitleLabel.textColor = [UIColor grayColor];
    self.subtitleLabel.text = WFCString(@"WorkspaceWelcomeSubtitle");
    [self.view addSubview:self.subtitleLabel];

    self.dateCard = [[UIView alloc] init];
    self.dateCard.backgroundColor = [UIColor whiteColor];
    self.dateCard.layer.cornerRadius = 16;
    self.dateCard.layer.masksToBounds = YES;
    [self.view addSubview:self.dateCard];

    self.dayBadge = [[UIView alloc] init];
    self.dayBadge.backgroundColor = [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.1];
    self.dayBadge.layer.cornerRadius = 12;
    self.dayBadge.layer.masksToBounds = YES;
    [self.dateCard addSubview:self.dayBadge];

    self.dayLabel = [[UILabel alloc] init];
    self.dayLabel.font = [UIFont scaledBoldSystemFontOfSize:24];
    self.dayLabel.textColor = [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9];
    self.dayLabel.textAlignment = NSTextAlignmentCenter;
    [self.dayBadge addSubview:self.dayLabel];

    self.dateLabel = [[UILabel alloc] init];
    self.dateLabel.font = [UIFont scaledBoldSystemFontOfSize:14];
    self.dateLabel.textColor = [UIColor darkTextColor];
    [self.dateCard addSubview:self.dateLabel];

    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.font = [UIFont scaledSystemFontOfSize:12];
    self.hintLabel.textColor = [UIColor grayColor];
    self.hintLabel.text = WFCString(@"WorkspaceWelcomeHint");
    [self.dateCard addSubview:self.hintLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadContent];

    //单栏形态（iPad 的 Slide Over / 1/3 分屏）下没有右栏可以常驻，网页就是本 tab 的正文，
    //压在迎宾面板上面。变回双栏时由 WFCUPadSplitViewController 摘回右栏，不必在这里撤。
    if (![WFCUPadUtility isSplitLayoutActive]
        && self.workspaceViewController
        && !self.workspaceViewController.parentViewController
        && self.navigationController.viewControllers.count == 1) {
        [self.navigationController pushViewController:self.workspaceViewController animated:NO];
    }
}

- (void)reloadContent {
    WFCCUserInfo *me = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
    NSString *name = [me.displayName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *greeting = [self greetingText];
    self.greetingLabel.text = name.length ? [NSString stringWithFormat:@"%@，%@", greeting, name] : greeting;

    UIImage *placeholder = [WFCUImage imageNamed:@"PersonalChat"];
    if (me.portrait.length) {
        [self.portraitView sd_setImageWithURL:[NSURL URLWithString:me.portrait] placeholderImage:placeholder];
    } else {
        self.portraitView.image = placeholder;
    }

    NSDate *now = [NSDate date];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:now];
    self.dayLabel.text = [NSString stringWithFormat:@"%ld", (long)components.day];
    //日期格式交给系统按当前语言排，省掉一条各语言都要自己拼的格式串
    self.dateLabel.text = [NSDateFormatter localizedStringFromDate:now
                                                         dateStyle:NSDateFormatterLongStyle
                                                         timeStyle:NSDateFormatterNoStyle];
    [self.view setNeedsLayout];
}

/// 问候语的分档与 flutter 的 PadWorkspaceWelcome 一致（6/12/14/18 四个分界）
- (NSString *)greetingText {
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    if (hour < 6) {
        return WFCString(@"GreetingNight");
    } else if (hour < 12) {
        return WFCString(@"GreetingMorning");
    } else if (hour < 14) {
        return WFCString(@"GreetingNoon");
    } else if (hour < 18) {
        return WFCString(@"GreetingAfternoon");
    }
    return WFCString(@"GreetingEvening");
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGRect visible = self.view.bounds;
    if (@available(iOS 11.0, *)) {
        visible = UIEdgeInsetsInsetRect(visible, self.view.safeAreaInsets);
    }
    CGFloat padding = 16;
    CGFloat left = CGRectGetMinX(visible) + padding;
    CGFloat width = MAX(CGRectGetWidth(visible) - padding * 2, 0);
    CGFloat top = CGRectGetMinY(visible) + padding;

    self.portraitView.frame = CGRectMake(left, top, 44, 44);
    CGFloat textLeft = CGRectGetMaxX(self.portraitView.frame) + 12;
    CGFloat textWidth = MAX(CGRectGetMaxX(visible) - padding - textLeft, 0);
    self.greetingLabel.frame = CGRectMake(textLeft, top + 2, textWidth, 22);
    self.subtitleLabel.frame = CGRectMake(textLeft, CGRectGetMaxY(self.greetingLabel.frame) + 2, textWidth, 16);

    CGFloat cardTop = CGRectGetMaxY(self.portraitView.frame) + padding;
    self.dateCard.frame = CGRectMake(left, cardTop, width, 88);
    self.dayBadge.frame = CGRectMake(padding, padding, 56, 56);
    self.dayLabel.frame = self.dayBadge.bounds;
    CGFloat cardTextLeft = CGRectGetMaxX(self.dayBadge.frame) + padding;
    CGFloat cardTextWidth = MAX(width - padding - cardTextLeft, 0);
    self.dateLabel.frame = CGRectMake(cardTextLeft, padding + 8, cardTextWidth, 20);
    self.hintLabel.frame = CGRectMake(cardTextLeft, CGRectGetMaxY(self.dateLabel.frame) + 4, cardTextWidth, 16);
}

@end
