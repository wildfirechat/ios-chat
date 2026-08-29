# iPad 适配计划

野火 IM iOS 端目前只适配了 iPhone。本文记录 **iPad** 形态的适配调研结论与分阶段计划。

> **交互规范不自行发明。** android-chat 与 flutter-chat 已完成 pad 适配，本文的每一条交互规则
> 都注明了出处，以那两端的实现为准：
> - android-chat：`chat/.../main/TwoPaneNavigator.java`（601 行，右栏导航器）、
>   `chat/.../main/AppPaneRegistry.java`（右栏登记表）、
>   `uikit/.../utils/WfcDeviceUtils.java`（形态判定）
> - flutter-chat：`chat/lib/pad/pad_home.dart`、仓库根 `PAD_ADAPTATION_PLAN.md`（P0–P9）、
>   `PAD_VERIFY_CHECKLIST.md`（验收清单）
>
> **总原则：iPhone 现状（交互、视觉、功能）在整个适配过程中零变化。**
> 任何一步改动如果无法证明对 iPhone 无影响，就不做。

---

## 一、调研结论

### 1.1 iPad 现在的实际状态

| 项 | 适配前 | 说明 |
|---|---|---|
| 能否安装 | ❌ | 四个 target 全是 `TARGETED_DEVICE_FAMILY = 1` |
| 屏幕方向 | ❌ | `AppDelegate` 的 `supportedInterfaceOrientationsForWindow:` 硬锁竖屏，盖过 Info.plist |
| 布局形态 | ❌ | `WFCBaseTabBarController` 单栏拉满全屏 |
| 协议平台号 | ✅ | SDK 已自动上报 `Platform_iPad = 8`，见 `WFCCNetworkService.mm:911` |

### 1.2 存量红利

- **协议平台号不用改**。`WFCCNetworkService` 单例初始化时就按 `UI_USER_INTERFACE_IDIOM()`
  把 `isPad` 置上，`app_callback.mm:123` 据此上报 `PlatformType_iPad`。
  ⚠️ 但仍需与 im-server 确认 8 已被支持：平台号参与多端互踢与离线推送目标选择，
  iPhone 与 iPad 在服务端将不再是同一类端。
- **`WFChatUIKit` / `WFChatClient` 两个工程本来就是 `TARGETED_DEVICE_FAMILY = "1,2"`**，
  只有壳工程需要开。
- **导航调用点高度集中在 `UINavigationController`**。全仓 195 处 `pushViewController`，
  但只要替换 TabBar 里那 5 个导航控制器的类，就能在一处拦下全部左栏发起的跳转 ——
  相当于 flutter 端 `app_navigator` 那 88 个调用点零改动的红利。

### 1.3 核心障碍

| 障碍 | 规模 | 后果 |
|---|---|---|
| 全部手写 frame 布局，0 处 Masonry | 全仓 | 尺寸变化（旋转、分屏、栏宽）不会自动重排 |
| 直接读 `[UIScreen mainScreen].bounds.size.width` | 146 处 / 74 文件 | 双栏下按整屏宽算，一律溢出 |
| `actionSheet` 未设 popover 锚点 | 32 处中 28 处 | iPad 上**必崩** |
| 视图控制器无 `viewWillLayoutSubviews` | 消息页等 | 首次布局用错误宽度后不再纠正 |

`[UIScreen mainScreen]` 的 146 处分布：

```
MessageList 28 | Vendor 27 | Voip 25 | Me 9 | ConversationList 8 | Contacts 7
Favorite 5 | ConversationSetting 5 | Group 4 | CommonVC 4 | 其余 24
```

注意并非全部需要改：Voip 的 25 处大多在**全屏**通话/会议页里，按整屏算是对的；
真正要改的是会进右栏、或会进左栏的那些。

### 1.4 iOS 26 的分栏形态（lldb 实测，不是推断）

iPad Pro 11" 横屏 1210×834pt，`UISplitViewController`（legacy `viewControllers` 形式）：

```
primary   column=0   frame = (10, 32, 375, 792)     ← 悬浮面板，四周留白，圆角
secondary column=2   frame = (0,  0,  1210, 834)    ← 整屏满铺，压在 primary 下面
separator            frame = (385, 32, 0, 792)

右栏 VC 的 view:  frame = (0, 0, 1210, 834)
                safeAreaInsets = (top 32, left 385, bottom 20, right 0)
```

**右栏的栏宽是通过 `safeAreaInsets.left` 表达的，不是 `view.frame`。**
iOS 25 及更早是硬分栏（右栏 view 就是右半边，left inset 为 0），
所以布局代码统一按安全区算，两种系统都对，iPhone 竖屏时左右恒为 0 也不受影响。

这一条推翻了此前「右栏 view.bounds 就是栏宽」的假设，是第四节 1/2/3 号缺陷的共同根因。

---

## 二、交互规范

以下各条全部来自 android-chat / flutter-chat 的已落地实现。

**R1 · 两栏形态**（`main_pad_activity.xml`）
左栏固定宽度，装整套 TabBar（5 个 tab + 底部栏 + 搜索 + 加号），结构与手机版完全一致；
右栏是详情容器。中间 1pt 分隔线。左栏宽度 **320pt，10 寸以上 360pt**
（android `values/dimens.xml` 320dp，`values-sw840dp` 360dp）。

**R2 · 断点**（flutter `AppShell.multiPaneBreakpoint`）
窗口宽 **≥ 720pt 走双栏**，否则回落单栏 TabBar。
iPad mini 竖屏 744pt 刚好进双栏；1/3 分屏（320–375pt）自动回落单栏。

**R3 · 每个 tab 一条独立的右栏导航栈**（`TwoPaneNavigator.stacks`）
> 「共用一条栈的话，在通讯录点开某人资料再切到消息 tab，右栏还挂着那个人；
> 切回通讯录又变成了会话。微信 Pad 与 hm-chat 都是每 tab 一条栈。」

没进过的 tab 显示欢迎页。**懒建**：不进不建（工作台那条栈一建就是 WebView 要拉远端页面）。

**R4 · 换内容 vs 往下钻**（`TwoPaneNavigator.openInPane`，flutter P8/P9）
判据是**发起者在栏内还是栏外**：
- 发起者在左栏 → **换内容**：把当前 tab 的栈退回栈底再压入；
- 发起者已在右栏栈里（群资料点成员、联系人资料点「发消息」）→ **压栈**，下面那页留着，返回回得去。

**欢迎页是每条栈的永久栈底，压进右栏的页面一律有返回键**（`PaneStackFragment.pushPage`）：
> 「压进来的页面一律给返回箭头：它下面至少还有本栈的栈底（欢迎页或工作台网页），
> 返回过去是有意义的。与微信 Pad 一致 —— 从左栏点开任何一项后，右栏左上角都能退回欢迎页。」

