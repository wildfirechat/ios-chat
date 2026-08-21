//
//  WFCUDshState.h
//  WFChatUIKit
//
//  DSH 会话运行时状态工具（scope=31 会话级用户设置，key 后缀 _1 表示状态）。
//  机器人把 {state, phase, toolName, model, ...} JSON 写到
//  "<convType>-<line>-<target>_1"，群成员以会话级用户设置收到。
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

NS_ASSUME_NONNULL_BEGIN

//卡片点击"自定义回答"后聚焦会话主输入框（object 为会话）
extern NSString *const WFCUDshFocusInputNotification;
//卡片点击"查看计划"后 push 全屏计划详情页（userInfo: conversation/qid/questionId/plan/approveLabel/rejectLabel）
extern NSString *const WFCUDshShowPlanDetailNotification;
//某提问卡片已作答（本地立即置灰用，userInfo: qid）
extern NSString *const WFCUDshAnsweredNotification;

@interface WFCUDshState : NSObject

/// 状态 key："{conversationType}-{line}-{target}_1"
+ (NSString *)dshStateKey:(WFCCConversation *)conversation;

/// 群 extra 是否带 {"dsh":true} 标记（容错：非 JSON 返回 NO）
+ (BOOL)isDshGroupExtra:(nullable NSString *)extra;

/// 是否 DSH 会话：单聊=对方 userInfo.type==1（机器人）；群聊=groupInfo.extra 含 dsh:true。
/// 本地未缓存到 user/group info 时返回 NO，待 kUserInfoUpdated/kGroupInfoUpdated 后重新判定。
+ (BOOL)isDshConversation:(WFCCConversation *)conversation;

/// 读取 DSH 运行时状态。非 DSH 会话/未设置/非法时返回 nil。
+ (nullable NSDictionary *)dshState:(WFCCConversation *)conversation;

/// 状态文案：空闲/运行中/等待确认/已完成，未知返回 nil
+ (nullable NSString *)stateText:(nullable NSString *)state;

/// 状态圆点颜色：running=主色，waiting_user=#f59e0b，done=#22c55e，其他=#94a3b8
+ (UIColor *)stateColor:(nullable NSString *)state;

/// 目标阶段颜色：active=#22c55e，paused=#94a3b8，blocked=红，complete=主色
+ (UIColor *)goalPhaseColor:(nullable NSString *)phase;

/// 目标阶段文案
+ (NSString *)goalPhaseText:(nullable NSString *)phase;

/// 主题主色
+ (UIColor *)accentColor;

/// '/' 命令集（@{命令: 说明}，有序）。单聊与群聊命令集不同；非 DSH 会话返回 nil。
+ (nullable NSArray<NSDictionary<NSString *, NSString *> *> *)dshCommands:(WFCCConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
