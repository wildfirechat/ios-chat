//
//  WFCUConfigManager.m
//  WFChatUIKit
//
//  Created by heavyrain lee on 2019/9/22.
//  Copyright © 2019 WF Chat. All rights reserved.
//

#import "WFCUConfigManager.h"
#import "UIColor+YH.h"
#import "UIFont+YH.h"
#import <WFChatClient/WFCChatClient.h>

static WFCUConfigManager *sharedSingleton = nil;

NSString *const WFCUFontScaleDidChangeNotification = @"WFCUFontScaleDidChangeNotification";

@implementation WFCUConfigManager

+ (WFCUConfigManager *)globalManager {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[WFCUConfigManager alloc] init];
                sharedSingleton.conversationFilesDir = @"ConversationResource";
                sharedSingleton.cellContentDict = [[NSMutableDictionary alloc] init];
            }
        }
    }
    return sharedSingleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _selectedTheme = [[NSUserDefaults standardUserDefaults] integerForKey:@"WFC_THEME_TYPE"];
        
        // 初始化 cell size 缓存（使用 NSCache 自动管理内存）
        _cellSizeCache = [[NSCache alloc] init];
        _cellSizeCache.countLimit = 500; // 最多缓存 500 个尺寸
        _cellSizeCache.totalCostLimit = 5 * 1024 * 1024; // 最多 5MB
        
        // Markdown 配置默认值
        _enableMarkdownSupport = YES;
        _markdownDisplayStrategy = 0; // 0: 自动检测
        
        // 文件类型限制默认值
        _disabledSendFileTypes = @[@"exe", @"bat", @"apk"];
        _disabledReceiveFileTypes = @[@"exe", @"bat", @"apk"];
        
        // 打开链接策略默认值：1 = 提醒确认
        _openLinkPolicy = 1;
        
        // 全局字体缩放默认值
        CGFloat savedFontScale = [[NSUserDefaults standardUserDefaults] doubleForKey:@"WFC_FONT_SCALE"];
        if (savedFontScale < 0.8 || savedFontScale > 1.5) {
            _fontScale = 1.0;
        } else {
            _fontScale = savedFontScale;
        }
        
        // 监听内存警告通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // 内存警告时清理所有缓存
    [self.cellSizeCache removeAllObjects];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setFontScale:(CGFloat)fontScale {
    fontScale = MAX(0.8, MIN(1.5, fontScale));
    if (_fontScale != fontScale) {
        _fontScale = fontScale;
        [[NSUserDefaults standardUserDefaults] setDouble:fontScale forKey:@"WFC_FONT_SCALE"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // 清理文本 cell 尺寸缓存，避免气泡高度沿用旧值
        [self.cellSizeCache removeAllObjects];
        
        // 立即更新所有已创建导航栏的标题字体，无需重启即可生效
        [self applyFontScaleToNavigationBars];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WFCUFontScaleDidChangeNotification object:nil];
    }
}

- (void)applyFontScaleToNavigationBars {
    UIFont *naviTitleFont = [UIFont scaledPingFangSCWithWeight:FontWeightStyleMedium size:18];
    NSDictionary *titleAttributes = @{
        NSForegroundColorAttributeName : [WFCUConfigManager globalManager].naviTextColor,
        NSFontAttributeName : naviTitleFont
    };
    
    // 更新全局 appearance，确保后续创建的导航栏也使用新字体
    UINavigationBar *appearanceBar = [UINavigationBar appearance];
    appearanceBar.titleTextAttributes = titleAttributes;
    if (@available(iOS 13, *)) {
        UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
        navBarAppearance.backgroundColor = [WFCUConfigManager globalManager].naviBackgroudColor;
        navBarAppearance.titleTextAttributes = titleAttributes;
        appearanceBar.standardAppearance = navBarAppearance;
        appearanceBar.scrollEdgeAppearance = navBarAppearance;
    }
    
    // 同步更新所有已存在的导航栏
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        [self updateNavigationBarInViewController:window.rootViewController withAttributes:titleAttributes];
    }
}

- (void)updateNavigationBarInViewController:(UIViewController *)vc withAttributes:(NSDictionary *)titleAttributes {
    if (!vc) return;
    
    if (vc.navigationController) {
        vc.navigationController.navigationBar.titleTextAttributes = titleAttributes;
        if (@available(iOS 13, *)) {
            vc.navigationController.navigationBar.standardAppearance.titleTextAttributes = titleAttributes;
            vc.navigationController.navigationBar.scrollEdgeAppearance.titleTextAttributes = titleAttributes;
        }
    }
    
    for (UIViewController *child in vc.childViewControllers) {
        [self updateNavigationBarInViewController:child withAttributes:titleAttributes];
    }
    
    [self updateNavigationBarInViewController:vc.presentedViewController withAttributes:titleAttributes];
}

+ (CGFloat)scaledSize:(CGFloat)baseSize {
    CGFloat scaled = baseSize * [WFCUConfigManager globalManager].fontScale;
    return MAX(8, scaled);
}

-(void)setSelectedTheme:(WFCUThemeType)themeType {
    _selectedTheme = themeType;
    
    [[NSUserDefaults standardUserDefaults] setInteger:themeType forKey:@"WFC_THEME_TYPE"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self setupNavBar];
}

