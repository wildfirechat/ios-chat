
//
//  WFCUConfigManager.h
//  WFChatUIKit
//
//  Created by heavyrain lee on 2019/9/22.
//  Copyright © 2019 WF Chat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WFCUAppServiceProvider.h"
#import "WFCUOrgServiceProvider.h"
#import "WFCUCollectionService.h"
#import "WFCUPollService.h"
#import "WFCUPanService.h"

NS_ASSUME_NONNULL_BEGIN

@class WFCCConversation;
typedef NS_ENUM(NSInteger, WFCCMediaType);
/**
 主题类型

 - ThemeType_WFChat: 野火风格
 - ThemeType_White: 白色风格
 */
typedef NS_ENUM(NSInteger, WFCUThemeType) {
    ThemeType_WFChat,
    ThemeType_White
};

@interface WFCUConfigManager : NSObject
+ (WFCUConfigManager *)globalManager;

- (void)setupNavBar;
@property(nonatomic, assign)WFCUThemeType selectedTheme;

@property(nonatomic, strong)UIColor *backgroudColor;
/*
 * 与backgroudColor的区别是，backgroudColor是内容区的背景颜色；frameBackgroudColor是内容区之外框架的颜色，也用在输入框的背景色。
 */
@property(nonatomic, strong)UIColor *frameBackgroudColor;
@property(nonatomic, strong)UIColor *textColor;

@property(nonatomic, strong)UIColor *naviBackgroudColor;
@property(nonatomic, strong)UIColor *naviTextColor;

@property(nonatomic, strong)UIColor *separateColor;

@property(nonatomic, strong)UIColor *externalNameColor;

@property(nonatomic, weak)id<WFCUAppServiceProvider> appServiceProvider;

@property(nonatomic, weak)id<WFCUOrgServiceProvider> orgServiceProvider;

@property(nonatomic, weak)id<WFCUCollectionService> collectionServiceProvider;

@property(nonatomic, weak)id<WFCUPollService> pollServiceProvider;

@property(nonatomic, weak)id<WFCUPanService> panServiceProvider;

@property(nonatomic, strong)NSString *fileTransferId;

@property(nonatomic, strong)NSString *asrServiceUrl;

@property(nonatomic, strong)NSString *aiRobotId;

@property(nonatomic, strong)NSString *conversationFilesDir;

@property(nonatomic, assign)BOOL enableMultiCallAutoJoin;

@property(nonatomic, assign)BOOL displaySpeakingInMultiCall;

/**
 * 是否启用 Markdown 文本消息支持
 * 启用后，包含 Markdown 语法的文本消息将使用 WFCUMarkdownCell 显示
 * 默认为 YES
 */
@property(nonatomic, assign)BOOL enableMarkdownSupport;

/**
 * Markdown 检测策略
 * - 0: 自动检测（消息内容包含 Markdown 语法时使用 Markdown Cell）
 * - 1: 全部使用 Markdown Cell
 * - 2: 全部不使用 Markdown Cell（使用普通 Text Cell）
 */
@property(nonatomic, assign)NSInteger markdownDisplayStrategy;

@property (nonatomic, strong)NSMutableDictionary<NSNumber*, Class>* cellContentDict;

- (NSString *)cachePathOf:(WFCCConversation *)conversation mediaType:(WFCCMediaType)mediaType;

//[[WFCUConfigManager globalManager] registerCustomCell:[WFCUTextCell class] forContent:[WFCCTextMessageContent class]];
- (void)registerCustomCell:(Class)cellCls forContent:(Class)msgContentCls;

//缓存文本cell的size，避免卡顿（使用 NSCache 自动管理内存）
@property (nonatomic, strong)NSCache<NSString*, NSDictionary*> *cellSizeCache;

/**
 * 清理 Cell 尺寸缓存（可在内存警告时调用）
 */
- (void)clearCellSizeCache;

/**
 * 清理所有缓存
 */
- (void)clearAllCache;

@end

NS_ASSUME_NONNULL_END
