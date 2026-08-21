//
//  WFCCDshMessageContents.h
//  WFChatClient
//
//  DSH × Wildfire 结构化交互消息内容类（200-206，官方预留 AI 交互段）。
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
@interface WFCCDshMessageContentBase : WFCCMessageContent
+ (NSDictionary *)decodeJsonDict:(WFCCMessagePayload *)payload;
- (void)encodeJsonDict:(NSDictionary *)dict payload:(WFCCMessagePayload *)payload digest:(NSString *)digest;
@end

/// DSH 提问卡片（机器人→用户），MessageContentType: 200
@interface WFCCDshQuestionMessageContent : WFCCDshMessageContentBase
/// 提问ID
@property (nonatomic, strong) NSString *qid;
/// 问题列表，元素为 NSDictionary：{id, header, question, detail, options:[{label}], multiSelect, intent:{kind, approve}}
@property (nonatomic, strong) NSArray<NSDictionary *> *questions;
/// 状态：pending/answered/expired
@property (nonatomic, strong) NSString *state;
@end

/// DSH 用户回答（用户→机器人），MessageContentType: 201
@interface WFCCDshAnswerMessageContent : WFCCDshMessageContentBase
/// 提问ID
@property (nonatomic, strong) NSString *qid;
/// 回答列表，元素为 NSDictionary：{id, selected:[label], custom}
@property (nonatomic, strong) NSArray<NSDictionary *> *answers;
@end

/// DSH 工具审批卡片（机器人→用户），MessageContentType: 202
@interface WFCCDshApprovalMessageContent : WFCCDshMessageContentBase
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
@interface WFCCDshApprovalResultMessageContent : WFCCDshMessageContentBase
/// 审批ID
@property (nonatomic, strong) NSString *aid;
/// 动作：approve/reject
@property (nonatomic, strong) NSString *action;
@end

/// DSH 目标进度卡片，MessageContentType: 206
@interface WFCCDshGoalMessageContent : WFCCDshMessageContentBase
/// 目标ID
@property (nonatomic, strong) NSString *gid;
/// 目标内容
@property (nonatomic, strong) NSString *objective;
/// 阶段：active/paused/blocked/complete
@property (nonatomic, strong) NSString *phase;
/// 已执行轮数
@property (nonatomic, assign) NSInteger roundsStarted;
@end

NS_ASSUME_NONNULL_END
