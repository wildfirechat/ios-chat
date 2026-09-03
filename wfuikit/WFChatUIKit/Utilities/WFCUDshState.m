//
//  WFCUDshState.m
//  WFChatUIKit
//
//  DSH 会话运行时状态工具实现。
//

#import "WFCUDshState.h"
#import "UIColor+YH.h"

//1=状态（业务约定）；2=Token 统计（独立通道，回合结束必推，含出错/取消）；3=AI 面板数据（组合查询结果）
static const NSInteger DSHStateType = 1;
static const NSInteger DSHMetricsType = 2;
static const NSInteger DSHPanelType = 3;

NSString *const WFCUDshFocusInputNotification = @"WFCUDshFocusInputNotification";
NSString *const WFCUDshShowPlanDetailNotification = @"WFCUDshShowPlanDetailNotification";
NSString *const WFCUDshAnsweredNotification = @"WFCUDshAnsweredNotification";

// 数字格式化：整数不带小数，否则保留 1 位（与 PC 端 dshState.js fmtNum 一致）；非数字返回 nil
static NSString *fmtDshNum(NSNumber *num) {
    if (![num isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    double value = [num doubleValue];
    if (isnan(value) || isinf(value)) {
        return nil;
    }
    if (value == floor(value)) {
        return [NSString stringWithFormat:@"%.0f", value];
    }
    return [NSString stringWithFormat:@"%.1f", round(value * 10) / 10.0];
}

@implementation WFCUAgentState

//scope=31（会话级用户设置）本地库全量读：server 现统一写
//"<convType>-<line>-<target>_<type>_<机器人uid>"（uid 后缀，不再有无后缀 key），
//因此不做精确 key 读取：扫描全部 scope=31 条目，返回首个 key 以 prefix 开头
//（"<convType>-<line>-<target>_<type>_"）的 value。
+ (NSString *)settingValueWithKeyPrefix:(NSString *)prefix {
    if (prefix.length == 0) {
        return nil;
    }
    NSDictionary<NSString *, NSString *> *settings = [[WFCCIMService sharedWFCIMService] getUserSettings:UserSettingScope_Conversation_User_Setting keyPrefix:prefix];
    settings = [[WFCCIMService sharedWFCIMService] getUserSettings:UserSettingScope_Conversation_User_Setting];
    for (NSString *key in settings) {
        if ([key hasPrefix:prefix]) {
            return settings[key];
        }
    }
    return nil;
}

//server v2 统一在 key 尾追加机器人 uid，以下三个方法返回匹配前缀（以 "_" 结尾）
+ (NSString *)dshStateKey:(WFCCConversation *)conversation {
    return [NSString stringWithFormat:@"%d-%d-%@_%d_", (int)conversation.type, (int)conversation.line, conversation.target, (int)DSHStateType];
}

+ (NSString *)dshMetricsKey:(WFCCConversation *)conversation {
    return [NSString stringWithFormat:@"%d-%d-%@_%d_", (int)conversation.type, (int)conversation.line, conversation.target, (int)DSHMetricsType];
}

+ (NSString *)dshPanelKey:(WFCCConversation *)conversation {
    return [NSString stringWithFormat:@"%d-%d-%@_%d_", (int)conversation.type, (int)conversation.line, conversation.target, (int)DSHPanelType];
}

+ (BOOL)isDshGroupExtra:(NSString *)extra {
    if (extra.length == 0) {
        return NO;
    }
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[extra dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error || ![dict isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    return [dict[@"dsh"] boolValue];
}

// AI/DSH 会话类型：'group'（群聊会话 line 2）/ nil（非 AI 会话）。
// 判断依据：群聊会话且 conversation.line == 2（AI 消息统一使用 line 2，
// 普通消息 line 0，朋友圈 line 1）；单聊是全局控制面板，不判 AI。
+ (NSString *)dshConversationKind:(WFCCConversation *)conversation {
    if (!conversation || conversation.target.length == 0) {
        return nil;
    }
    // AI 会话 = 群聊 + line 2；单聊不判 AI（控制面板）
    if (conversation.type != Group_Type || conversation.line != 2) {
        return nil;
    }
    return @"group";
}

+ (BOOL)isDshConversation:(WFCCConversation *)conversation {
    // AI/DSH 会话统一通过 群聊+line==2 判断。
    return [self dshConversationKind:conversation] != nil;
}

+ (NSDictionary *)dshState:(WFCCConversation *)conversation {
    if (![self isDshConversation:conversation]) {
        return nil;
    }
    NSString *value = [self settingValueWithKeyPrefix:[self dshStateKey:conversation]];
    if (value.length == 0) {
        return nil;
    }
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error || ![dict isKindOfClass:[NSDictionary class]] || ![dict[@"state"] isKindOfClass:[NSString class]]) {
        return nil;
    }
    return dict;
}

//Token 统计（scope=31 type=2 计量）：回合结束必推（含出错/取消），带 metricsAt 时间戳。
//与运行状态（type=1）分开读；非法/未设置返回 nil
+ (NSDictionary *)dshMetrics:(WFCCConversation *)conversation {
    if (![self isDshConversation:conversation]) {
        return nil;
    }
    NSString *value = [self settingValueWithKeyPrefix:[self dshMetricsKey:conversation]];
    if (value.length == 0) {
        return nil;
    }
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return dict;
}

//AI 面板数据（scope=31 type=3，DSH_Command 207 query 组合查询结果）：
//{model:{current,options[]}, effort:{current,options[]}, sandbox:{current,options[]},
// plan:{on}, cwd, sessionId, dirs[]}；未设置/非法返回 nil
+ (NSDictionary *)dshPanelData:(WFCCConversation *)conversation {
    if (![self isDshConversation:conversation]) {
        return nil;
    }
    NSString *value = [self settingValueWithKeyPrefix:[self dshPanelKey:conversation]];
    if (value.length == 0) {
        return nil;
    }
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return dict;
}

+ (NSString *)stateText:(NSString *)state {
    static NSDictionary<NSString *, NSString *> *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{@"idle": @"空闲",
                @"running": @"运行中",
                @"waiting_user": @"等待确认",
                @"done": @"已完成"};
    });
    return map[state];
}

//Token/上下文计量一行文本：输入为 type=2 统计对象（dshMetrics: 的返回值），
//只输出统计段（上下文 x% / 缓存 y% / z tok/s / 本轮 n tok / 累计 m tok）；
//运行态提示（等待确认/审批、错误、取消）走 dshStatusHint:（type=1），不在此处
+ (NSString *)dshMetricsText:(NSDictionary *)metrics {
    if (![metrics isKindOfClass:[NSDictionary class]]) {
        return @"";
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray array];

    // 上下文占用（下一请求预估成本 / 模型窗口）
    NSDictionary *context = metrics[@"context"];
    if ([context isKindOfClass:[NSDictionary class]]) {
        NSString *pct = fmtDshNum(context[@"usedPct"]);
        if (pct.length) {
            [parts addObject:[NSString stringWithFormat:@"上下文 %@%%", pct]];
        }
    }
    // 缓存命中率（累计口径；值为 0 也要显示）
    NSString *cachePct = fmtDshNum(metrics[@"cacheHitRatePct"]);
    if (cachePct.length) {
        [parts addObject:[NSString stringWithFormat:@"缓存 %@%%", cachePct]];
    }
    // 本轮生成速度 + 输出 token
    NSDictionary *speed = metrics[@"speed"];
    if ([speed isKindOfClass:[NSDictionary class]]) {
        NSString *tps = fmtDshNum(speed[@"tokensPerSec"]);
        if (tps.length) {
            [parts addObject:[NSString stringWithFormat:@"%@ tok/s", tps]];
        }
    }
    NSDictionary *turn = metrics[@"turn"];
    if ([turn isKindOfClass:[NSDictionary class]]) {
        NSNumber *outTokens = turn[@"outputTokens"];
        if ([outTokens isKindOfClass:[NSNumber class]] && [outTokens doubleValue] > 0) {
            [parts addObject:[NSString stringWithFormat:@"本轮 %@ tok", fmtDshNum(outTokens)]];
        }
    }
    // 累计用量
    NSDictionary *usage = metrics[@"usage"];
    if ([usage isKindOfClass:[NSDictionary class]]) {
        NSString *total = fmtDshNum(usage[@"totalTokens"]);
        if (total.length) {
            [parts addObject:[NSString stringWithFormat:@"累计 %@ tok", total]];
        }
    }
    return [parts componentsJoinedByString:@" · "];
}

//运行态提示（type=1 状态）：waiting_user → 🤔 等待确认 / 🔐 等待审批；
//reason=error → ⚠️ 错误；reason=cancelled → 已取消；无提示返回空字符串
+ (NSString *)dshStatusHint:(NSDictionary *)state {
    if (![state isKindOfClass:[NSDictionary class]]) {
        return @"";
    }
    // 交互等待：优先提示在等什么
    if ([state[@"state"] isEqualToString:@"waiting_user"]) {
        NSString *interaction = [state[@"interaction"] isKindOfClass:[NSString class]] ? state[@"interaction"] : nil;
        return [interaction isEqualToString:@"approval"] ? @"🔐 等待审批" : @"🤔 等待确认";
    }
    // 结果原因 / 错误
    NSString *reason = [state[@"reason"] isKindOfClass:[NSString class]] ? state[@"reason"] : nil;
    if ([reason isEqualToString:@"error"]) {
        NSString *error = [state[@"error"] isKindOfClass:[NSString class]] && [state[@"error"] length] ? state[@"error"] : @"出错了";
        return [NSString stringWithFormat:@"⚠️ %@", error];
    }
    if ([reason isEqualToString:@"cancelled"]) {
        return @"已取消";
    }
    return @"";
}

+ (UIColor *)accentColor {
    return [UIColor colorWithHexString:@"0x4764DC"];
}

+ (UIColor *)stateColor:(NSString *)state {
    if ([state isEqualToString:@"running"]) {
        return [self accentColor];
    } else if ([state isEqualToString:@"waiting_user"]) {
        return [UIColor colorWithHexString:@"0xf59e0b"];
    } else if ([state isEqualToString:@"done"]) {
        return [UIColor colorWithHexString:@"0x22c55e"];
    }
    // idle / 未识别状态：与 done 一致显示绿色（可继续输入指示任务）
    return [UIColor colorWithHexString:@"0x22c55e"];
}

+ (UIColor *)goalPhaseColor:(NSString *)phase {
    if ([phase isEqualToString:@"active"]) {
        return [UIColor colorWithHexString:@"0x22c55e"];
    } else if ([phase isEqualToString:@"paused"]) {
        return [UIColor colorWithHexString:@"0x94a3b8"];
    } else if ([phase isEqualToString:@"blocked"]) {
        return [UIColor redColor];
    } else if ([phase isEqualToString:@"complete"]) {
        return [self accentColor];
    }
    return [UIColor colorWithHexString:@"0x94a3b8"];
}

+ (NSString *)goalPhaseText:(NSString *)phase {
    static NSDictionary<NSString *, NSString *> *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{@"active": @"进行中",
                @"paused": @"已暂停",
                @"blocked": @"受阻",
                @"complete": @"已完成"};
    });
    return map[phase] ?: (phase.length ? phase : @"");
}

