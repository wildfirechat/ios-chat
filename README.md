## 野火IM解决方案

野火IM是专业级即时通讯和实时音视频整体解决方案，由北京野火无限网络科技有限公司维护和支持。

主要特性有：私有部署安全可靠，性能强大，功能齐全，全平台支持，开源率高，部署运维简单，二次开发友好，方便与第三方系统对接或者嵌入现有系统中。详细情况请参考[在线文档](https://docs.wildfirechat.cn)。

主要包括一下项目：

| [GitHub仓库地址(主站)](https://github.com/wildfirechat)      | [码云仓库地址(镜像)](https://gitee.com/wfchat)        | 说明                                                                                      | 备注                                           |
| ------------------------------------------------------------ | ----------------------------------------------------- | ----------------------------------------------------------------------------------------- | ---------------------------------------------- |
| [im-server](https://github.com/wildfirechat/im-server)       | [im-server](https://gitee.com/wfchat/im-server)          | IM Server                                                                                 |                                                |
| [android-chat](https://github.com/wildfirechat/android-chat) | [android-chat](https://gitee.com/wfchat/android-chat) | 野火IM Android SDK源码和App源码                                                           | 可以很方便地进行二次开发，或集成到现有应用当中 |
| [ios-chat](https://github.com/wildfirechat/ios-chat)         | [ios-chat](https://gitee.com/wfchat/ios-chat)         | 野火IM iOS SDK源码和App源码                                                               | 可以很方便地进行二次开发，或集成到现有应用当中 |
| [pc-chat](https://github.com/wildfirechat/vue-pc-chat)       | [pc-chat](https://gitee.com/wfchat/vue-pc-chat)       | 基于[Electron](https://electronjs.org/)开发的PC 端                                        |                                                |
| [web-chat](https://github.com/wildfirechat/vue-chat)         | [web-chat](https://gitee.com/wfchat/vue-chat)         | 野火IM Web 端, [体验地址](http://web.wildfirechat.cn)                                     |                                                |
| [wx-chat](https://github.com/wildfirechat/wx-chat)           | [wx-chat](https://gitee.com/wfchat/wx-chat)           | 小程序平台的Demo(支持微信、百度、阿里、字节、QQ 等小程序平台)                             |                                                |
| [app server](https://github.com/wildfirechat/app_server)     | [app server](https://gitee.com/wfchat/app_server)     | 应用服务端                                                                                |                                                |
| [robot_server](https://github.com/wildfirechat/robot_server) | [robot_server](https://gitee.com/wfchat/robot_server) | 机器人服务端                                                                              |                                                |
| [push_server](https://github.com/wildfirechat/push_server)   | [push_server](https://gitee.com/wfchat/push_server)   | 推送服务器                                                                                |                                                |
| [docs](https://github.com/wildfirechat/docs)                 | [docs](https://gitee.com/wfchat/docs)                 | 野火IM相关文档，包含设计、概念、开发、使用说明，[在线查看](https://docs.wildfirechat.cn/) |                                                |


## 说明
本工程为野火IM iOS App。开发过程中，充分考虑了二次开发和集成需求，可作为SDK集成到其他应用中，或者直接进行二次开发。

开发一套IM系统真的很艰辛，请路过的朋友们给点个star，支持我们坚持下去🙏🙏🙏🙏🙏

### 联系我们

> 商务合作请优先采用邮箱和我们联系。技术问题请到[野火IM论坛](http://bbs.wildfirechat.cn/)发帖交流。

1. heavyrain.lee  邮箱: heavyrain.lee@wildfirechat.cn  微信：wildfirechat
2. imndx  邮箱: imndx@wildfirechat.cn  微信：wfchat

### 问题交流

1. 如果大家发现bug，请在GitHub提issue
2. 其他问题，请到[野火IM论坛](http://bbs.wildfirechat.cn/)进行交流学习
3. 微信公众号

<img src="http://static.wildfirechat.cn/wx_wfc_qrcode.jpg" width = 50% height = 50% />

> 强烈建议关注我们的公众号。我们有新版本发布或者有重大更新会通过公众号通知大家，另外我们也会不定期的发布一些关于野火IM的技术介绍。

#### 体验Demo
我们提供了体验demo，请使用微信扫码下载安装体验

![野火IM](http://static.wildfirechat.cn/download_qrcode.png)

#### 应用截图
![ios-demo](http://static.wildfirechat.cn/ios-demo.gif)

<img src="http://static.wildfirechat.cn/ios-message-view.png" width = 50% height = 50% />

<img src="http://static.wildfirechat.cn/ios-contact-view.png" width = 50% height = 50% />

<img src="http://static.wildfirechat.cn/ios-discover-view.png" width = 50% height = 50% />

<img src="http://static.wildfirechat.cn/ios-settings-view.png" width = 50% height = 50% />

<img src="http://static.wildfirechat.cn/ios-messagelist-view.png" width = 50% height = 50% />

<img src="http://static.wildfirechat.cn/ios-chat-setting-view.png" width = 50% height = 50% />

<img src="http://static.wildfirechat.cn/ios-takephoto-view.png" width = 50% height = 50% />

<img src="http://static.wildfirechat.cn/ios-record-voice-view.png" width = 50% height = 50% />

<img src="http://static.wildfirechat.cn/ios-location-view.png" width = 50% height = 50% />

<img src="http://static.wildfirechat.cn/ios-voip-view.png" width = 50% height = 50% />


### 工程说明

工程中有3个项目，其中1个是应用，另外两个2个是库。chatclient库是IM的通讯能力，是最底层的库，chatuikit是IM的UI控件库，依赖于chatclient。chat是IM的demo，依赖于这两个库，chat需要正确配置服务器地址。

### 配置

在项目的Config.m文件中，修改IM服务器地址配置。把```IM_SERVER_HOST```和```IM_SERVER_PORT```设置成火信的地址和端口。另外需要搭配应用服务器，请按照说明部署好[应用服务器](https://github.com/wildfirechat/app_server)，然后把```APP_SERVER_HOST```和```APP_SERVER_PORT```设置为应用服务器的地址和端口。

### 自签名证书

私有化部署时，IM 服务、媒体服务、应用服务等可能会使用自签名证书。客户端默认会以"证书无效"（`NSURLErrorServerCertificateUntrusted`）拒绝连接，工程内置了统一的证书信任管理，把证书放进 App 即可，不需要改动业务代码。

#### 1. 放证书

把证书文件（`.cer`、`.crt`、`.pem`、`.der`，一个 `.pem` 里可以包含多张）放到 App 的 Bundle 根目录，例如工程里已有的 ```wfchat/WildFireChat/ip.crt```。客户端启动时会自动遍历 Bundle 根目录下的所有证书文件并加载，代码见 ```wfclient/WFChatClient/CertificateManager/WFCCCertificateManager.m```。

> ShareExtension 不链接 chatclient 库，而是**文件引用**同一份证书管理源文件（```wfclient/WFChatClient/CertificateManager/WFCCCertificateManager.*```）直接参与编译，证书文件也要加进 Extension 的 Bundle（`wfchat/ShareExtension/` 已配置好）。

#### 2. 证书里的地址必须和实际拨号的地址一致

主机绑定**完全依赖证书的 SAN**（Subject Alternative Name），评估时统一使用 `SecPolicyCreateSSL(true, host)`，所以：

- 证书 SAN 里必须包含客户端实际连接的 IP 或域名；
- 用 IP 直连就要有 **IP SAN**，用域名连接就要有 **DNS SAN**（或 `*.example.com` 通配）；
- SAN 不匹配就是连接失败，**没有跳过校验的开关**。

比如工程里已有的 `ip.crt`，SAN 是 `IP:101.35.103.221, IP:10.0.16.12`，就只能用这两个地址直连。

#### 3. 证书建议做成"合规"证书

Apple 对 TLS 服务端证书有硬性策略，不满足时即使把证书内置为信任锚，Security.framework 依然会拒绝：

- 有效期不超过 **825 天**；
- 必须带 `extended key usage: serverAuth`。

自签证书可以参考下面的命令生成：

```bash
openssl req -x509 -newkey rsa:2048 -nodes -days 820 \
  -keyout server.key -out server.crt \
  -subj "/CN=101.35.103.221" \
  -addext "subjectAltName=IP:101.35.103.221,IP:10.0.16.12" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,digitalSignature,keyEncipherment,keyCertSign" \
  -addext "extendedKeyUsage=serverAuth"
```

如果不想重签、证书不满足上面两条，客户端默认的**宽松模式**可以兼容。

#### 4. 两种校验策略

| 策略 | 说明 |
| --- | --- |
| `WFCCCertPolicyModePermissive`（默认） | 用 `SecPolicyCreateBasicX509` 只校验证书链和有效期，不套用 Apple 的 825 天有效期、`serverAuth` EKU 等 TLS 策略；主机匹配由客户端按证书 SAN 自行完成。可以兼容不合规的自签证书 |
| `WFCCCertPolicyModeTLS` | 完全走系统 TLS 策略，要求证书合规 |

```objc
// 切换到严格模式
[WFCCCertificateManager sharedManager].policyMode = WFCCCertPolicyModeTLS;
// 只信任内置证书，忽略系统信任库里的其它根证书
[WFCCCertificateManager sharedManager].trustMode = WFCCCertTrustModePinOnly;
// 关闭自签证书支持
[WFCCCertificateManager sharedManager].enabled = NO;
// 手动加载并应用到 IM（一般不需要，启动时会自动做）
[WFCCCertificateManager setupWithMainBundleCertificates];
```

默认是"宽松模式 + 先走系统信任库、失败再用内置证书当锚点"，公签证书、用户自己安装并信任的证书、内置自签证书三种情况都能正常工作。

#### 5. 覆盖范围

证书信任管理已经接入所有网络通道，不需要逐个改造：

- IM 长连接及协议栈内的媒体上传下载（`WFCCNetworkService` 的 TLS 配置 + 协议栈证书链校验回调）
- 大文件预签名上传（`WFCCIMService`）
- 头像、图片、表情、朋友圈图片（SDWebImage）
- 应用服务、组织通讯录、接龙、投票、网盘、归档等（AFNetworking）
- 实时语音输入的 WebSocket、语音转文字（`NSURLSession`）
- 工作台、关于、隐私政策等网页（WKWebView）

#### 6. 排障

证书不匹配或校验失败时会输出 `[WFCCCert]` 前缀的日志，包含服务端证书的 SAN、有效期、指纹，以及当前连接的 host 是否匹配。也可以直接调用：

```objc
NSLog(@"%@", [[WFCCCertificateManager sharedManager] describeCertificatesForHost:@"101.35.103.221"]);
```

#### 7. 安全建议

内置证书信任是为了兼容私有化部署的自签证书，安全性弱于公签证书，生产环境建议：

- 使用公签证书；或者搭建私有 CA（长期有效）签发服务端证书（不超过 825 天），客户端内置并固定 CA，续期时不用发版；
- 不要为了省事把证书校验全局放开；
- 自签方案仅用于内网或设备可管控的私有化部署。

### 登陆
使用手机号码及验证码登陆，
> 在没有短信供应商时，可以使用[superCode](https://github.com/wildfirechat/app_server#短信资源)进行测试验证。

### 集成
在集成到其他应用中时，如果使用了UIKit库，需要在应用的```Info.plist```文件中添加属性```CFBundleAllowMixedLocalizations```值为true。项目下的脚本[release_libs.sh](./release_libs.sh)可以把chatclient和chatuikit打包成动态库，把生成的库和资源添加到工程依赖中，注意库是动态库，需要"Embed"。此外还可以把chatclient和chatuikit项目直接添加到工程依赖中。

### 第三方动态库
1. [SDWebImage](https://github.com/SDWebImage/SDWebImage)
2. [ZLPhotoBrowser](https://github.com/longitachi/ZLPhotoBrowser)
> UI层使用了它们的动态库，如果需要源码可以去对应地址下载，可以自己编译替换第三方动态库。

如果编译时提示动态库签名"cannot be verified"：这是因为动态库使用了官方自签证书，且文件带有隔离属性或符号链接被破坏。请使用```git clone```获取代码（不要用浏览器下载ZIP），项目不要放在FAT32等非Mac格式的磁盘或网盘同步目录中。如果已正常clone仍提示，执行```xattr -dr com.apple.quarantine <项目路径>```后重新编译即可。比如:
```
xattr -dr com.apple.quarantine /User/user/Download/ios-chat
```

### 推送
当应用在后台几秒钟后就会被冻结和杀掉，此时收到消息需要APNS通知。请部署推送服务，推送服务代码可以在[Github](https://github.com/wildfirechat/push_server)和[码云](https://gitee.com/wfchat/push_server)下载。具体使用方式，请参考推送服务项目上的说明。

### 升级说明
2022.11.05 iOS SDK修改了```kUserInfoUpdated```、```kGroupInfoUpdated```和```kChannelInfoUpdated````通知。把之前的单个通知，改成了批量通知，请注意这个变化。

### 感谢
本工程使用了[mars](https://github.com/tencent/mars)及其它大量优秀的开源项目，对他们的贡献表示感谢。本工程使用的Icon全部来源于[icons8](https://icons8.com)，对他们表示感谢。Gif动态图来源于网络，对网友的制作表示感谢。如果有什么地方侵犯了您的权益，请联系我们删除🙏🙏🙏

### License
1. Under the Creative Commons Attribution-NoDerivs 3.0 Unported license. See the [LICENSE](https://github.com/wildfirechat/ios-chat/blob/master/LICENSE) file for details.
2. Under the 996ICU License. See the [LICENSE](https://github.com/996icu/996.ICU/blob/master/LICENSE) file for details.