「换内容」也只退到栈底（欢迎页）为止，不是把栈清空。两端此处**有分歧**，取 android，见第五节。

**R5 · 重复点开同一会话直接返回**（`isSameConversationAsTop`）
避免重建丢掉草稿与滚动位置。但**带定位参数时必须重建**——否则从搜索结果点进
「当前已打开的会话」不会跳转。

**R6 · 不进右栏、必须全屏的页面**（`AppPaneRegistry` 注释）
登录、闪屏、用户协议、备份与恢复、PC 登录确认、**媒体预览**、音视频通话与会议。
> flutter P7：「媒体预览……在右栏里就只盖住右半边；而且预览的进出场动画是按气泡的
> **全局**坐标算的，压错栈连动画起点都是偏的。」

> ⚠️ **本条此前记错了，已按 `PaneRegistry` 源码更正。** 原先还写着「以及所有『选择器』形态
> （选联系人、选会话、forResult）」—— 那是从 `AppPaneRegistry` 的注释推出来的，
> 而那份注释根本没提选择器。翻 `uikit/.../pane/PaneRegistry.java` 才看到：android
> **把选择器一律登记进了右栏** —— `ForwardActivity`、`PickContactActivity`、
> `PickGroupMemberActivity`、`AddGroupMemberActivity`、`CreateConversationActivity`、
> `MentionGroupMemberActivity`、`PickConversationActivity`、
> `PickOrCreateConversationTargetActivity`、`PickOrganizationMemberActivity`，
> 以及「改一段文字然后保存」的那五个页面，全部有登记项。
> 真正返回 null 走全屏的只有三处，而且理由是同一个 ——
> **同一个页面既是普通列表又是选择器**（`GroupListActivity` 带 `forResult`、
> `ChannelListActivity` 与组织架构页带 `pick`），右栏那一份是「普通列表」那一份，
> 回传不了结果。它甚至专门为「第一个进右栏的选择器」写过注释：
> 「`PickGroupMemberActivity` ……它需要回传结果，因此调用方必须用
> `WfcPageCompat.startPageForResult`。」
>
> iOS 没有这个二义性：选择器的结果是 block 回调，捕获在调用点，页面在哪一栏都能回传。
> 所以 iOS 上这一批一律留在右栏。

**R7 · 左栏选中态**（`conversationOnTopOfMessageTab` / `onConversationListChanged`）
- 高亮**只跟消息 tab 走**：当前 tab 不是消息时，左栏没有可高亮的行；
- 选中的会话从列表消失（删除会话、退群）→ 只弹**它所在那一栏**的那一页，不清整条栈；
- 守卫：必须先确认该会话「在列表里出现过」才清 —— 新建会话在发出首条消息前本来就不在列表里。

> 选中态**只有会话列表有**：android 全项目只有
> `ConversationListAdapter.setSelectedConversation` 与那一个
> `selector_conversation_item_two_pane.xml`，再无第二处 `setActivated`；
> flutter 只有 `_shell.selectedConversation`。通讯录 / 发现 / 我 三个 tab 两端都不做。

**R8 · 搜索开在右栏**
android 把 `SearchPortalActivity` / `SearchUserActivity` / `SearchMessageActivity` /
`SearchChannelActivity` 全部登记进了 `PaneRegistry`；flutter `app_navigator.openSearch`
把搜索路由压给右栏的 Navigator（「多栏形态压进右栏，单栏仍是整页」）。
> android 那一段还写了：「这几页 `providesOwnToolbar()==true`，右栏不会再给一条标题栏……
> 都不去重：每次进来都该是一张空搜索框，退回上次的搜索结果反而是错的。」

两端的**搜索框都长在搜索页自己身上**，不在列表那一栏：android 是
`search_bar.xml` 里的「搜索框 + 取消」那一条（58dp），左栏顶上只有一颗
toolbar 菜单项 `R.id.search`（`MainActivity.showSearchPortal()`）；flutter 同理，
`_onTapSearchButton` 是一颗按钮，输入框在 `SearchPortalDelegate` 里。

所以：点左栏顶部那条搜索框 → 它**不取焦点**，只负责**清空该 tab 的右栏栈到栈底、
压入一张新的搜索页**；焦点归右栏那张搜索页顶上的输入框（它一上屏就自己抢）。
点开某条命中后右栏换成那一页，搜索到此为止；点「取消」或退回欢迎页同样收工。

**R9 · 成员宫格每行几个**（android `values/integers.xml` 与 `values-sw600dp/integers.xml`）
`wfc_member_grid_span`：手机 **5**、平板 **8**。iPad 上继续按「栏宽的 1/5」排，
一个头像能有 140pt 宽，比列表行还高。

**R10 · 页面按自己那一栏的宽度排版，不是按屏幕宽**
android 的布局本来就是 `match_parent` + 约束，进右栏自动按栏宽排；宽屏下再额外封顶：
`values-sw600dp/dimens.xml` 里 `wfc_form_max_width` **400dp**（表单类内容，
「平板整宽拉伸的输入框既难看也难用，统一约束后居中显示」）、`wfc_card_max_width` **560dp**。
二维码那张页面 android 干脆是固定 250dp（`qrcode_activity.xml`），两端都不随屏宽走。
iOS 这边不少页面是拿 `[UIScreen mainScreen].bounds.size.width` 直接算 frame 的，
在右栏里就会按整屏宽排：文字顶到栏外、居中的东西偏到一边。

**工作台特例**（flutter P6）：两栏时左栏换成迎宾面板，网页常驻右栏。
「工作台没有『列表 → 详情』的层次，一整个网页塞进 320 宽的左栏没法看。」

---

## 三、分阶段计划

### P0 — 工程开关与崩溃兜底　✅ 已完成

| 改动 | 位置 |
|---|---|
| 4 个 target × 2 configuration 改 `TARGETED_DEVICE_FAMILY = "1,2"` | `WildFireChat.xcodeproj` |
| iPad 放开全部方向（iPhone 维持锁竖屏） | `AppDelegate.m:314` |
| actionSheet / 分享面板 popover 锚点统一兜底 | `WFCUPadUtility.m` 的 `presentViewController:` swizzle |

兜底而非逐点改，是因为 32 处里含第三方 `LBXAlertAction`，且新写的 actionSheet 会继续漏。
只在「iPad + actionSheet/分享 + 未设锚点」三个条件同时成立时才介入，iPhone 上恒不触发。

协议平台号已由 SDK 自动处理，本阶段无代码改动，但 **⚠️ 待办：与 im-server 确认 8 已支持**。

### P1 — 双栏 Shell 骨架　⚠️ 仅剩断点一项

