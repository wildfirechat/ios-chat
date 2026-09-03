//
//  WFCCDshMessageContents.m
//  WFChatClient
//
//  DSH × Wildfire 结构化交互消息内容类实现。
//

#import "WFCCDshMessageContents.h"
#import "WFCCIMService.h"
#import "Common.h"

//官方预留 AI 交互段（200-209）
static const int AgentMessageContentTypeQuestion = 200;
static const int AgentMessageContentTypeAnswer = 201;
static const int AgentMessageContentTypeApproval = 202;
static const int AgentMessageContentTypeApprovalResult = 203;
static const int AgentMessageContentTypeGoal = 206;
static const int AgentMessageContentTypeCommand = 207;
static const int AgentMessageContentTypeTaskProgress = 208;

//取 dict 中首个非空 NSString 值（goal ver:2 兼容：v1 字段缺失时回退读取 v2 字段）
static NSString *firstNonEmptyString(NSDictionary *dict, NSArray<NSString *> *keys) {
    for (NSString *key in keys) {
        id value = dict[key];
        if ([value isKindOfClass:[NSString class]] && [value length]) {
            return value;
        }
    }
    return nil;
}

@implementation WFCCAgentMessageContentBase

+ (NSDictionary *)decodeJsonDict:(WFCCMessagePayload *)payload {
    if (payload.content.length == 0) {
        return @{};
    }
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[payload.content dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error || ![dict isKindOfClass:[NSDictionary class]]) {
        return @{};
    }
    return dict;
}

- (void)encodeJsonDict:(NSDictionary *)dict payload:(WFCCMessagePayload *)payload digest:(NSString *)digest {
    payload.contentType = [self.class getContentType];
    payload.searchableContent = digest;
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    if (!error) {
        payload.content = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

+ (int)getContentFlags {
    //与 PC 端一致：PERSIST(1)，不是 PERSIST_AND_COUNT
    return WFCCPersistFlag_PERSIST;
}

@end

@implementation WFCCAgentQuestionMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"qid"] = self.qid ?: @"";
    dict[@"questions"] = self.questions ?: @[];
    dict[@"state"] = self.state.length ? self.state : @"pending";
    [self encodeJsonDict:dict payload:payload digest:[self digest:nil]];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    NSDictionary *dict = [WFCCAgentMessageContentBase decodeJsonDict:payload];
    self.qid = dict[@"qid"];
    NSArray *questions = dict[@"questions"];
    self.questions = [questions isKindOfClass:[NSArray class]] ? questions : @[];
    self.state = dict[@"state"];
    //服务端 updateMessage 回填的用户选择；只读，不参与编码（客户端不发送提问卡片）
    NSArray *answers = dict[@"answers"];
    self.answers = [answers isKindOfClass:[NSArray class]] ? answers : @[];
}

+ (int)getContentType {
    return AgentMessageContentTypeQuestion;
}

- (NSString *)digest:(WFCCMessage *)message {
    NSDictionary *first = self.questions.firstObject;
    if (![first isKindOfClass:[NSDictionary class]]) {
        return @"🤔 需要你确认";
    }
    NSString *header = [first[@"header"] isKindOfClass:[NSString class]] ? first[@"header"] : nil;
    NSString *question = [first[@"question"] isKindOfClass:[NSString class]] ? first[@"question"] : @"";
    if (header.length) {
        return [NSString stringWithFormat:@"🤔 【%@】%@", header, question];
    }
    return [NSString stringWithFormat:@"🤔 %@", question.length ? question : @"需要你确认"];
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

@end

@implementation WFCCAgentAnswerMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"qid"] = self.qid ?: @"";
    dict[@"answers"] = self.answers ?: @[];
    [self encodeJsonDict:dict payload:payload digest:[self digest:nil]];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    NSDictionary *dict = [WFCCAgentMessageContentBase decodeJsonDict:payload];
    self.qid = dict[@"qid"];
    NSArray *answers = dict[@"answers"];
    self.answers = [answers isKindOfClass:[NSArray class]] ? answers : @[];
}

+ (int)getContentType {
    return AgentMessageContentTypeAnswer;
}

- (NSString *)digest:(WFCCMessage *)message {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (NSDictionary *answer in self.answers) {
        if (![answer isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSArray *selected = answer[@"selected"];
        if ([selected isKindOfClass:[NSArray class]] && selected.count) {
            [parts addObject:[selected componentsJoinedByString:@"、"]];
        } else if ([answer[@"custom"] isKindOfClass:[NSString class]] && [answer[@"custom"] length]) {
            [parts addObject:answer[@"custom"]];
        }
    }
    return parts.count ? [NSString stringWithFormat:@"已选择：%@", [parts componentsJoinedByString:@"；"]] : @"（已作答）";
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

@end

@implementation WFCCAgentApprovalMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"aid"] = self.aid ?: @"";
    dict[@"toolName"] = self.toolName ?: @"";
    if (self.reason.length) {
        dict[@"reason"] = self.reason;
    }
    dict[@"state"] = self.state.length ? self.state : @"pending";
    [self encodeJsonDict:dict payload:payload digest:[self digest:nil]];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    NSDictionary *dict = [WFCCAgentMessageContentBase decodeJsonDict:payload];
    self.aid = dict[@"aid"];
    self.toolName = dict[@"toolName"];
    self.reason = dict[@"reason"];
    self.state = dict[@"state"];
}

+ (int)getContentType {
    return AgentMessageContentTypeApproval;
}

- (NSString *)digest:(WFCCMessage *)message {
    NSString *toolName = self.toolName.length ? self.toolName : @"工具";
    if (self.reason.length) {
        return [NSString stringWithFormat:@"🔐 工具审批：%@（%@）", toolName, self.reason];
    }
    return [NSString stringWithFormat:@"🔐 工具审批：%@", toolName];
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

@end

@implementation WFCCAgentApprovalResultMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"aid"] = self.aid ?: @"";
    dict[@"action"] = self.action.length ? self.action : @"reject";
    [self encodeJsonDict:dict payload:payload digest:[self digest:nil]];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    NSDictionary *dict = [WFCCAgentMessageContentBase decodeJsonDict:payload];
    self.aid = dict[@"aid"];
    self.action = dict[@"action"];
}

