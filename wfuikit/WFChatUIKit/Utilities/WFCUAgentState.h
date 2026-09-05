//
//  WFCUAgentState.h
//  WFChatUIKit
//
//  Agent 会话运行时状态工具（scope=31 会话级用户设置）。
//  运行状态 type=1：机器人把 {state, phase, toolName, model, ...} JSON 写到
//  "<convType>-<line>-<target>_1_<机器人uid>"；Token 统计 type=2（独立通道）：
//  回合结束必推 {usage, turn, context, cacheHitRatePct, speed, metricsAt}，
//  独立于状态推送（含出错/取消）；AI 面板数据 type=3（组合查询结果）：
//  打开面板发 Agent_Command(207) query 后插件聚合 {model, effort, sandbox, plan,
//  cwd, sessionId, dirs} 写入，操作（207 set）后插件写 type=1 lastChange 并刷新 type=3。
//  server 统一在 scope=31 key 尾部追加机器人 uid（无旧式无后缀 key），读取不做精确
//  key 匹配：全量读 scope=31（getUserSettings:）后取首个 key 以
//  "<convType>-<line>-<target>_<type>_" 前缀开头的条目（agentStateKey: 等返回该前缀）。
//  多机器人：listAgentRobotUids:/agentRobotStates:/agentPanelData:robotUid: 按完整 uid
//  后缀扫描/精确匹配（uid 形如 robot_xxx_yyy，勿截断），每机器人一条
//  entry（1 状态/2 计量/3 面板）。
//  群成员以会话级用户设置收到；会话判断依据：conversation.line == 2
//  （AI 消息统一使用 line 2，普通消息 line 0、朋友圈 line 1）。
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

NS_ASSUME_NONNULL_BEGIN

//卡片点击"自定义回答"后聚焦会话主输入框（object 为会话）
extern NSString *const WFCUAgentFocusInputNotification;
//卡片点击"查看计划"后 push 全屏计划详情页（userInfo: conversation/qid/questionId/plan/approveLabel/rejectLabel）
extern NSString *const WFCUAgentShowPlanDetailNotification;
//某提问卡片已作答（本地立即置灰用，userInfo: qid）
extern NSString *const WFCUAgentAnsweredNotification;

@interface WFCUAgentState : NSObject

/// 状态 key 前缀："{conversationType}-{line}-{target}_1_"（server 追加机器人 uid 后缀）
+ (NSString *)agentStateKey:(WFCCConversation *)conversation;

/// 计量 key 前缀："{conversationType}-{line}-{target}_2_"（Token 统计，独立于运行状态）
+ (NSString *)agentMetricsKey:(WFCCConversation *)conversation;

/// AI 面板 key 前缀："{conversationType}-{line}-{target}_3_"（组合查询结果，面板打开/更新后刷新）
+ (NSString *)agentPanelKey:(WFCCConversation *)conversation;

/// AI/Agent 会话类型：'single'（line 2 单聊）/ 'group'（line 2 群聊）/ nil（非 AI 会话）。
/// 判断依据：conversation.line == 2（AI 消息统一使用 line 2，普通消息 line 0，朋友圈 line 1）。
+ (nullable NSString *)agentConversationKind:(WFCCConversation *)conversation;

/// 是否 Agent/AI 会话：conversation.line == 2 即为 AI 会话（单聊/群聊均可）。
+ (BOOL)isAgentConversation:(WFCCConversation *)conversation;

/// 读取 Agent 运行时状态（scope=31 type=1，按 "<...>_1_" 前缀匹配带机器人 uid 的 key）。
/// 非 Agent 会话/未设置/非法时返回 nil。
+ (nullable NSDictionary *)agentState:(WFCCConversation *)conversation;

/// 读取 Agent Token 统计（scope=31 type=2 计量，按 "<...>_2_" 前缀匹配）。
/// 回合结束必推（含出错/取消），带 metricsAt 时间戳；未设置/非法时返回 nil。
+ (nullable NSDictionary *)agentMetrics:(WFCCConversation *)conversation;