已完成：
- `WFCUPadSplitViewController`（左栏 TabBar + 右栏详情，禁滑动隐藏）
- `WFCUPadPrimaryNavigationController`（左栏 5 个 tab 的导航控制器，拦截根页面发起的 push）
- `WFCUPadPlaceholderViewController`（右栏欢迎页）
- `WFCBaseTabBarController.rootViewController` 统一工厂；4 处切根控制器入口全部接入
  （冷启动 ×2、**登录成功**、改字号重建）
- 窄↔宽跨断点时把右栏页面在两种形态间搬运

- 左栏定宽 320 / 短边 ≥840pt 的大屏 360（`WFCUPadUtility.primaryColumnWidth`，
  min 与 max 取同一个值）。实测左栏落在 320，与 android 的 `dimens.xml` 一致
- **每个 tab 一条独立的右栏栈**（`WFCUPadSplitViewController.detailStacks`，按 tab 下标存）。
  换栈用 `setViewControllers:` 而不是隐藏，切走那条栈上的会话页才会真的走
  `viewWillDisappear` —— 否则它在后台继续把新消息标记成已读（android 注释里记过同样的坑）。
  实测 5 个 tab 各自持有自己的页面互不串台
- 用户点 TabBar 走 `UITabBarControllerDelegate`；代码里改 `selectedIndex` 不触发代理，
  由 `WFCBaseTabBarController` 重写 `setSelectedIndex:` / `setSelectedViewController:` 补上
- 跨断点搬运按 tab 分别搬运，不再把所有页面塞给当前 tab；
  摘出去右栏的是「第一个未标 `wfcu_prefersPrimaryColumn` 的页面起往上」那一段，
  对应 flutter 的「设置/资料这类页面不受牵连」。
  **注意：`wfcu_prefersPrimaryColumn` 目前全仓库没有一处在设**，机制通了但名单是空的，
  所以现在所有下钻页都会去右栏 —— 名单属 P4

- **右栏内容硬钉在安全区右侧**（`WFCUPadDetailContainerViewController`，见第五节的决定）。
  iOS 26 起右栏 view 是满铺整屏的，栏宽藏在 `safeAreaInsets.left` 里：新页面压进右栏的头一帧
  安全区还没传下来（转场中的视图更是先在屏外排一次版），页面按整屏宽排了一遍，
  内容就从悬浮左栏底下透出来闪一下（缺陷 #12）。右栏外面套一层容器，把导航控制器的 view
  钉在安全区右侧那一块并 `clipsToBounds`，页面再怎么算也画不到左栏那一条上。
  安全区随之逐级传下去（左边距被容器吃掉，顶部状态栏、底部 Home 指示条照旧），
  页面里按安全区算的布局一行没动。iOS 25 及更早本来就是硬分栏（left inset 恒为 0），
  这一层退化成整块铺满，逐字节等价

待改：
- [ ] 断点改为显式 720pt。当前依赖 UIKit 的 regular/compact 自动折叠，**取值未与另两端核对**。
      需要在 iPad mini 竖屏 744pt 与 1/2 分屏 507pt 两个点上实测比对再决定，见第五节

### P2 — 路由规则　⚠️ 部分完成

已完成：
- 左栏根页面发起的 push → 换右栏内容；右栏内发起的 push → 压右栏栈（R4 两半都已成立）
- **欢迎页常驻栈底，右栏能一路返回到欢迎页**。原先 `showDetailViewController:` 用
  `setViewControllers:@[vc]` 换根，栈深恒为 1，压根没地方可退。现在改成
  `@[欢迎页, vc]`：欢迎页在则复用、不在则补一个。连带四处：
  跨断点展开时摘出来的那段也要补栈底；`postDetailDidChange` /
  `currentDetailRootViewController` 改成「取第一个非欢迎页」而不是 `firstObject`；
  加 `didShowViewController:`，点返回退回欢迎页后左栏高亮跟着撤掉
  （android 用 `addOnBackStackChangedListener`、flutter 用 `NavigatorObserver` 做同一件事）；
  欢迎页设空标题的 `backBarButtonItem`，返回键才是个光秃秃的箭头而不是「返回」二字
- R5 重复点开同一会话直接返回（`UIViewController.wfcu_padPageKey` + 比栈顶）。
  定位参数（`highlightMessageId` / `highlightText` / `selectedDate`）编进 key，
  所以「同一个会话但要停在不同位置」仍然重建，对应 android
  `isSameConversationAsTop` 里那句「需要定位时即使是同一个会话也要重建」

- R6 的媒体预览部分。iOS 存量代码默认全是 push，没法照抄 android「白名单之外全屏」的形状，
  改成列黑名单：`WFCUPadUtility.requiresFullScreen:`（`MWPhotoBrowser` /
  `WFCUImagePreviewViewController` + `wfcu_prefersFullScreen` opt-in）。
  两条路径都拦：push 由左右两个导航控制器子类拦下改为全屏模态
  （右栏新增私有的 `WFCUPadDetailNavigationController`）；已经是模态的那一路在
  `presentViewController:` 的 swizzle 里把 iOS 13 起默认的 pageSheet 卡片拉回全屏。
  拦截按导航控制器的**类**生效，不看全局的双栏标志 —— 相册选择器内部（`DNImageFlowViewController`）
  那种模态里的 push 用的是普通 `UINavigationController`，不会被误伤。
  包在导航控制器里弹出是必需的：MWPhotoBrowser 的「完成」按钮挂在 `navigationItem` 上，
  不套一层就没地方显示，也就关不掉

- **「+ → 发起聊天 / 发起密聊」进右栏**（实测反馈：这两页还是全屏）。原先是
  `presentViewController:` + `UIModalPresentationFullScreen`，模态盖住整个窗口。
  android 把 `CreateConversationActivity` 登记进了 `PaneRegistry`，注释写得很直白：
  「发起群聊 / 新建会话。不回传结果，建完直接把会话压在本页上面。」所以这里也是
  选完人 **push** 会话（`pushDetailViewController:`），而不是 dismiss 再换右栏内容。
  页面 key 取类名，连点两次不会在右栏叠出两张选人表。
  连带改 `WFCUSeletedUserViewController.cancel`：在右栏里没有模态可关，改为 pop
  （用 `presentingViewController` 是否为空区分两种形态）。
  **选完人之后是「顶替」而不是「压栈」**（缺陷 #19）：新增
  `WFCUPadUtility.replaceDetailViewController:animated:`，对应 android 专门为此写的
  `replacePage`——「从『发起群聊』的选人页建完群，选人页就该消失」。
  单聊、密聊、建群三条路径都走这一条，从新会话返回时回到欢迎页而不是那张用完的选人表。
  栈底（欢迎页 / 工作台网页）不参与顶替，返回键始终有落点