- (void)setupNavBar {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    UIFont *naviTitleFont = [UIFont scaledPingFangSCWithWeight:FontWeightStyleMedium size:18];
    NSDictionary *titleAttributes = @{
        NSForegroundColorAttributeName : [WFCUConfigManager globalManager].naviTextColor,
        NSFontAttributeName : naviTitleFont
    };
    
    UINavigationBar *bar = [UINavigationBar appearance];
    bar.barTintColor = [WFCUConfigManager globalManager].naviBackgroudColor;
    bar.tintColor = [WFCUConfigManager globalManager].naviTextColor;
    bar.titleTextAttributes = titleAttributes;
    bar.barStyle = UIBarStyleDefault;
    
    if (@available(iOS 13, *)) {
        UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
        bar.standardAppearance = navBarAppearance;
        bar.scrollEdgeAppearance = navBarAppearance;
        navBarAppearance.backgroundColor = [WFCUConfigManager globalManager].naviBackgroudColor;
        navBarAppearance.titleTextAttributes = titleAttributes;
    }
    
    [[UITabBar appearance] setBarTintColor:[WFCUConfigManager globalManager].frameBackgroudColor];
    [UITabBar appearance].translucent = YES;
}

- (UIColor *)backgroudColor {
    if (_backgroudColor) {
        return _backgroudColor;
    }
    BOOL darkModel = NO;
    if (@available(iOS 13.0, *)) {
        if(UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            darkModel = YES;
        }
    }
    
    if (darkModel) {
        return [UIColor colorWithRed:33/255.f green:33/255.f blue:33/255.f alpha:1.0f];
    } else {
        if (self.selectedTheme == ThemeType_WFChat) {
            return [UIColor colorWithRed:243/255.f green:243/255.f blue:243/255.f alpha:1.0f];
        } else if (self.selectedTheme == ThemeType_White) {
            return [UIColor colorWithHexString:@"0xededed"];
        }
        return [UIColor whiteColor];
    }
}

- (UIColor *)frameBackgroudColor {
    if (_frameBackgroudColor) {
        return _frameBackgroudColor;
    }
    BOOL darkModel = NO;
    if (@available(iOS 13.0, *)) {
        if(UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            darkModel = YES;
        }
    }
    
    if (darkModel) {
        return [UIColor colorWithRed:39/255.f green:39/255.f blue:39/255.f alpha:1.0f];
    } else {
        return [UIColor colorWithRed:239/255.f green:239/255.f blue:239/255.f alpha:1.0f];
    }
}

- (UIColor *)textColor {
    if (_textColor) {
        return _textColor;
    }
    BOOL darkModel = NO;
    if (@available(iOS 13.0, *)) {
        if(UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            darkModel = YES;
        }
    }
    
    if (darkModel) {
        return [UIColor whiteColor];
    } else {
        return [UIColor colorWithHexString:@"0x1d1d1d"];
    }
}

- (UIColor *)naviBackgroudColor {
    if (_naviBackgroudColor) {
        return _naviBackgroudColor;
    }
    BOOL darkModel = NO;
    if (@available(iOS 13.0, *)) {
        if(UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            darkModel = YES;
        }
    }
    
    if (darkModel) {
        return [UIColor colorWithRed:39/255.f green:39/255.f blue:39/255.f alpha:1.0f];
    } else {
        if (self.selectedTheme == ThemeType_WFChat) {
            return [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:1];
        } else if(self.selectedTheme == ThemeType_White) {
            return [UIColor colorWithHexString:@"0xededed"];;
        }
        return [UIColor colorWithRed:239/255.f green:239/255.f blue:239/255.f alpha:1.0f];
    }
}

- (UIColor *)naviTextColor {
    if (_naviTextColor) {
        return _naviTextColor;
    }
    BOOL darkModel = NO;
    if (@available(iOS 13.0, *)) {
        if(UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            darkModel = YES;
        }
    }
    
    if (darkModel) {
        return [UIColor whiteColor];
    } else {
        if (self.selectedTheme == ThemeType_WFChat) {
            return [UIColor blackColor];
        } else if(self.selectedTheme == ThemeType_White) {
            [UIColor colorWithHexString:@"0c0c0c"];
        }
        return [UIColor blackColor];
    }
}

- (UIColor *)separateColor {
    if (_separateColor) {
        return _separateColor;
    }
    BOOL darkModel = NO;
    if (@available(iOS 13.0, *)) {
        if(UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            darkModel = YES;
        }
    }
    
    if (darkModel) {
        return [UIColor colorWithHexString:@"0x3f3f3f"];
    } else {
        return [UIColor colorWithHexString:@"0xe7e7e7"];
    }
    
}

- (UIColor *)externalNameColor {
    if(_externalNameColor) {
        return _externalNameColor;
    }
    
    return [UIColor colorWithHexString:@"0xF0A040"];
}

//file path document/conversationresource/conv_line/conv_type/conv_target/mediatype/
- (NSString *)cachePathOf:(WFCCConversation *)conversation mediaType:(WFCCMediaType)mediaType {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *path = [documentDirectory stringByAppendingPathComponent:self.conversationFilesDir];
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%d/%d/%@", conversation.line, (int)conversation.type, conversation.target]];
    
    NSString *type = @"general";
    if(mediaType == Media_Type_IMAGE) type = @"image";
    else if(mediaType == Media_Type_VOICE) type = @"voice";
    else if(mediaType == Media_Type_VIDEO) type = @"video";
    else if(mediaType == Media_Type_PORTRAIT) type = @"portrait";
    else if(mediaType == Media_Type_FAVORITE) type = @"favorite";
    else if(mediaType == Media_Type_STICKER) type = @"sticker";
    else if(mediaType == Media_Type_MOMENTS) type = @"moments";
    
    path = [path stringByAppendingPathComponent:type];

    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (void)registerCustomCell:(Class)cellCls forContent:(Class)msgContentCls {
    self.cellContentDict[@([msgContentCls getContentType])] = cellCls;
}

#pragma mark - 缓存清理

- (void)clearCellSizeCache {
    [self.cellSizeCache removeAllObjects];
}

- (void)clearAllCache {
    [self.cellSizeCache removeAllObjects];
    // 也可以在这里清理其他缓存
}

@end