+ (int)getContentType {
    return AgentMessageContentTypeApprovalResult;
}

- (NSString *)digest:(WFCCMessage *)message {
    return [self.action isEqualToString:@"approve"] ? @"（已同意）" : @"（已拒绝）";
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

@end

@implementation WFCCAgentGoalMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"gid"] = self.gid ?: @"";
    dict[@"objective"] = self.objective ?: @"";
    dict[@"phase"] = self.phase.length ? self.phase : @"active";
    dict[@"roundsStarted"] = @(self.roundsStarted);
    [self encodeJsonDict:dict payload:payload digest:[self digest:nil]];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    NSDictionary *dict = [WFCCAgentMessageContentBase decodeJsonDict:payload];
    self.gid = [dict[@"gid"] isKindOfClass:[NSString class]] ? dict[@"gid"] : nil;
    //ver:2 兼容：objective 缺省回退 title；phase 缺省回退 state（枚举字符串一致）
    self.objective = firstNonEmptyString(dict, @[@"objective", @"title"]);
    self.title = firstNonEmptyString(dict, @[@"title"]);
    self.phase = firstNonEmptyString(dict, @[@"phase", @"state"]);
    self.stage = firstNonEmptyString(dict, @[@"stage"]);
    self.roundsStarted = [dict[@"roundsStarted"] integerValue];
}

+ (int)getContentType {
    return AgentMessageContentTypeGoal;
}

- (NSString *)digest:(WFCCMessage *)message {
    //v1 载荷渲染不变；ver:2 缺省时回退 title，存在 stage 时附加展示
    NSString *objective = self.objective.length ? self.objective : (self.title.length ? self.title : @"目标");
    NSString *stage = self.stage.length ? [NSString stringWithFormat:@"，%@", self.stage] : @"";
    return [NSString stringWithFormat:@"🎯 %@（%@%@，round %d）", objective, self.phase ?: @"", stage, (int)self.roundsStarted];
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

@end

@implementation WFCCAgentTaskProgressMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"tasks"] = self.tasks ?: @[];
    dict[@"updatedAt"] = @(self.updatedAt);
    [self encodeJsonDict:dict payload:payload digest:[self digest:nil]];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    NSDictionary *dict = [WFCCAgentMessageContentBase decodeJsonDict:payload];
    NSArray *tasks = dict[@"tasks"];
    self.tasks = [tasks isKindOfClass:[NSArray class]] ? tasks : @[];
    self.updatedAt = [dict[@"updatedAt"] longLongValue];
}

+ (int)getContentType {
    return AgentMessageContentTypeTaskProgress;
}

- (NSString *)digest:(WFCCMessage *)message {
    //与 PC 端 searchableContent 一致："🧩 任务 N（M 运行中）" / "🧩 任务 N（全部完成）" / "🧩 任务：无"
    NSInteger running = 0;
    for (NSDictionary *task in self.tasks) {
        if ([task isKindOfClass:[NSDictionary class]] && [task[@"status"] isEqualToString:@"running"]) {
            running++;
        }
    }
    if (self.tasks.count == 0) {
        return @"🧩 任务：无";
    }
    if (running > 0) {
        return [NSString stringWithFormat:@"🧩 任务 %lu（%ld 运行中）", (unsigned long)self.tasks.count, (long)running];
    }
    return [NSString stringWithFormat:@"🧩 任务 %lu（全部完成）", (unsigned long)self.tasks.count];
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

@end

@implementation WFCCAgentCommandMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"op"] = self.op.length ? self.op : @"query";
    if (self.cmd.length) {
        dict[@"cmd"] = self.cmd;
    }
    dict[@"seq"] = @(self.seq);
    [self encodeJsonDict:dict payload:payload digest:@""];
    //透明消息：不携带可搜索/推送内容
    payload.searchableContent = @"";
    payload.pushContent = @"";
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    NSDictionary *dict = [WFCCAgentMessageContentBase decodeJsonDict:payload];
    self.op = [dict[@"op"] isKindOfClass:[NSString class]] && [dict[@"op"] length] ? dict[@"op"] : @"query";
    self.cmd = [dict[@"cmd"] isKindOfClass:[NSString class]] ? dict[@"cmd"] : nil;
    self.seq = [dict[@"seq"] integerValue];
}

+ (int)getContentType {
    return AgentMessageContentTypeCommand;
}

+ (int)getContentFlags {
    //静默通道：透明消息（不存储、不计未读、不多端同步，对端不在线则丢弃），与会议命令消息一致
    return WFCCPersistFlag_TRANSPARENT;
}

- (NSString *)digest:(WFCCMessage *)message {
    //digest 为空：不显示在消息流/会话列表/通知
    return @"";
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

@end
