//
//  WFCCAgentMessageContents.h
//  WFChatClient
//
//  Agent × Wildfire 结构化交互消息内容类（200-209，官方预留 AI 交互段）。
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

/// Agent 消息内容基类：payload.content = JSON 字符串，persist flag = PERSIST(1)
@interface WFCCAgentMessageContentBase : WFCCMessageContent
+ (NSDictionary *)decodeJsonDict:(WFCCMessagePayload *)payload;
- (void)encodeJsonDict:(NSDictionary *)dict payload:(WFCCMessagePayload *)payload digest:(NSString *)digest;
@end

/// Agent 提问卡片（机器人→用户），MessageContentType: 200
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

/// Agent 用户回答（用户→机器人），MessageContentType: 201
@interface WFCCAgentAnswerMessageContent : WFCCAgentMessageContentBase
/// 提问ID
@property (nonatomic, strong) NSString *qid;
/// 回答列表，元素为 NSDictionary：{id, selected:[label], custom}
@property (nonatomic, strong) NSArray<NSDictionary *> *answers;
@end

/// Agent 工具审批卡片（机器人→用户），MessageContentType: 202
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

/// Agent 审批结果（用户→机器人），MessageContentType: 203
@interface WFCCAgentApprovalResultMessageContent : WFCCAgentMessageContentBase
/// 审批ID
@property (nonatomic, strong) NSString *aid;
/// 动作：approve/reject
@property (nonatomic, strong) NSString *action;
@end

/// Agent 目标进度卡片，MessageContentType: 206
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

/// Agent 任务进度卡片（机器人→用户），MessageContentType: 208
/// 插件派生子任务/后台任务时以 sendCard 首推、updateMessage 原地更新；
/// content = {tasks:[{kind:"subagent|job", id, label?, status, reason?, updatedAt}], updatedAt}
/// status: running / done / completed / failed / killed
@interface WFCCAgentTaskProgressMessageContent : WFCCAgentMessageContentBase
/// 任务列表，元素为 NSDictionary：{kind, id, label?, status, reason?, updatedAt}
@property (nonatomic, strong) NSArray<NSDictionary *> *tasks;
/// 更新时间戳（毫秒）
@property (nonatomic, assign) long long updatedAt;
@end

/// Agent 命令消息（用户→机器人），MessageContentType: 207
/// AI 面板静默指令（静默通道）：透明消息（不存储、不计未读、不多端同步），
/// digest 为空、不显示在消息流；payload.content = JSON 字符串
/// {"op":"query"|"set","cmd":"/model xxx","seq":123,"robotId":"robot_xxx_yyy"(可选)}。
/// op=query：组合查询（插件聚合面板数据写 scope=31 type=3，不回复消息）；
/// op=set：更新（cmd 为命令文本，如 "/model deepseek-official/xxx"）。
/// robotId 存在时仅该机器人执行（多机器人会话寻址），为空则按会话默认机器人处理。
@interface WFCCAgentCommandMessageContent : WFCCAgentMessageContentBase
/// 操作：query=组合查询 / set=执行命令更新
@property (nonatomic, strong) NSString *op;
/// 命令文本（op=set 时，如 "/model xxx"、" /effort high"、" /cwd server"）；query 时为 nil
@property (nonatomic, strong, nullable) NSString *cmd;
/// 序号（防重/追踪，客户端自增）
@property (nonatomic, assign) NSInteger seq;
/// 目标机器人 uid（多机器人会话寻址，完整 robot_xxx_yyy，勿截断）；空 = 会话默认机器人
@property (nonatomic, strong, nullable) NSString *robotId;
@end

/// Agent 命令应答（机器人→用户），MessageContentType: 209
/// 207 Agent_Command 的应答通道（当前仅 op=dirs：目录列表按需获取）；透明消息
/// （不落库、不显示、不计数，digest 为空，与 207 一致）。
/// payload.content = JSON 字符串，v1：
/// {"ver":1, "op":"dirs", "seq":12345(回显请求 seq), "robotId":"robot_xxx_yyy"(可选),
///  "cwd":"/abs/current/dir"(可选), "root":"/abs/root"(可选),
///  "dirs":["a","b"], "total":194(可选), "truncated":false(可选)}
/// dirs 为目录名（非全路径），按名称升序；root 为其父目录。
/// 客户端必须按 seq 关联 pending 请求：seq 不匹配或已超时的应答直接丢弃。
@interface WFCCAgentCommandResultMessageContent : WFCCAgentMessageContentBase
/// 协议版本（当前 1）
@property (nonatomic, assign) NSInteger ver;
/// 应答对应的指令 op（当前仅 dirs）
@property (nonatomic, strong) NSString *op;
/// 回显请求的 seq（客户端据此关联 pending 请求）
@property (nonatomic, assign) NSInteger seq;
/// 应答机器人 uid（多机器人会话寻址，可能为空）
@property (nonatomic, strong, nullable) NSString *robotId;
/// 机器人当前工作目录（可能为空）
@property (nonatomic, strong, nullable) NSString *cwd;
/// 目录列表根目录（dirs 的父目录，可能为空）
@property (nonatomic, strong, nullable) NSString *root;
/// 目录名列表（非全路径，按名称升序；无则空数组，非 nil）
@property (nonatomic, strong) NSArray<NSString *> *dirs;
/// 总条数（0 = 未提供）
@property (nonatomic, assign) NSInteger total;
/// 是否被截断（插件侧上限 3000 条）
@property (nonatomic, assign) BOOL truncated;
@end

NS_ASSUME_NONNULL_END