- **会话列表的搜索结果进右栏**（实测反馈）。对应 android 登记 `SearchPortalActivity` 的那一条
  ——搜索是「一屏内容」，不该把左栏的会话列表顶掉。左栏那张表从此恒为会话列表，
  搜索结果渲染在右栏新开的 `WFCUPadSearchResultViewController` 上，
  两张表共用同一个 dataSource（搜索的取数、分组、展开、点击全长在会话列表控制器身上，
  搬出来等于把那几百行抄第二遍）。判据从 `searchController.active` 换成
  `isSearchTableView:` —— 「问我的是哪张表」，单栏形态下逐字节等价。
  点开某条命中后右栏换成那个会话，此时搜索自动收起（挂在
  `WFCUPadDetailDidChangeNotification` 上，不用在三类命中的分支里各写一遍）；
  取消搜索只在右栏还挂着搜索结果时才清空右栏。
  android 那边搜索页「不去重：每次进来都该是一张空搜索框」，这里每次新建一个页面，同理

- **其余选择器只占右栏，不再盖住整个窗口**。判据不是「有没有回传结果」—— 见 R6 那条更正，
  android 把选择器全登记进了右栏。iOS 这边这一批（转发、选人、选联系人、改一段文字、
  互联域、发送位置、投票/接龙详情）都是 `present` 出来的模态，而模态在 iOS 上必然盖满窗口，
  所以问题出在**形态**而不是路由。
  用 UIKit 给分栏详情栏准备的现成机制解决：右栏导航控制器置 `definesPresentationContext = YES`，
  这批模态的 `modalPresentationStyle` 改成 `UIModalPresentationCurrentContext`，
  UIKit 便从发起者往上找到右栏导航控制器当容器，模态只盖住右栏。
  名单在 `WFCUPadUtility.detailPaneClassNames`，逐条对应 android 的登记项。
  左栏发起的（会话列表的「+」、通讯录、我 里那些入口）改由右栏代为弹出 ——
  否则 `CurrentContext` 向上找到的是左栏那条 320pt 宽的导航控制器，页面会缩在左边一条里。
  **没有改成压栈**（android 那边是压栈的页面），理由见第五节
- **深链落到消息 tab 的栈**。对应 android `TwoPaneNavigator.openInTab(tab, intent, resetFirst)`，
  那边的注释是「在指定 tab 的栈里打开页面，并把左栏切到该 tab。用于外部入口（通知点击、深链）」。
  外部进来的用户资料/群资料不该压到当前恰好停在的那个 tab（比如「我 → 设置」）的栈上。
  新增 `AppDelegate.externalEntryNavigationController`：双栏下先把左栏切到消息 tab，
  再交给那条左栏导航控制器（它的 `pushViewController:` 会按 R4/R5 转到右栏）。
  单栏下不切 tab —— 那会把用户从当前页面拽走，与原行为不符。
  扫码结果**不**走这一条：它是从当前 tab 里发起的（通讯录 → 扫一扫），android 的
  `openInTab` 也只说「用于外部入口」，所以扫出来的页面留在扫码所在的那一栏。
  连带修掉一处已经失效的分支：`currentNavigationController` 原先认为分栏的
  `viewControllers.lastObject` 就是右栏导航控制器，加了容器层之后不再成立；
  何况直接往右栏裸 push 本来就绕过了 R4/R5，现在统一交给左栏那条导航控制器

待做：本阶段没有遗留项。

### P3 — 面板宽度正确性　✅ 已完成

已完成：
- 气泡最大宽度改为按聊天栏宽计算并封顶（`WFCUMessageCell.bubbleWidth`）
- 消息页 `viewWillLayoutSubviews` 重排；顶部内边距改用 safeArea（iPad 导航栏 50pt ≠ iPhone 44pt）
- 输入栏 `relayoutForParentBoundsChange`
- 会话列表 cell 的 10 处屏幕宽改为 cell 宽
- 登录表单限宽 420pt 居中（已实测）

- **消息页按水平安全区布局**（`contentFrame` = view.bounds 去掉四边安全区），
  这是 1.4 节那条实测结论的直接落地。气泡、输入栏、通话浮层、新消息提示、
  入群申请条全部改用内容区坐标系
- 右栏导航栏的显隐改由 `WFCUPadSplitViewController` 按「栈顶是不是占位页」统一决定。
  原先写在占位页的 `viewWillDisappear` 里恢复，而右栏是 `setViewControllers:` 直接换根页面的，
  这个回调不保证被调用 —— 一旦漏掉，聊天页就没有标题也没有返回键
- 占位页图标按安全区居中，不再跑到整屏正中

- **表情 / 扩展面板只占右栏**（实测反馈：这两块横向铺满了整个窗口）。根因不是算错宽度，
  而是形态错了：两块面板是当作 `textInputView.inputView` 弹出的，等于一块自定义键盘，
  由系统摆在窗口底部，宽度必然是整屏，横跨左右两栏。
  android(`EmotionLayout`) 与 flutter(`ConversationPane` 里的表情面板) 两端，面板本来就是
  会话页里的一层普通视图 —— 改成同一形态：双栏下面板内联挂在 `backgroundView` 上，
  宽度即会话栏宽度。三处配套：
  - 切到面板时主动 `resignFirstResponder`，`keyboardWillHide:` 按新的 `padBoardHeight`
    把输入栏摆到面板上面 —— 只有一次动画，不会先落到底再弹上来；
    `padBoardHeight` 为 0 时与原来逐字节相同
  - 面板期间输入框不是第一响应者，`selectedTextRange` 为 nil：光标位置自己记
    （否则表情一律插到最前面），退格也自己删（按 composedCharacterSequence 取，
    emoji 是多码位的）
  - 两块面板都改成宽度可变（`layoutSubviews` 里按新宽重排）。iPhone 锁竖屏、面板又是按屏宽建的，
    这个分支永远进不来，是真正的 no-op

- **剩下那批按屏幕宽算的 cell 与页面全部改完**。判据统一成「谁在问就按谁的宽度算」：
  - 聊天里的卡片（`WFCURichNotificationCell` 8 处、`WFCUArticlesCell` 3 处）改按
    `[WFCUMessageCell chatContentWidth]` —— 与气泡同一个口径；
  - 合并消息详情（`WFCUCompositeBaseCell` 4 处）加了一个 `+setListWidth:`，
    由 `WFCUCompositeMessageViewController` 在布局时写进来。cell 里全是手写 frame、
    还有 `+contentFrame` 这种类方法，宽度只能从外面给，与 `chatContentWidth` 同一个套路；
  - cell 里那些在 `init`/getter 里按屏幕宽定死位置的控件（联系人在线小圆点、好友申请与
    入群申请的「接受」按钮、开关 cell 的 `UISwitch`、搜索结果 cell 的时间/摘要、
    转发选择 cell、文件记录 cell），一律补一个 `layoutSubviews` 按 cell 真实宽度纠回来。
    **不能在 `setXxx:` 里直接读 `self.bounds`**：新建（未复用）的 cell 那会儿宽度还是系统默认的
    320，iPhone 上会算错；排版时才是真实宽度
  - 页面级的（`WFCUMyProfileTableViewController`、`WFCUModifyMyProfileViewController`、
    `WFCUGroupInfoViewController`、会话详情的频道头部与二维码图标）改按 `self.view` / 表宽算

  以上每一处在 iPhone 上都取到与改之前同一个数（cell 宽 = 表宽 = 屏幕宽；页面宽 = 屏幕宽）。
  余下仍按屏幕宽算的集中在 Voip（全屏通话/会议页，按整屏算本来就是对的）

