//
//  WFCUDshAgentPanelViewController.h
//  WFChatUIKit
//
//  DSH/AI 会话设置面板（静默通道：207 DSH_Command 透明消息 + scope=31 type=3 面板数据）。
//  打开面板发 207 query 组合查询 → 插件聚合面板数据写 type=3 → 本端读 type=3 渲染
//  （model/effort 下拉选项、sandbox radio、plan switch、cwd + dirs 列表）；
//  操作发 207 set（cmd=命令文本，如 "/model deepseek-official/xxx"），插件执行后写
//  type=1 lastChange（标题可见）并刷新 type=3；本端监听 kSettingUpdated 重读 type=3。
//  全部交互不落消息流（207 为透明消息，digest 为空、不显示），不再发送文本命令、
//  不再解析机器人回复。
//

#import <UIKit/UIKit.h>

@class WFCCConversation;

NS_ASSUME_NONNULL_BEGIN

@interface WFCUDshAgentPanelViewController : UIViewController

/// 仅限 DSH/AI 会话（conversation.line == 2）使用
- (instancetype)initWithConversation:(WFCCConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
