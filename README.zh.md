# Thymer

<img src="docs/brand/app-icon/thymer-app-icon-v1.png" alt="Thymer app icon" width="128" />

[English](README.md) · [中文](README.zh.md)

> “Know Thy Time” — 彼得·德鲁克，《卓有成效的管理者》（[英文节选](https://www.christianitytoday.com/pastors/content/knowthytime/)）

**Thymer** 读起来像 *timer*，名字里的 *thy* 取自 “Know Thy Time”：先了解时间去了哪里，再决定怎样使用它。

一个待在 **Mac 菜单栏**里的小计时器，用来工作、休息，也记录一天的时间。设好周期，写下正在做的事，让它帮你计时，不必手写起止时间再逐项相加。

有想法或建议？欢迎[提 issue](https://github.com/simonsysun/thymer/issues)，或在已有讨论下留言。

## 它能做什么

- **拖动圆盘设置时间。** 调整工作与休息时长，也可以只计休息时间。
- **随时掌握节奏。** 开始、暂停、继续或重新开始，每次启动和恢复都有简短提示。
- **看看今天的时间去了哪里。** 给任务起名，在时间线上查看工作与休息记录。
- **数据留在本机。** 无需账号，没有服务器或使用追踪。

## 试一试

Thymer 目前是持续测试中的 macOS MVP，**暂未提供下载版 release**。

在 **macOS 26+** 上，安装 Xcode 26 命令行工具和 Python 3 后构建：

```sh
./scripts/build.sh
open 'dist/Thymer.app'
```

首个下载版将面向 Apple Silicon、macOS 26+。构建使用临时签名，不做 Apple 公证；首次打开可能需要在“系统设置 → 隐私与安全性”中选择“仍要打开”。安装、操作与当前限制见[构建与记录指南](NATIVE.md)。

## 接下来

- **手机端：** 离开书桌，也能随手记录时间。
- **AI Agent：** 用自然语言设置计时、调整周期、回顾时间分配。
- **更多平台：** 在其他操作系统上延续同样简单的使用方式。

这些是未来方向，当前版本尚不支持；计划会随着反馈继续调整。

## 开源协议

[MIT](LICENSE)。欢迎使用、修改，也欢迎分享你做出的东西。