待做：本阶段没有遗留项。

### P4 — 各 tab 下钻页与工作台　⚠️ 部分完成

- [x] 会话详情页的成员宫格（缺陷 #7）。根因是 `WFCUConversationSettingMemberCollectionViewLayout`
      按屏幕宽除以 5 排格子、还把结果缓存住了：右栏比屏幕窄，5 列一排就顶到栏外，
      表头高度也跟着算大。改成由调用方给 `layoutWidth`（未设时退回屏幕宽 = iPhone 原行为），
      并去掉缓存 —— 栏宽会随旋转/分屏变，缓存住就再也纠不回来。
      这一页的表格与宫格都是按 `viewDidLoad` 那一刻的宽度定死的，另加了一个 **仅 iPad 生效**的
      `viewWillLayoutSubviews`，宽度变了整页重排一次
- [x] **工作台特例**：左栏换成迎宾面板，网页常驻右栏。取自 flutter 的 `PadWorkspaceWelcome`
      （「工作台没有『列表 → 详情』的层次，一整个网页塞进 320 宽的左栏没法看」，
      与 hm-chat 的 `WorkspacePane` 同一套）。落地方式是给右栏栈引入「栈底可以不是欢迎页」：
      新增 `wfcu_padDetailRootViewController`，标了它的 tab，那条栈的栈底就是它
      （对应 flutter `_initialPaneRoutes` 里「工作台 tab 的基座就是工作台本身」）。
      迎宾面板上只放问候语 + 日期两块静态信息 —— flutter 记过原因：
      「左栏一旦出现可点的入口，用户就会预期它在右栏里打开，而右栏此刻被工作台网页占着，
      两者会互相打架」。iPhone 上这个 tab 一行没动，仍是整页网页
- [x] 长按菜单定位。`KxMenu showMenuInView:self.view fromRect:menuPos`，而
      `menuPos = [baseCell convertRect:… toView:self.view]` —— 两边都是会话页自己的坐标系，
      与页面在哪一栏无关，**无需修改**（`UIMenuController` 那处只用来清菜单项，不涉及定位）
- [x] **成员宫格每行几个**（R9）。原先固定 5 列，iPad 右栏 704pt 时每格 140pt。
      改成 iPhone 恒为 5、iPad 按「每格不超过 96pt」反推列数（下限仍是 5）：
      704pt 算出 8 列，与 android 平板那份 `wfc_member_grid_span=8` 对上；
      12.9 寸横屏 1046pt 算出 11 列。这里显式按机型分叉而不是只靠公式 ——
      最宽的 iPhone 竖屏 440pt 算出来也还是 5，但横屏 926pt 会算成 10，那就不是零变化了。
      顺带把 `Group_Member_Visible_Lines * 5`（「最多几行，多的收进查看更多」）
      改成按 `itemsPerLine` 算
- [x] **会话扩展里「视频通话」的类型选择框位置**。它是全项目唯一一处自带 iPad 分支的
      actionSheet：`sourceRect` 设成整块会话视图的 `bounds`，UIKit 只能把气泡硬塞进这块矩形里，
      落点跟另外三十来处对不上。删掉这段，交给 `WFCUPadUtility` 那条统一兜底
      （会话栏底部居中、不带箭头）。iPhone 走的是从底部升起的那条路径，与此无关
- [x] **按栏宽排版的页面**（R10）。统一入口 `WFCUPadUtility.layoutWidthForView:` ——
      iPhone 上原样返回屏幕宽（这些页面恒等于整屏宽，取值一个不变），iPad 上返回页面自己的宽度；
      同时给相关子视图配上 autoresizing，页面还没上屏、以及旋转/Stage Manager 改栏宽时会自己纠回来。
      改到的页面：用户资料页（昵称/野火号/收藏星标）、二维码页（个人 + 群，见下条）、
      频道资料页（头像居中、简介、底部订阅按钮）、域资料页、
      「改一段文字」页（改群名、改昵称…的输入框）、聊天室列表（两列网格按栏宽算）、
      收藏列表（量文字高度改按表宽，否则长文本被切）；
      以及四处按屏幕宽定位的 cell：群列表、群成员（多选那个勾）、频道、发现-朋友圈的小头像
      （后者在 320 宽的左栏里，原先直接落到栏外）
- [x] **二维码卡片封顶**（R10）。原先是「页面宽的 5/6」，右栏 704pt 算出接近 600pt，
      一张卡片比半个屏幕还大。iPad 上按 android `wfc_form_max_width`（400dp）封顶后居中，
      iPhone 仍是 5/6
- [x] **各 tab 下钻页的宽度跟随**（缺陷 #22）。判据统一成「主表格/网格一律配 `autoresizingMask`」：
      这批页面（设置、隐私、备份恢复、收藏、文件、网盘、黑名单、群管理四页、
      查找聊天内容、已读列表、投票、频道搜索…共 38 处）的表格都是按 `viewDidLoad`
      那一刻的 frame 定死的，栏宽一变就不跟。iPhone 锁竖屏、页面恒等于整屏，这一行是 no-op。
      查找聊天内容页那四颗分类按钮是两列手写 frame，另抽出 `layoutCategoryButtons`
      在 `viewDidLayoutSubviews` 里按当前宽度重排
- [x] **聊天室列表的格子内容**（缺陷 #23）。列表本身已按栏宽算 itemSize，但
      `ChatroomItemCell` 的头像/标题是在 getter 里按当时 bounds 定死的，补 `layoutSubviews`
- [ ] 通讯录 / 发现 / 我 三个 tab 的其余下钻页逐页实测（路由与宽度跟随已覆盖，剩视觉复验）
- [ ] 收藏列表里除文本/组合外的其它类型（图片、文件、位置…）行高仍按各自的常量算，
      未按栏宽复核

### P5 — 左栏选中态与失效　✅ 已完成

已完成：右栏当前会话在左栏高亮；切到别的 tab 自动取消；iPhone 上不显示选中态。

