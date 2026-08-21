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
static const int DSHMessageContentTypeQuestion = 200;
static const int DSHMessageContentTypeAnswer = 201;
static const int DSHMessageContentTypeApproval = 202;
static const int DSHMessageContentTypeApprovalResult = 203;
static const int DSHMessageContentTypeGoal = 206;

@implementation WFCCDshMessageContentBase

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

@implementation WFCCDshQuestionMessageContent

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
    NSDictionary *dict = [WFCCDshMessageContentBase decodeJsonDict:payload];
    self.qid = dict[@"qid"];
    NSArray *questions = dict[@"questions"];
    self.questions = [questions isKindOfClass:[NSArray class]] ? questions : @[];
    self.state = dict[@"state"];
}

+ (int)getContentType {
    return DSHMessageContentTypeQuestion;
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

@implementation WFCCDshAnswerMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"qid"] = self.qid ?: @"";
    dict[@"answers"] = self.answers ?: @[];
    [self encodeJsonDict:dict payload:payload digest:[self digest:nil]];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    NSDictionary *dict = [WFCCDshMessageContentBase decodeJsonDict:payload];
    self.qid = dict[@"qid"];
    NSArray *answers = dict[@"answers"];
    self.answers = [answers isKindOfClass:[NSArray class]] ? answers : @[];
}

+ (int)getContentType {
    return DSHMessageContentTypeAnswer;
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

@implementation WFCCDshApprovalMessageContent

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
    NSDictionary *dict = [WFCCDshMessageContentBase decodeJsonDict:payload];
    self.aid = dict[@"aid"];
    self.toolName = dict[@"toolName"];
    self.reason = dict[@"reason"];
    self.state = dict[@"state"];
}

+ (int)getContentType {
    return DSHMessageContentTypeApproval;
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

@implementation WFCCDshApprovalResultMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"aid"] = self.aid ?: @"";
    dict[@"action"] = self.action.length ? self.action : @"reject";
    [self encodeJsonDict:dict payload:payload digest:[self digest:nil]];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    NSDictionary *dict = [WFCCDshMessageContentBase decodeJsonDict:payload];
    self.aid = dict[@"aid"];
    self.action = dict[@"action"];
}

+ (int)getContentType {
    return DSHMessageContentTypeApprovalResult;
}

- (NSString *)digest:(WFCCMessage *)message {
    return [self.action isEqualToString:@"approve"] ? @"（已同意）" : @"（已拒绝）";
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

@end

@implementation WFCCDshGoalMessageContent

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
    NSDictionary *dict = [WFCCDshMessageContentBase decodeJsonDict:payload];
    self.gid = dict[@"gid"];
    self.objective = dict[@"objective"];
    self.phase = dict[@"phase"];
    self.roundsStarted = [dict[@"roundsStarted"] integerValue];
}

+ (int)getContentType {
    return DSHMessageContentTypeGoal;
}

- (NSString *)digest:(WFCCMessage *)message {
    return [NSString stringWithFormat:@"🎯 %@（%@，round %d）", self.objective.length ? self.objective : @"目标", self.phase ?: @"", (int)self.roundsStarted];
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

@end
