//
//  CombineServices.h
//  WildFireChat
//
//  combine-server 统一业务服务（单类实现全部 4 个 UIKit 业务协议）：
//  由原 PollService / PanService / CollectionService / OrgService 合并而来。
//
//  职责：
//  1) 业务协议实现（投票/网盘/接龙/组织通讯录），实例赋给 WFCUConfigManager 的 4 个 provider；
//  2) combine 统一登录与会话状态（authToken / features 存于 NSUserDefaults）；
//  3) 业务请求统一网络核心（JSON POST，无 token 自动登录，401 自动清 token）。
//
//  配置入口仍是 WFCConfig 的 COMBINE_SERVER_ADDRESS（单地址）；本类只负责运行时逻辑。
//

#import <Foundation/Foundation.h>
#import <WFChatUIKit/WFChatUIKit.h>

NS_ASSUME_NONNULL_BEGIN

// features 收敛完成通知（user_login 返回的功能清单已应用），UI 可据此刷新入口显隐
extern NSString *const WFCCombineFeaturesDidUpdateNotification;

@interface CombineServices : NSObject <WFCUPollService, WFCUPanService, WFCUCollectionService, WFCUOrgServiceProvider>

+ (CombineServices *)sharedInstance;

#pragma mark - combine 统一登录与会话状态（自 WFCConfig 迁入）

// 当前全局 authToken（可能为空）
+ (NSString *)authToken;
// 已开启的功能码列表（如 @"poll"、"pan"）；未登录/未获取时为空
+ (NSArray *)features;
// features 已获取时按清单判断是否开启；未获取（空）视为可用（登录后收敛）
+ (BOOL)isFeatureEnabled:(NSString *)code;
// 保存登录结果（/api/user_login 响应的 token + features）
+ (void)saveAuth:(NSString *)token features:(nullable NSArray *)features;
// 仅清除全局登录态（token + features）；业务缓存清理见 clearAuthInfos
+ (void)clearAuth;
// 确保已登录：无 token 时用 IM authCode 调 user_login 一次（幂等，可重复调用）
+ (void)ensureLogin:(void(^)(BOOL ok))completion;

#pragma mark - 登出/清理

// 登出/切换账号/注销账号时调用：清空 combine 全局登录态与业务本地缓存（组织通讯录缓存）
- (void)clearAuthInfos;

@end

NS_ASSUME_NONNULL_END