- **R7 会话被删除 / 退群后清右栏**。对应 android `TwoPaneNavigator.onConversationListChanged`，
  连守卫一起照搬：右栏打开的会话在列表刷新后不见了，才清；且必须先确认它
  「在列表里出现过」—— 新建的会话在发出第一条消息之前本来就不在列表里，
  不守这一下会把刚点开的新会话立刻关掉。
  只退它所在的那一栏（新增 `WFCUPadUtility.resetDetailStackForTabAtIndex:` →
  `stacks.get(tab).reset()`）：别的 tab 的栈上压着完全无关的页面，不该被连累。
  会话所在的 tab 在 `WFCUPadDetailDidChangeNotification` 到达时记下来，
  同一个会话的重复通知（往下钻、返回）不重置「出现过」标记，否则中间来一次刷新就会误判
- **高亮严格只跟消息 tab**：`isPadSelectedConversation:` 先看当前 tab 是不是这张列表所在的那个
  （`tabBarController.selectedViewController == self.navigationController`），
  不是就没有可高亮的行。切 tab 会发一次详情变更通知，高亮跟着重算，切回来会亮回去

待做：本阶段没有遗留项。

### P6 — iPad 专属体验　❌ 未开始

- [ ] 旋转时会话列表滚动位置保持、键盘高度按方向分别缓存
- [ ] 相册选择器（`ZLPhotoBrowser.xcframework`，第三方二进制）在 iPad 上的列数
- [ ] 通话 / 会议横屏
- [ ] 分屏、台前调度下确认窗口尺寸变化不触发 IM 重连
- [ ] 外接键盘（⌘↩ 发送等）

### P7 — 验证　❌ 未开始

设备矩阵与逐项验收另起 `PAD_VERIFY_CHECKLIST.md`，结构对齐 flutter-chat 那一份。
iPhone 回归是全程红线，每阶段都要跑。

---

## 四、缺陷跟踪（实测，iPad Pro 11" 横屏 / iOS 26.5）

