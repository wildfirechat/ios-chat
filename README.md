## 说明
本系统有4部分组成，服务器部分/iOS部分（ios-chat）/Android部分（android-chat）/协议栈部分（mars）。其中iso和android都依赖于协议栈部分。本工程为iOS部分


### 编译

下载之后要先编译一遍协议栈，编译方法参考协议栈文档。然后打开ios-chat.xcworkspace工程，对每个项目进行编译。

### 工程说明

工程中有3个项目，1个应用和2个库。chatclient库是IM的通讯能力，是最底层的库，chatuikit是IM的UI控件库，依赖于chatclient。chat是IM的demo，依赖于这两个库，chat需要正确配置服务器地址。

### 配置

在项目的Config.m文件中，修改IM服务器地址配置。如果为了体验，把```USE_EMBED_APP```改成```YES```, 然后```IM_SERVER_HOST```和```IM_SERVER_PORT```设置成火信的地址和端口。如果生产使用，请使用独立应用服务器。

### 登陆
根据服务器说明，使用注册脚本注册的用户
