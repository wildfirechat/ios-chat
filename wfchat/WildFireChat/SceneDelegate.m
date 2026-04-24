//
//  SceneDelegate.m
//  WildFireChat
//

#import "SceneDelegate.h"
#import "AppDelegate.h"
#import "WFCBaseTabBarController.h"
#import "WFCLoginViewController.h"
#import "WFCConfig.h"
#import "TYHWaterMark.h"
#import "SSKeychain.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.backgroundColor = [UIColor whiteColor];
    
    NSString *savedToken = [SSKeychain passwordForWFService:@"savedToken"];
    NSString *savedUserId = [SSKeychain passwordForWFService:@"savedUserId"];
    if (!savedToken || !savedUserId) {
        savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedToken"];
        savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    }
    
    if (savedToken.length > 0 && savedUserId.length > 0) {
        self.window.rootViewController = [WFCBaseTabBarController new];
        if (ENABLE_WATER_MARKER) {
            [self.window addSubview:[TYHWaterMarkView new]];
            [TYHWaterMarkView setCharacter:savedUserId];
            [TYHWaterMarkView autoUpdateDate:YES];
        }
    } else {
        WFCLoginViewController *loginVC = [[WFCLoginViewController alloc] init];
        loginVC.isPwdLogin = Prefer_Password_Login;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
        self.window.rootViewController = nav;
    }
    
    [self.window makeKeyAndVisible];
    
    // 兼容旧代码中对 AppDelegate.window 的直接访问
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.window = self.window;
}

- (void)sceneDidDisconnect:(UIScene *)scene {
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
}

- (void)sceneWillResignActive:(UIScene *)scene {
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts API_AVAILABLE(ios(13.0)) {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    for (UIOpenURLContext *urlContext in URLContexts) {
        [appDelegate application:[UIApplication sharedApplication] handleOpenURL:urlContext.URL];
    }
}

@end