/// 读取 AI 面板数据（scope=31 type=3，Agent_Command 207 query 组合查询结果，按 "<...>_3_" 前缀匹配）：
/// {model:{current,options[]}, effort:{current,options[]}, sandbox:{current,options[]},
///  plan:{on}, cwd, sessionId, dirs[]}。未设置/非法时返回 nil。
+ (nullable NSDictionary *)agentPanelData:(WFCCConversation *)conversation;

// ===================== 多机器人（多 agent）支持 =====================

/// 机器人显示名：取用户信息（displayName/name）；取不到时回退完整 uid
/// （不截断 robot_xxx_yyy 的多段 id，机器人 uid 由下划线拼接，勿取末段）。
+ (NSString *)agentRobotName:(NSString *)uid;

/// 列出会话内“有状态推送”的机器人 uid 列表（按 scope=31 type=1 条目 uid 后缀，去重排序）。
/// 说明：机器人首次在该会话活动（推送状态）后才会出现；AI 群（line==2 群聊）会
/// 按“机器人成员”兜底补齐（memberId 以 robot_/robot- 开头），让尚未推送过状态、
/// 但已在本群的机器人也能出现在选择列表。始终为空的会话按单机器人处理。
+ (NSArray<NSString *> *)listAgentRobotUids:(WFCCConversation *)conversation;

/// 读取会话内每个机器人的（type=1 状态 + type=2 计量），按机器人分组（uid 升序）。
/// 返回数组元素为 NSDictionary：{@"uid": uid, @"state": NSDictionary, @"metrics": NSDictionary?}；
/// 无有效状态（state 缺失）的 uid 不返回；非 Agent 会话返回空数组。
+ (NSArray<NSDictionary *> *)agentRobotStates:(WFCCConversation *)conversation;

/// 读取指定机器人的 type=3 面板数据；robotUid 非空时精确匹配
/// "<...>_3_<robotUid>" key，为空时取会话默认（首个 "<...>_3_" 前缀条目，兼容旧版）。
/// 未设置/非法时返回 nil。
+ (nullable NSDictionary *)agentPanelData:(WFCCConversation *)conversation
                                 robotUid:(nullable NSString *)robotUid;

/// 状态文案：空闲/运行中/等待确认/已完成，未知返回 nil
+ (nullable NSString *)stateText:(nullable NSString *)state;

/// Token/上下文计量一行文本（各段用 " · " 连接），输入为 type=2 统计对象
/// （agentMetrics: 的返回值），只输出统计段：
/// 上下文 x% / 缓存 y% / z tok/s / 本轮 n tok / 累计 m tok；无任何计量字段时返回空字符串。
+ (NSString *)agentMetricsText:(nullable NSDictionary *)metrics;

/// 运行态提示（type=1 状态）：waiting_user → 🤔 等待确认 / 🔐 等待审批
/// （interaction=approval）；reason=error → ⚠️ 错误；reason=cancelled → 已取消。
/// 无提示返回空字符串。
+ (NSString *)agentStatusHint:(nullable NSDictionary *)state;

/// 状态圆点颜色：running=主色，waiting_user=#f59e0b，done=#22c55e，idle/其他=#22c55e（可继续输入）
+ (UIColor *)stateColor:(nullable NSString *)state;

/// 目标阶段颜色：active=#22c55e，paused=#94a3b8，blocked=红，complete=主色
+ (UIColor *)goalPhaseColor:(nullable NSString *)phase;

/// 目标阶段文案
+ (NSString *)goalPhaseText:(nullable NSString *)phase;

/// 主题主色
+ (UIColor *)accentColor;

/// '/' 命令集（@{命令: 说明}，有序）。单聊与群聊命令集不同；非 Agent 会话返回 nil。
/// 群聊仅保留 help/stop/群管理（members/kick/invite/mute/unmute）——
/// model/effort/cwd/sandbox/plan/compact/reset/ls 已被 AI 设置面板（207 静默通道）覆盖。
+ (nullable NSArray<NSDictionary<NSString *, NSString *> *> *)agentCommands:(WFCCConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
