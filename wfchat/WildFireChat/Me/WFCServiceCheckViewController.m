//
//  WFCServiceCheckViewController.m
//  WildFireChat
//
//  POC 部署自检页：分别检测以下服务的连通性并展示结果
//   1. IM 服务        GET  https://<IM_SERVER_HOST>/api/version     期望 200 + JSON
//   2. 应用服务        GET  <APP_SERVER>/                           期望 200 + "Ok"
//   3. 组织通讯录      GET  <ORG_SERVER>/api/user_login             （未配置则跳过）
//                      GET 请求命中后端返回 405/400，说明后端存活；502/503/504 或超时说明不可用
//   4. 开放平台        GET  <WORK_PLATFORM_URL> 所在服务的 /api/login 同理
//
//  说明：组织通讯录、开放平台的静态页由前置 Nginx 直接返回，即使后端挂掉也是 200，
//        因此这里刻意探后端接口来判定后端是否存活。
//

#import "WFCServiceCheckViewController.h"
#import "WFCConfig.h"

typedef NS_ENUM(NSInteger, WFCServiceCheckState) {
    WFCServiceCheckStateChecking = 0,
    WFCServiceCheckStateOK,
    WFCServiceCheckStateFailed,
    WFCServiceCheckStateNotConfigured,
};

@interface WFCServiceCheckItem : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *urlString;      // 为 nil 表示未配置
@property (nonatomic, assign) WFCServiceCheckState state;
@property (nonatomic, copy) NSString *detail;
@end

@implementation WFCServiceCheckItem
@end


@interface WFCServiceCheckViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<WFCServiceCheckItem *> *items;
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation WFCServiceCheckViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"服务诊断";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"重新检测"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(onRetry)];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    cfg.timeoutIntervalForRequest = 8;
    cfg.timeoutIntervalForResource = 10;
    cfg.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    self.session = [NSURLSession sessionWithConfiguration:cfg];

    [self buildItems];
    [self runChecks];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.session invalidateAndCancel];
}

#pragma mark - 构建检测项

- (void)buildItems {
    self.items = [NSMutableArray array];

    // 1. IM 服务：/api/version 由 IM 后端直接返回 JSON
    WFCServiceCheckItem *im = [WFCServiceCheckItem new];
    im.name = @"IM 服务 (/api/version)";
    im.urlString = [self imVersionUrl];
    [self.items addObject:im];

    // 2. 应用服务：根路径由 app_server 直接返回 "Ok"，NG 未连通时会是 502
    WFCServiceCheckItem *app = [WFCServiceCheckItem new];
    app.name = @"应用服务 (/app)";
    app.urlString = [self appProbeUrl];
    [self.items addObject:app];

    // 3. 组织通讯录（未配置则不检测）
    WFCServiceCheckItem *org = [WFCServiceCheckItem new];
    org.name = @"组织通讯录 (/org)";
    org.urlString = [self orgProbeUrl];
    [self.items addObject:org];

    // 4. 开放平台（工作台未配置则不检测）
    WFCServiceCheckItem *open = [WFCServiceCheckItem new];
    open.name = @"开放平台 (/open)";
    open.urlString = [self openProbeUrl];
    [self.items addObject:open];

    for (WFCServiceCheckItem *item in self.items) {
        if (item.urlString.length == 0) {
            item.state = WFCServiceCheckStateNotConfigured;
            item.detail = @"未配置";
        } else {
            item.state = WFCServiceCheckStateChecking;
            item.detail = @"检测中…";
        }
    }
}

#pragma mark - 地址拼装

// IM 的 http 端口固定为 443（本环境全 WSS 单入口，NG 只在 443 对外）
- (NSString *)imVersionUrl {
    NSString *host = IM_SERVER_HOST;
    if (host.length == 0) {
        return nil;
    }
    if ([host hasPrefix:@"http://"] || [host hasPrefix:@"https://"]) {
        return [host stringByAppendingString:@"/api/version"];
    }
    return [NSString stringWithFormat:@"https://%@/api/version", host];
}

- (NSString *)appProbeUrl {
    NSString *base = WFCGetAppServerAddress();
    if (base.length == 0) {
        return nil;
    }
    return [self ensureTrailingSlash:base];
}

// 组织通讯录：探后端接口（GET 到 POST 接口会返回 405，说明后端存活）
- (NSString *)orgProbeUrl {
    NSString *base = WFCGetOrgServerAddress();
    if (base.length == 0) {
        return nil;
    }
    return [[self trimTrailingSlash:base] stringByAppendingString:@"/api/user_login"];
}

