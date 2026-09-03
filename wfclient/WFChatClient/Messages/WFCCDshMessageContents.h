//
//  WFCCDshMessageContents.h
//  WFChatClient
//
//  DSH × Wildfire 结构化交互消息内容类（200-208，官方预留 AI 交互段）。
//
//  Payload 约定:
//    payload.content           = JSON 字符串（结构化数据）
//    payload.searchableContent = 摘要文本（会话列表/通知显示）
//
//  卡片的 state 字段（pending/answered/approved/rejected/expired）驱动按钮可用性，
//  由发送方（机器人）通过 updateMessage 更新。
//

#import "WFCCMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/// DSH 消息内容基类：payload.content = JSON 字符串，persist flag = PERSIST(1)
@interface WFCCAgentMessageContentBase : WFCCMessageContent
+ (NSDictionary *)decodeJsonDict:(WFCCMessagePayload *)payload;
- (void)encodeJsonDict:(NSDictionary *)dict payload:(WFCCMessagePayload *)payload digest:(NSString *)digest;
@end

/// DSH 提问卡片（机器人→用户），MessageContentType: 200
@interface WFCCAgentQuestionMessageContent : WFCCAgentMessageContentBase
/// 提问ID
@property (nonatomic, strong) NSString *qid;
/// 问题列表，元素为 NSDictionary：{id, header, question, detail, options:[{label}], multiSelect, intent:{kind, approve}}
@property (nonatomic, strong) NSArray<NSDictionary *> *questions;
/// 状态：pending/answered/expired
@property (nonatomic, strong) NSString *state;
/// 用户回答（服务端 updateMessage 回填，只读）：元素为 NSDictionary：{id, selected:[label], custom}
@property (nonatomic, strong) NSArray<NSDictionary *> *answers;
@end

/// DSH 用户回答（用户→机器人），MessageContentType: 201
@interface WFCCAgentAnswerMessageContent : WFCCAgentMessageContentBase
/// 提问ID
@property (nonatomic, strong) NSString *qid;
/// 回答列表，元素为 NSDictionary：{id, selected:[label], custom}
@property (nonatomic, strong) NSArray<NSDictionary *> *answers;
@end

/// DSH 工具审批卡片（机器人→用户），MessageContentType: 202
@interface WFCCAgentApprovalMessageContent : WFCCAgentMessageContentBase
/// 审批ID
@property (nonatomic, strong) NSString *aid;
/// 工具名
@property (nonatomic, strong) NSString *toolName;
/// 审批原因
@property (nonatomic, strong, nullable) NSString *reason;
/// 状态：pending/approved/rejected/expired
@property (nonatomic, strong) NSString *state;
@end

/// DSH 审批结果（用户→机器人），MessageContentType: 203
@interface WFCCAgentApprovalResultMessageContent : WFCCAgentMessageContentBase
/// 审批ID
@property (nonatomic, strong) NSString *aid;
/// 动作：approve/reject
@property (nonatomic, strong) NSString *action;
@end

/// DSH 目标进度卡片，MessageContentType: 206
/// v1 字段：{gid, objective, phase, roundsStarted}；
/// ver:2 兼容：服务端可能发 {ver:2, gid, title, state, stage, updatedAt, ...}（仍可能带 v1 字段）——
/// objective 缺省回退读 title；phase 缺省回退读 state（枚举字符串一致）；
/// stage 为 ver:2 阶段文本（如 "1/3"），存在时展示。
@interface WFCCAgentGoalMessageContent : WFCCAgentMessageContentBase
/// 目标ID
@property (nonatomic, strong) NSString *gid;
/// 目标内容（v1 objective；缺失时回退为 v2 title）
@property (nonatomic, strong) NSString *objective;
/// ver:2 目标标题（仅在 objective 缺失时作为回退源；可能为 nil）
@property (nonatomic, strong, nullable) NSString *title;
/// 阶段：active/paused/blocked/complete（v1 phase；缺失时回退为 v2 state）
@property (nonatomic, strong) NSString *phase;
/// ver:2 阶段文本（如 "1/3"）；存在时展示在卡片/摘要，v1 载荷为 nil
@property (nonatomic, strong, nullable) NSString *stage;
/// 已执行轮数
@property (nonatomic, assign) NSInteger roundsStarted;
@end

/// DSH 任务进度卡片（机器人→用户），MessageContentType: 208
/// 插件派生子任务/后台任务时以 sendCard 首推、updateMessage 原地更新；
/// content = {tasks:[{kind:"subagent|job", id, label?, status, reason?, updatedAt}], updatedAt}
/// status: running / done / completed / failed / killed
@interface WFCCAgentTaskProgressMessageContent : WFCCAgentMessageContentBase
/// 任务列表，元素为 NSDictionary：{kind, id, label?, status, reason?, updatedAt}
@property (nonatomic, strong) NSArray<NSDictionary *> *tasks;
/// 更新时间戳（毫秒）
@property (nonatomic, assign) long long updatedAt;
@end

/// DSH 命令消息（用户→机器人），MessageContentType: 207
/// AI 面板静默指令（静默通道）：透明消息（不存储、不计未读、不多端同步），
/// digest 为空、不显示在消息流；payload.content = JSON 字符串
/// {"op":"query"|"set","cmd":"/model xxx","seq":123}。
/// op=query：组合查询（插件聚合面板数据写 scope=31 type=3，不回复消息）；
/// op=set：更新（cmd 为命令文本，如 "/model deepseek-official/xxx"）。
@interface WFCCAgentCommandMessageContent : WFCCAgentMessageContentBase
/// 操作：query=组合查询 / set=执行命令更新
@property (nonatomic, strong) NSString *op;
/// 命令文本（op=set 时，如 "/model xxx"、" /effort high"、" /cwd server"）；query 时为 nil
@property (nonatomic, strong, nullable) NSString *cmd;
/// 序号（防重/追踪，客户端自增）
@property (nonatomic, assign) NSInteger seq;
@end

NS_ASSUME_NONNULL_END
