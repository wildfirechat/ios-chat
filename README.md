## 野火IM解决方案

野火IM是一套跨平台、全开源的即时通讯解决方案，主要包含以下内容。

| 仓库                                                         | 说明                                                    | 备注                                           |
| ------------------------------------------------------------ | ------------------------------------------------------- | ---------------------------------------------- |
| [android-chat](https://github.com/wildfirechat/android-chat) | 野火IM Android App                                      | 可以很方便地进行二次开发，或集成到现有应用当中 |
| [ios-chat](https://github.com/wildfirechat/ios-chat)         | 野火IM iOS App                                          | 可以很方便地进行二次开发，或集成到现有应用当中 |
| [pc-chat](https://github.com/wildfirechat/pc-chat)           | 基于[Electron](https://electronjs.org/)开发的PC平台应用 |                                                |
| [proto](https://github.com/wildfirechat/proto)               | 野火IM的协议栈实现                                      |                                                |
| [server](https://github.com/wildfirechat/server)             | IM server                                               |                                                |
| [app server](https://github.com/wildfirechat/app_server)     | 应用服务端                                              |                                                |
| [robot_server](https://github.com/wildfirechat/robot_server) | 机器人服务端                                            |                                                |
| [push_server](https://github.com/wildfirechat/push_server)   | 推送服务器                                              |                                                |
| [docs](https://github.com/wildfirechat/docs)                 | 野火IM相关文档，包含设计、概念、开发、使用说明          |                                                |

## 说明
本工程为野火IM iOS App。开发过程中，充分考虑了二次开发和集成需求，可作为SDK集成到其他应用中，或者直接进行二次开发，详情可以阅读[docs](http://docs.wildfirechat.cn).

开发一套IM系统真的很艰辛，请路过的朋友们给点个star，支持我们坚持下去🙏🙏🙏🙏🙏


### 联系我们
问题讨论请加群：822762829

<img src="http://static.wildfirechat.cn/qr_qqgroup.jpeg" width = 50% height = 50% />

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


### 编译

工程中已经包含了编译好的协议栈，也可以自己编译，编译方法参考[协议栈库](https://github.com/wildfirechat/proto)文档。然后打开ios-chat.xcworkspace工程，对每个项目进行编译。

### 工程说明

工程中有3个项目，其中1个是应用，另外两个2个是库。chatclient库是IM的通讯能力，是最底层的库，chatuikit是IM的UI控件库，依赖于chatclient。chat是IM的demo，依赖于这两个库，chat需要正确配置服务器地址。

### 配置

在项目的Config.m文件中，修改IM服务器地址配置。把```IM_SERVER_HOST```和```IM_SERVER_PORT```设置成火信的地址和端口。另外需要搭配应用服务器，请按照说明部署好[应用服务器](https://github.com/wildfirechat/app_server)，然后把```APP_SERVER_HOST```和```APP_SERVER_PORT```设置为应用服务器的地址和端口。

### 登陆
使用手机号码及验证码登陆，
> 在没有短信供应商时，可以使用[superCode](https://github.com/wildfirechat/app_server#短信资源)进行测试验证。