// 开放平台：工作台地址形如 https://host/open/work.html，取其 /open 前缀再拼后端接口
- (NSString *)openProbeUrl {
    NSString *work = WFCGetWorkPlatformUrl();
    if (work.length == 0) {
        return nil;
    }
    NSURL *url = [NSURL URLWithString:work];
    if (url == nil || url.scheme.length == 0 || url.host.length == 0) {
        return nil;
    }
    NSMutableString *base = [NSMutableString stringWithFormat:@"%@://%@", url.scheme, url.host];
    if (url.port != nil) {
        [base appendFormat:@":%@", url.port];
    }
    // 取工作台地址所在服务的前缀（/open/work.html -> /open）
    NSString *path = url.path;
    if ([path containsString:@"/open"]) {
        [base appendString:@"/open"];
    }
    return [base stringByAppendingString:@"/api/login"];
}

- (NSString *)ensureTrailingSlash:(NSString *)s {
    return [s hasSuffix:@"/"] ? s : [s stringByAppendingString:@"/"];
}

- (NSString *)trimTrailingSlash:(NSString *)s {
    return [s hasSuffix:@"/"] ? [s substringToIndex:s.length - 1] : s;
}

#pragma mark - 执行检测

- (void)runChecks {
    for (WFCServiceCheckItem *item in self.items) {
        if (item.state == WFCServiceCheckStateNotConfigured) {
            continue;
        }
        NSInteger index = [self.items indexOfObject:item];
        [self checkItem:item atIndex:index];
    }
}

- (void)checkItem:(WFCServiceCheckItem *)item atIndex:(NSInteger)index {
    NSURL *url = [NSURL URLWithString:item.urlString];
    if (url == nil) {
        item.state = WFCServiceCheckStateFailed;
        item.detail = @"地址格式不正确";
        [self reloadRow:index];
        return;
    }

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"GET";
    req.timeoutInterval = 8;
    [req setValue:@"*/*" forHTTPHeaderField:@"Accept"];

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task =
        [self.session dataTaskWithRequest:req
                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            WFCServiceCheckItem *cur = index < self.items.count ? self.items[index] : nil;
            if (cur == nil) {
                return;
            }
            [self applyResult:cur index:index data:data response:response error:error];
        });
    }];
    [task resume];
}

- (void)applyResult:(WFCServiceCheckItem *)item
              index:(NSInteger)index
               data:(NSData *)data
           response:(NSURLResponse *)response
              error:(NSError *)error {
    if (error != nil) {
        item.state = WFCServiceCheckStateFailed;
        if (error.code == NSURLErrorTimedOut) {
            item.detail = @"连接超时";
        } else if (error.code == NSURLErrorCannotFindHost) {
            item.detail = @"域名解析失败";
        } else if (error.code == NSURLErrorCannotConnectToHost) {
            item.detail = @"无法建立连接";
        } else if (error.code == NSURLErrorSecureConnectionFailed ||
                   error.code == NSURLErrorServerCertificateUntrusted ||
                   error.code == NSURLErrorServerCertificateHasBadDate ||
                   error.code == NSURLErrorServerCertificateNotYetValid ||
                   error.code == NSURLErrorServerCertificateHasUnknownRoot) {
            item.detail = @"证书校验失败";
        } else {
            item.detail = [NSString stringWithFormat:@"%@ (%ld)", error.localizedDescription, (long)error.code];
        }
        [self reloadRow:index];
        return;
    }

    NSInteger status = 0;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        status = ((NSHTTPURLResponse *)response).statusCode;
    }
    [self evaluateStatus:status data:data item:item];
    [self reloadRow:index];
}

