# Work Rest Timer

一个用于记录当前任务工作时间、提醒起身休息的 Mac 菜单栏小工具。

最新视觉探索入口：[平面表盘 HTML/SVG 预览](prototype/flat-dial/README.md)。用于快速调整轻薄圆形层次、长短直线拨杆和较大的中央玻璃按钮，独立于原生样机。最新视觉方向以该预览说明和用户反馈为准，下面的原生预览及早期设计文档尚未同步这一轮改版。

当前阶段：产品与交互设计 + 原生 SwiftUI 菜单栏预览。仅在专用临时目录运行，尚未接入通知中心与持久记录。

## 保存的设计版本

`preview-2026-09-07` 保存当前平面表盘探索：细长短拨杆及末端圆球、中央拖动读数、多圈叠加底色与扩散阴影。此版本用于后续比较与借鉴；配色和其他设计仍会继续迭代。

当前 HTML 预览入口：

```sh
python3 -m http.server 8765 --bind 127.0.0.1 --directory prototype/flat-dial
```

在浏览器打开 <http://127.0.0.1:8765>。逻辑与几何检查：`node prototype/flat-dial/check.mjs`。

这是 Build in Public 的早期设计快照，尚非可日常使用的计时产品。HTML 预览与较早的 SwiftUI 样机独立；根目录产品／设计／检查文档保留探索历史，最新行为以 [平面表盘说明](prototype/flat-dial/README.md) 为准。参考截图与私人本地文件不随仓库发布。

## 项目文件

- [PRODUCT.md](PRODUCT.md)：目标、范围、已确认要求、设计假设、计时状态和记录规则。
- [DESIGN.md](DESIGN.md)：布局、双拨杆几何、联动、动效、颜色和验收标准。
- [prototype/native/](prototype/native/)：隔离的 SwiftUI 首页样机；数据临时保存在内存中。
- [REVIEW.md](REVIEW.md)：本轮实际检查结果与仍未验证的能力。

## 查看预览

在项目目录运行：

```sh
zsh prototype/native/build-preview.sh
open '/private/tmp/work-rest-timer-native-preview/Work Rest Timer Preview.app'
```

需要 macOS 26 和可用的 Swift／macOS SDK，不需要第三方依赖。2026-09-07 已确认开发机为 macOS 26.5.1、Swift 6.3.3、SDK 26.5。构建产物与编译缓存都位于专用临时目录；不会安装到 Applications。

首先在菜单栏弹窗中拖动两个拨杆，再点击中央播放。独立的“交互预览”窗口提供相同界面的镜像，以及加速时间、快速接近阶段结束和试听声音的控制。两处共用一个计时状态。预览不应当作日常学习时长记录器使用，退出会清除数据；通过控制窗口“退出预览”或 Command-Q 结束进程。

运行计时规则检查：

```sh
zsh prototype/native/check.sh
```

## 现有方案与实现选择

调研日期：2026-09-07。此次只读公开文档，没有下载第三方应用，也没有复制它们的代码或声音。

| 来源 | 可借鉴之处 | 对此项目的结论 |
| --- | --- | --- |
| [TomatoBar](https://github.com/ivoronin/TomatoBar) | 原生菜单栏计时、可调工作／休息时间、可选声音、可操作通知、状态事件日志 | 说明基础功能已有成熟范例。已查文档没有体现本项目要求的双拨杆联动交互；先验证这一设计 |
| [Stretchly](https://github.com/hovancik/stretchly) | 休息提醒、暂停、空闲与勿扰模式处理 | 空闲检测会改变计时语义，不能直接把“无输入”当成“没学习”；本项目先手动暂停，原生版另行验证锁屏／休眠 |
| [pomodoro-menubar](https://github.com/onurdilmen/pomodoro-menubar) | Swift 菜单栏与 WebKit 界面的组合 | 可作为实现路径比较；依据用户最新要求，本项目直接采用 SwiftUI |
| [Apple MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra) | 在系统菜单栏提供常用入口，可使用 window 风格 | 正式产品可采用此入口；预览为支持程序化展开和独立非激活提醒，外壳使用 AppKit，内容使用 SwiftUI |
| [Apple 原生新设计](https://developer.apple.com/videos/play/wwdc2025/323/) | macOS 26 的 Liquid Glass 与原生控件外观 | 用已安装 SDK 支持的材质和控件，避免为了尚未安装的系统接口升级开发环境 |
| [Apple 通知授权](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications) | 系统通知需要处理授权状态 | 产品内始终提醒是一条行为规则，无法保证越过系统权限或专注模式；菜单栏等待标记作为持续反馈 |

本轮采用无第三方依赖的原生 SwiftUI 样机，验证真实菜单栏弹窗布局、拖动手感和动效。安装包、数据库和完整统计页面留到方向确认后；长期后台与数据可靠性仍需后续单独验收。

## 下一步

先用预览确认拨杆错层、消耗方向、休息变色和 Reset 手感。以下方案目前保留为假设：自动开始默认开启、顺时针增加时长、Reset 保留时长设定。

确认首页方向后，下一阶段是将预览收敛为可日常使用的本地记录应用，加入持久保存、通知授权与锁屏／休眠／跨日计时测试。历史统计页面继续单独讨论；手机仍不在范围内。