| # | 现象 | 状态 |
|---|---|---|
| 1 | 右栏聊天页气泡完全不显示 | ✅ 已修。根因见 1.4：右栏 view 是满屏的，栏宽在 `safeAreaInsets.left` 里，气泡被压在左栏底下 |
| 2 | 右栏聊天页左上角一块游离的白色圆角块 | ✅ 已修。是 `joinGroupRequestButton`：单聊根本不走 `updateUnreadJoinGroupRequestButton` 的置零分支，它一直是 `(0,0,屏宽,36)`；iPhone 上藏在不透明导航栏后面看不出来，右栏没有导航栏遮挡就露了出来。**这是存量缺陷，不是 iPad 引入的** |
| 3 | 「N 条新消息」按钮位置错乱、被右边缘截断 | ✅ 已修。按钮挂在 `backgroundView` 上却按 `self.view` 宽度定位 |
| 4 | 左栏最后一行会话被悬浮 TabBar 盖住 | 复测未复现，列表的 `adjustedContentInset` 底部为 72 已生效 |
| 5 | 会话未读红点压在头像左上角 | 复测未复现，红点在头像右上角 |
| 6 | 图片/视频预览只盖右半边 | ✅ 已修，见 P2 的 R6。**待实测复验** |
| 7 | 右栏「会话详情」页顶部成员宫格错位 | ✅ 已修。宫格按屏幕宽除以 5 排格子且缓存了结果，右栏比屏幕窄就顶到栏外。见 P4。**待实测复验** |
| 8 | 右栏无法返回欢迎页，返回键根本不出现 | ✅ 已修。根因：右栏换内容时把欢迎页也换掉了，栈深恒为 1。见 P2 |
| 9 | 表情 / 扩展面板横向铺满整个窗口 | ✅ 已修。根因是形态错了：面板是当作 `inputView`（自定义键盘）弹出的，宽度必然整屏。改成内联在会话栏里，见 P3。**待实测复验** |
| 10 | 「+ → 发起聊天」等页仍是全屏模态 | ✅ 已修，见 P2。其余选择器（转发、选联系人、改群名…）已一并关进右栏。**待实测复验** |
| 11 | 会话列表搜索时结果占了左栏 | ✅ 已修，改到右栏，见 P2 / R8。通讯录 tab 的搜索框已一并按同一套处理。**待实测复验** |
| 12 | 压页面进右栏时，左栏后面闪一下新页面的内容 | ✅ 已修。iOS 26 的右栏是满铺整屏的，头一帧安全区还没传下来，页面按整屏宽排了一遍，从悬浮左栏底下透出来。见 P1 的容器层。**待实测复验** |
| 13 | 会话扩展 → 视频通话，弹出的通话类型选择框位置不对 | ✅ 已修。全项目唯一一处自带 iPad 分支的 actionSheet，`sourceRect` 设成整块会话视图的 bounds。删掉这段，交给统一兜底。见 P4。**待实测复验** |
| 14 | 会话详情页成员头像在 iPad 上太大 | ✅ 已修。见 P4 / R9：iPad 按「每格不超过 96pt」反推列数，右栏 704pt 算出 8 列，与 android 平板 span=8 一致。**待实测复验** |
| 15 | 通讯录 tab 的搜索框没有按 R8 处理 | ✅ 已修。与会话列表同一套：清空该 tab 的右栏栈并压入搜索结果页，左栏保持完整通讯录。**待实测复验** |
| 16 | 左栏那条搜索框会取焦点，搜索页自己没有输入框 | ✅ 已修，见 R8。左栏那条只当按钮用（输入框关掉 + 点击手势），输入框改在右栏搜索页顶上，压进去就自动取焦点。**待实测复验** |
| 17 | 用户资料页、个人/群二维码等页未按栏宽排版 | ✅ 已修，见 P4 / R10。同批还改了频道资料、域资料、改名页、聊天室列表、收藏列表，以及四处按屏幕宽定位的 cell。**待实测复验** |
| 18 | 右栏搜索页：搜索框自成一条 58pt，导航条上还立着一个返回键 | ✅ 已修。搜索框改挂 `navigationItem.titleView`，`hidesBackButton = YES`，「取消」挪到导航条右侧 —— 与 android `providesOwnToolbar()==true`「取消是唯一出口」对齐，也省下那 58pt。见第五节那条差异记录的更正。**待实测复验** |
| 19 | 建完会话后返回，会退回到那张已经用完的选人页 | ✅ 已修。新增 `WFCUPadUtility.replaceDetailViewController:animated:`（android `TwoPaneNavigator.replacePage`：「从『发起群聊』的选人页建完群，选人页就该消失」），单聊 / 密聊 / 建群三条路径都改成顶替而不是压栈，返回直接回欢迎页。**待实测复验** |
| 20 | 「发起聊天」页右上角的「完成」看不清 | ✅ 已修。存量缺陷：那颗按钮从没设过标题色，靠的是 `UIButtonTypeCustom` 的默认白色（代码里那句 `setTintColor:` 管不到自定义按钮的标题），白字落在浅色导航条上就没了。改成与左边「取消」同一个 `naviTextColor`。深色那一支（密聊/会议选人把导航条改成 0x1f2026）仍是白字，只是显式写出来。**这是存量缺陷，不是 iPad 引入的** |
| 21 | 群会话详情页从「改群名」返回时，顶部成员宫格从左上角闪到正确位置；实测进一步收敛为：返回后整页偏到左栏底下 / 位置对了但很快往右挪 / modal 消失后成员列表偏左被左栏覆盖、随后才往右移到正确位置 | ✅ 已修。第一版在 `viewWillAppear:` 里整段包 `performWithoutAnimation` 无效——这一下仍落在模态退场的动画事务里，此刻本页宽度还是过渡值（整屏宽），重建的宫格从左上角「飞」到正确位置。第二版：`viewWillAppear:` 在 iPad 上不再重建宫格（只刷数据），重建移到 `viewDidAppear:`（转场结束、宽度已稳定，不在动画事务里）；`viewWillLayoutSubviews:` 增加「模态弹收期间跳过」的守卫（`presentedViewController` 非空即跳），宽度变化时的整页重排再包一层 `performWithoutAnimation`。**实测仍坏**。第三版：容器在模态转场进行中跳过重钉 + 左边距合理性守卫 + dismiss swizzle 收回后补钉 + 本页表格补 `autoresizingMask`。**实测仍坏**（成员列表偏左被左栏覆盖后才往右挪）——两个新发现：① 容器「跳过」重钉等于把右栏内容留在系统挪到的错误位置，要等收回完成才纠；转场中应该**主动钉回上次的正确 frame**，下一轮布局立刻拉回来。② 本页 `viewWillLayoutSubviews` 的守卫用 `presentedViewController` 判断，而它在 dismiss 一开始就被系统清掉，收回动画那一段守卫失效——宽度过渡值时按整屏宽重建宫格，宫格立刻排到左栏底下；收回后再按最终宽重建才「往右挪回」。第四版：① 容器转场中不再只是跳过，而是 `performWithoutAnimation` 钉回 `_lastGoodFrame`（上次钉好的整个 frame，不单是左边距）；② 本页 `viewWillLayoutSubviews`/`viewWillAppear`/`viewDidAppear` 全部改用同一套 `isModalTransitionInProgress` 标记：`viewWillLayoutSubviews` 转场中直接返回，`viewWillAppear` 区分「首次出现（无转场，正常重建让宫格在 push 里就存在）」与「模态收回（只刷数据，重建交给 viewDidAppear/viewWillLayoutSubviews）」，`viewDidAppear` 转场刚结束时也先跳一轮等稳定宽度。**实测仍坏（R4 毛用没有）**。第五版（根因找到）：dismiss 动画中系统改的是**容器里 nav view 的 frame**，而容器自身的 bounds/安全区没变，`viewWillLayoutSubviews` 根本不会被触发——第四版的「转场中钉回」从未执行过，内容一直停在全屏位置，直到收回完成后的补钉才「往右挪回」；另外完成回调那一刻布局也还没稳定（nav view 还停在全屏、页面宽度还是过渡值）。于是：① 转场期间用 CADisplayLink 每帧驱动容器重钉（`relayoutDetailContainerIfNeeded`），把内容钉回 `_lastGoodFrame`，不等容器自己的布局钩子；② 清标记后留 0.25s 冷却期，期间 `isModalTransitionInProgress` 仍返回 YES，页面不会按过渡宽度重建宫格，容器继续钉回，等稳定再放开。**实测：正确**（名称等项位置一直对，宫格不再闪动）。**R5 收尾（按用户要求最小化）**：删掉第四版里已被证明冗余/无效的防御——容器的 `contentHasPresentedViewController` BFS（转场已被共享标记罩住，稳定呈现的模态不挪安全区）、容器左边距 3 帧合理性守卫（非转场时 safeAreaInsets 是真实值）、`relayoutDetailContainerIfNeeded` 的 `dispatch_async` 包装（displaylink 已每帧驱动）、dismiss 完成回调里的补钉（displaylink 会持续到冷却期结束，无需补发）、本页 `viewDidAppear` 重建（容器每帧钉回后宽度从未变过，宫格一直是 push 时排好的布局）。保留：CADisplayLink 每帧钉回 + 冷却期 + 容器 `_lastGoodFrame` 钉回 + 本页两处 `isModalTransitionInProgress` 守卫（`viewWillLayoutSubviews` 直接返回、`viewWillAppear` 只刷数据不重建）。**实测复验通过，最小化后待用户复验** |
| 22 | 查找聊天内容页、管理 → 群成员权限页等下钻页未按栏宽排版 | ✅ 已修。这批页面的主表格/网格都是按 `viewDidLoad` 那一刻的 frame 定死的，统一补 `autoresizingMask`（38 处，iPhone 上恒为 no-op）；查找聊天内容页那四颗分类按钮另抽出 `layoutCategoryButtons` 按当前宽度重排。**待实测复验** |
| 23 | 聊天室列表的格子内容不随栏宽变 | ✅ 已修。`ChatroomItemCell` 的头像与标题是在 getter 里按当时 bounds 定死的，栏宽变了（列表已按栏宽重算 itemSize）子视图不跟，补 `layoutSubviews`。**待实测复验** |
| 24 | 用户资料页「发送消息」「视频聊天」未水平居中；实测进一步收敛为：表格停在整屏宽（1210pt）上，按钮按 1210pt 排、内容中心偏到栏外；从模态返回后位置对了但很快往右挪；modal 返回后顶部头像等保持不动（不再闪） | ✅ 已修。这两颗是铺满整行、内容居中的按钮，宽度取自 `layoutWidthForView:`；而 `loadData` 在 `viewDidLoad` 里就跑了一次，那时页面还没上屏、退回的是屏幕宽，按屏幕宽排出来的中心就偏到栏外。第一版按 `contentView` 起排 + `FlexibleWidth` 实测无效——创建那一刻 cell 的 `contentView` 还没排版（宽度为 0 或默认值），autoresizing 的纠偏不可靠。第二版：行宽到 `tableView:willDisplayCell:forRowAtIndexPath:` 才真正定下来，在那一刻按真实行宽重排「发送消息」「视频聊天」「加好友」「设置备注」四颗按钮和头部那颗星，之后旋转/分屏宽度再变也会再走这里；iPhone 上行宽恒等于屏幕宽，整段是 no-op。**实测仍坏**，`willDisplayCell` 按 `host.bounds.width`（即表格宽）排，而表格本身停在了 `viewDidLoad` 时的整屏宽上：页面刚上屏时安全区还没传下来、容器按 0 钉过一帧，页面 1210pt，表格无 `autoresizingMask` 也没人纠正 frame，之后容器把页面钉回右栏（825pt）时表格不跟。第三版：表格补 `autoresizingMask = FlexibleWidth|FlexibleHeight`，被钉回右栏时自己缩回来，`willDisplayCell` 的纠偏随即生效；「从模态返回后往右挪」同 #21，容器层根治。**实测：按钮居中已好，模态返回后顶部头像保持原位不再闪**（本页没有宽度重建逻辑，容器转场中钉回正确 frame 后页面稳定不动）。**已实测复验通过**，与 #21 同一套容器层机制（CADisplayLink 每帧钉回 + 冷却期）一并生效 |

