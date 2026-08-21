//
//  WFCUDshState.m
//  WFChatUIKit
//
//  DSH 会话运行时状态工具实现。
//

#import "WFCUDshState.h"
#import "UIColor+YH.h"

//1=状态（业务约定）
static const NSInteger DSHStateType = 1;

NSString *const WFCUDshFocusInputNotification = @"WFCUDshFocusInputNotification";
NSString *const WFCUDshShowPlanDetailNotification = @"WFCUDshShowPlanDetailNotification";
NSString *const WFCUDshAnsweredNotification = @"WFCUDshAnsweredNotification";

@implementation WFCUDshState

+ (NSString *)dshStateKey:(WFCCConversation *)conversation {
    return [NSString stringWithFormat:@"%d-%d-%@_%d", (int)conversation.type, (int)conversation.line, conversation.target, (int)DSHStateType];
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

+ (BOOL)isDshConversation:(WFCCConversation *)conversation {
    if (!conversation || conversation.target.length == 0) {
        return NO;
    }
    if (conversation.type == Single_Type) {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:conversation.target refresh:NO];
        return userInfo.type == 1;
    }
    if (conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:conversation.target refresh:NO];
        return [self isDshGroupExtra:groupInfo.extra];
    }
    return NO;
}

+ (NSDictionary *)dshState:(WFCCConversation *)conversation {
    if (![self isDshConversation:conversation]) {
        return nil;
    }
    NSString *value = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Conversation_User_Setting key:[self dshStateKey:conversation]];
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
    return [UIColor colorWithHexString:@"0x94a3b8"];
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
        pairs = @[@[@"/help", @"命令帮助"],
                  @[@"/cwd", @"切换工作目录"],
                  @[@"/ls", @"列出目录"],
                  @[@"/model", @"切换模型"],
                  @[@"/effort", @"推理等级"],
                  @[@"/plan", @"计划模式"],
                  @[@"/compact", @"压缩上下文"],
                  @[@"/sandbox", @"沙箱模式"],
                  @[@"/reset", @"重置会话"],
                  @[@"/stop", @"停止当前任务"]];
    } else {
        pairs = @[@[@"/help", @"命令帮助"],
                  @[@"/create-group", @"创建 DSH 工作区群"],
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
