//
//  WFCUPadPlaceholderViewController.m
//  WFChat UIKit
//

#import "WFCUPadPlaceholderViewController.h"
#import "WFCUImage.h"
#import "WFCUConfigManager.h"

@interface WFCUPadPlaceholderViewController ()
@property (nonatomic, strong) UIImageView *logoView;
@end

@implementation WFCUPadPlaceholderViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //压在欢迎页上面的页面（会话、资料…）由系统自动生成返回键，标题取自欢迎页。
        //欢迎页没有标题，不设的话会长出一个"Back"/"返回"字样；android 那边是个光秃秃的箭头，对齐它。
        //必须在这里设而不是 viewDidLoad：欢迎页压在栈底时视图根本不会加载，
        //返回键却已经由它上面那一页画出来了。
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                                style:UIBarButtonItemStylePlain
                                                                               target:nil
                                                                               action:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;

    self.logoView = [[UIImageView alloc] initWithImage:[self placeholderImage]];
    self.logoView.contentMode = UIViewContentModeScaleAspectFit;
    self.logoView.tintColor = [UIColor colorWithWhite:0.62 alpha:1.0];
    [self.view addSubview:self.logoView];
}

/// 空白页的图标。优先用系统的会话气泡符号，老系统退回到内置图标。
- (UIImage *)placeholderImage {
    if (@available(iOS 13.0, *)) {
        UIImage *symbol = [UIImage systemImageNamed:@"bubble.left.and.bubble.right.fill"];
        if (symbol) {
            return [symbol imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
    }
    return [[WFCUImage imageNamed:@"default_app_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    //iOS 26 起右栏是整屏满铺的，左栏悬浮在上面，可见区域要按安全区算，否则图标会跑到整屏正中
    CGRect visible = self.view.bounds;
    if (@available(iOS 11.0, *)) {
        visible = UIEdgeInsetsInsetRect(visible, self.view.safeAreaInsets);
    }
    CGFloat side = MIN(112, MIN(visible.size.width, visible.size.height) * 0.22);
    self.logoView.frame = CGRectMake(CGRectGetMidX(visible) - side / 2,
                                     CGRectGetMidY(visible) - side / 2,
                                     side,
                                     side);
}

@end