另有一处**非本次改动引入**的既有崩溃需留意：IM 未连接完成时点进会话，
`-[WFCCIMService clearUnreadStatus:]` 内部 abort（`reloadMessageList` 回调里）。
冷启动后 6 秒内点会话必现，20 秒后正常。iPhone 上同样存在，只是不容易撞上。

---

## 五、与参考实现的差异记录

已经定下来的：

- **iOS 26 的悬浮左栏：外观保留，内容不许穿过去**。见 1.4：系统在 iOS 26 把左栏画成悬浮面板
  压在满铺的右栏上，而 R1 描述的是「左栏定宽 + 1pt 分隔线」的硬分栏，微信 iPad 也是硬分栏。
  没有替掉 `UISplitViewController`（那要自己实现折叠/展开与手势，代价远大于收益），
  而是在右栏外面套一层容器，把内容钉在安全区右侧那一块并裁掉外面——
  观感上就是硬分栏，左栏那一条留给容器的背景色，系统的悬浮面板照旧浮在上面。
  缺陷 #12（压页面进右栏时左栏后面闪内容）是这条决定的直接动因：满铺右栏 + 手写 frame，
  只要有一帧安全区没传到，内容就画到左栏底下去了。
  代价：显式断点与每 tab 一条栈的完全控制权仍然没有，前者见上面那条待定。

- **选择器在 iOS 上保持模态形态，只是把它关进右栏**。android 把转发/选人这些登记成右栏的
  *页面*（压栈、有返回键）；iOS 这边它们全是 `present` 出来的模态，回调、取消按钮、
  `dismissViewControllerAnimated:` 三样都绑在模态形态上。改成压栈要把每一处的
  「选完 → dismiss」翻译成「选完 → pop 到发起页」，而其中一类（选完人接着 push 新页面，
  再 dismiss 自己）两种语义正好打架 —— android 那边专门为此写了 `replacePage`
  （「从『发起群聊』的选人页建完群，选人页就该消失」）。
  用 `definesPresentationContext` 把模态限制在右栏内，观感上同样是「右栏换了一屏内容」，
  而所有回调路径一个字都不用改。差异只剩「左上角是取消按钮而不是返回箭头」——
  这些页面本来就有取消按钮，形态是自洽的。
  代价：这批页面不进右栏那条栈，所以不参与去重（android 那边它们本来也标着「不去重」）。

- **工作台在单栏形态下多了一层迎宾面板**。iPad 收窄（Slide Over、1/3 分屏）时右栏没了，
  网页由迎宾面板压栈打开，左上角会多一个退回迎宾面板的返回箭头；
  flutter 那边窄栏是直接整页网页。取这个折中是因为 tab 的根控制器在 `viewDidLoad` 里一次建成，
  要跟着断点来回换根，得把网页在左右两条栈之间搬来搬去，风险远大于多一层返回箭头。
  iPhone 不受影响（迎宾面板只在 iPad 上建）。

两端之间本身就有分歧、需要选边的：

- **栈底欢迎页之上要不要给返回键**。android 给（`PaneStackFragment`：「与微信 Pad 一致 ——
  从左栏点开任何一项后，右栏左上角都能退回欢迎页」）；flutter 不给
  （`PadHome`：「下面只有占位页，返回过去是一片空白，不该给返回键」）。
  **取 android**：微信 iPad 确实能退回欢迎页，且这是用户明确要的。

有意保留的差异：

- **左栏那条搜索框留在原处，但只当按钮用**。android/flutter 的搜索入口本来就是一颗按钮，
  iOS 的入口是 `UISearchController` 挂在左栏列表 `navigationItem` 上的一条真输入框，
  换成按钮等于改掉 iPhone 的形态。取的折中是：框留在原位不动，双栏下把它的
  `searchTextField` 关掉（点它不取焦点）再挂一个点击手势，行为上就是一颗按钮；
  输入框在右栏那张搜索页顶上，与两端一致。分栏形态会变，所以「能不能取焦点」
  在每次 `viewWillLayoutSubviews` 里同步一次；单栏（Slide Over）下自动恢复成原来那条真输入框。
  两张表共用同一套 dataSource，靠 `tableView` 参数分辨（各列表控制器里的 `isSearchTableView:`）。
  通讯录为此拆出了第二份分组数据（`padSearchSectionDic` / `padSearchKeys`）——
  它单栏下是「把左栏列表整个换成搜索结果」，双栏下左右两张表得各排各的。
- ~~**搜索页的「取消」旁边还有一个返回键**~~。**此条已撤销**（缺陷 #18）。原先的理由是
  「iOS 右栏是一条 `UINavigationController`，返回键去不掉」—— 这是错的，
  `navigationItem.hidesBackButton` 就能去掉。现在与 android 的
  `providesOwnToolbar()==true` 完全对齐：搜索框本身占 `titleView`，左侧不给返回箭头，
  「取消」挂在导航条右侧，是唯一出口。顺带省掉了搜索框自成一条时占的那 58pt。
- **只有会话列表有选中态**，通讯录 / 发现 / 我 三个 tab 的左栏不保留高亮 —— 与
  android / flutter 一致（两端都只给会话列表做了选中态）。
  曾按「右栏一直显示当前高亮项」的想法给每个 tab 各记一份高亮（按行号记），
  实测后按用户要求撤销，回到与参考实现一致的形态。
- **不做 `NavigationRail`**。flutter 在 ≥900 时把底部 tab 换成侧边 rail，iOS 端 UITabBar
  没有等价形态，且微信 iPad 也是底部栏，保持底部栏。
- **不做左栏拖拽**。android/flutter 两端也都没做（PC 才有）。

尚未决定的：

- 断点用显式 720pt 还是 UIKit 的 regular/compact。后者与系统行为一致、代码更少，
  但与另两端取值可能不同，需在 iPad mini 竖屏（744pt）与 1/2 分屏（507pt）两个点上实测比对。
  显式断点要接管 `horizontalSizeClass`：iOS 17+ 有 `traitOverrides`，
  iOS 12–16 得套一层容器用 `setOverrideTraitCollection:forChildViewController:`，成本不低。

- 断点这一条与下面那条原本被记作「同一个决定」，现在**只剩断点还没定**。