- (void)evaluateStatus:(NSInteger)status data:(NSData *)data item:(WFCServiceCheckItem *)item {
    // 网关无法连到后端
    if (status == 502 || status == 503 || status == 504) {
        item.state = WFCServiceCheckStateFailed;
        item.detail = [NSString stringWithFormat:@"后端不可用 (HTTP %ld)", (long)status];
        return;
    }

    NSString *body = nil;
    if (data.length > 0 && data.length < 2048) {
        body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }

    if ([item.name hasPrefix:@"IM 服务"]) {
        // 期望 200 + JSON（含 nodeIds / currentNode）
        if (status == 200) {
            NSMutableArray *parts = [NSMutableArray array];
            if ([body rangeOfString:@"\"nodeIds\""].location != NSNotFound) {
                NSRange r = [body rangeOfString:@"\"nodeIds\""];
                NSString *tail = [body substringWithRange:NSMakeRange(r.location, MIN((NSUInteger)60, body.length - r.location))];
                NSString *value = [self jsonStringValueForKey:@"nodeIds" inString:tail];
                if (value.length > 0) {
                    [parts addObject:[NSString stringWithFormat:@"节点: %@", value]];
                }
            }
            NSString *node = [self jsonStringValueForKey:@"currentNode" inString:body];
            if (node.length > 0) {
                [parts addObject:[NSString stringWithFormat:@"当前节点: %@", node]];
            }
            item.state = WFCServiceCheckStateOK;
            item.detail = parts.count > 0
                ? [NSString stringWithFormat:@"HTTP 200 · %@", [parts componentsJoinedByString:@"  "]]
                : @"HTTP 200";
        } else {
            item.state = WFCServiceCheckStateFailed;
            item.detail = [NSString stringWithFormat:@"HTTP %ld", (long)status];
        }
        return;
    }

    if ([item.name hasPrefix:@"应用服务"]) {
        // app_server 根路径返回 "Ok"
        NSString *trimmed = [body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (status == 200 && [trimmed isEqualToString:@"Ok"]) {
            item.state = WFCServiceCheckStateOK;
            item.detail = @"HTTP 200 · Ok";
        } else if (status == 200) {
            item.state = WFCServiceCheckStateOK;
            item.detail = @"HTTP 200（响应非 Ok，请检查 NG 转发目标）";
        } else {
            item.state = WFCServiceCheckStateFailed;
            item.detail = [NSString stringWithFormat:@"HTTP %ld", (long)status];
        }
        return;
    }

    // 组织通讯录 / 开放平台：探的是后端 POST 接口的 GET 请求
    // 405/400 说明后端存活并处理了请求；200 也视为可达
    if (status == 405 || status == 400 || status == 401 || status == 200) {
        item.state = WFCServiceCheckStateOK;
        item.detail = [NSString stringWithFormat:@"HTTP %ld · 后端存活", (long)status];
    } else if (status >= 200 && status < 600) {
        item.state = WFCServiceCheckStateFailed;
        item.detail = [NSString stringWithFormat:@"HTTP %ld（非预期响应）", (long)status];
    } else {
        item.state = WFCServiceCheckStateFailed;
        item.detail = @"无有效响应";
    }
}

- (NSString *)jsonStringValueForKey:(NSString *)key inString:(NSString *)json {
    if (json.length == 0 || key.length == 0) {
        return nil;
    }
    NSString *pattern = [NSString stringWithFormat:@"\"%@\"\\s*:\\s*\"([^\"]*)\"", key];
    NSRegularExpression *regex =
        [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSTextCheckingResult *m = [regex firstMatchInString:json options:0 range:NSMakeRange(0, json.length)];
    if (m != nil && m.numberOfRanges > 1) {
        return [json substringWithRange:[m rangeAtIndex:1]];
    }
    return nil;
}

#pragma mark - UI

- (void)onRetry {
    [self buildItems];
    [self.tableView reloadData];
    [self runChecks];
}

- (void)reloadRow:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.items.count) {
        return;
    }
    NSIndexPath *ip = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"服务连通性";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"说明：组织通讯录与开放平台的页面由前置 Nginx 直接返回，后端挂掉时页面仍是 200。"
            @"因此这里检测的是它们的后端接口（GET 到 POST 接口返回 405 即代表后端存活）。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"WFCServiceCheckCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    WFCServiceCheckItem *item = self.items[indexPath.row];

    cell.textLabel.text = item.name;
    cell.detailTextLabel.numberOfLines = 3;

    NSString *statusText = nil;
    UIColor *color = [UIColor secondaryLabelColor];
    switch (item.state) {
        case WFCServiceCheckStateChecking:
            statusText = @"⏳";
            break;
        case WFCServiceCheckStateOK:
            statusText = @"✅";
            color = [UIColor systemGreenColor];
            break;
        case WFCServiceCheckStateFailed:
            statusText = @"❌";
            color = [UIColor systemRedColor];
            break;
        case WFCServiceCheckStateNotConfigured:
            statusText = @"➖";
            break;
    }

    NSString *detail = item.detail.length > 0 ? item.detail : @"";
    if (item.urlString.length > 0) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n%@", detail, item.urlString];
    } else {
        cell.detailTextLabel.text = detail;
    }
    cell.detailTextLabel.textColor = (item.state == WFCServiceCheckStateFailed) ? [UIColor systemRedColor] : [UIColor secondaryLabelColor];

    cell.accessoryView = nil;
    UILabel *badge = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 34, 24)];
    badge.text = statusText;
    badge.textAlignment = NSTextAlignmentCenter;
    badge.font = [UIFont systemFontOfSize:18];
    cell.accessoryView = badge;

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCServiceCheckItem *item = self.items[indexPath.row];
    if (item.urlString.length == 0) {
        return;
    }
    // 长按复制地址，方便把失败信息发给管理员
    UIPasteboard.generalPasteboard.string = [NSString stringWithFormat:@"%@ -> %@ (%@)",
                                             item.name, item.urlString, item.detail];
    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [gen impactOccurred];
}

@end