+ (NSArray<NSDictionary<NSString *, NSString *> *> *)dshCommands:(WFCCConversation *)conversation {
    if (![self isDshConversation:conversation]) {
        return nil;
    }
    NSArray<NSArray<NSString *> *> *pairs;
    if (conversation.type == Group_Type) {
        //群聊精简：model/effort/cwd/sandbox/plan/compact/reset/ls 已由 AI 设置面板（207 静默通道）覆盖，
        //仅保留 help/stop/群管理
        pairs = @[@[@"/help", @"命令帮助"],
                  @[@"/members", @"列成员"],
                  @[@"/kick", @"踢人"],
                  @[@"/invite", @"拉人"],
                  @[@"/mute", @"禁言"],
                  @[@"/unmute", @"解除禁言"],
                  @[@"/stop", @"停止当前任务"]];
    } else {
        pairs = @[@[@"/help", @"命令帮助"],
                  @[@"/create", @"创建 AI 工作区群"],
                  @[@"/workspaces", @"列出工作区"],
                  @[@"/goal", @"目标管理"],
                  @[@"/jobs", @"后台任务"],
                  @[@"/model", @"切换模型"],
                  @[@"/effort", @"推理等级"],
                  @[@"/plan", @"计划模式"],
                  @[@"/compact", @"压缩上下文"],
                  @[@"/cwd", @"切换工作目录"],
                  @[@"/ls", @"列出目录"],
                  @[@"/sandbox", @"沙箱模式"],
                  @[@"/stop", @"停止当前任务"]];
    }
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *commands = [NSMutableArray array];
    for (NSArray<NSString *> *pair in pairs) {
        [commands addObject:@{@"command": pair[0], @"desc": pair[1]}];
    }
    return commands;
}

@end
