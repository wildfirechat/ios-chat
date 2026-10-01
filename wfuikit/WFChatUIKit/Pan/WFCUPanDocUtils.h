//
//  WFCUPanDocUtils.h
//  WFChatUIKit
//
//  在线文档 URL 与格式判定工具（对齐 wf-pan-server/doc-web）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUPanDocUtils : NSObject

/// 隐藏的文件夹名 / 扩展名判定：Word/Excel/PPT/PDF 组
+ (BOOL)isOnlineDocName:(nullable NSString *)name;

/// 是否是网盘在线文档页地址（<panRoot>/doc/...）
+ (BOOL)isDocUrl:(nullable NSString *)url;

/// 只读按链接打开：<root>/doc/open?url=&name=&platform=mobile
+ (nullable NSString *)docViewUrl:(NSString *)url name:(nullable NSString *)name;

/// 网盘文件编辑/查看：<root>/doc/open?fileId=&platform=mobile
+ (nullable NSString *)docOpenUrl:(NSInteger)fileId;

/// 开源许可页：<root>/doc/licenses.html
+ (nullable NSString *)licensesUrl;

/// 当前网盘根地址（来自 panServiceProvider），未配置返回 nil
+ (nullable NSString *)panServerAddress;

/// 当前是否已配置网盘
+ (BOOL)isPanConfigured;

/// 百分比编码查询参数值（不保留 & = / : 等）
+ (nullable NSString *)encodeQueryValue:(nullable NSString *)value;

@end

NS_ASSUME_NONNULL_END
