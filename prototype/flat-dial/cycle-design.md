# Cycle 表盘：本轮设计依据

采用直接修改现有组件的路径。主要参考是用户已认可的当前表盘及本轮草图式描述；保留深浅色表面、固定光照渐变、双半径、细杆圆球、中央播放、克制的拖动反馈。没有可调用的 Refero MCP，本轮使用其随附 typography 指南补充信息层级，不另换视觉方向。

| 决定 | 来源 | 适用范围 |
|---|---|---|
| 外杆代表整轮截止，内杆代表工作截止 | 本轮用户要求 | 几何和操作语义 |
| Work 蓝灰、Rest/Cycle 薄荷绿 | 现有已认可配色 | 颜色保持语义，位置交换 |
| Work / Rest / Cycle 单行、等宽数字、次级标签 | 用户要求 + Refero typography：系统字体、可扫描层级、tabular figures | 表盘下方、任务行上方 |
| 中央同时显示 Work 和 Rest | 最新用户确认 | 固定上下位置和颜色；无障碍标签保留名称 |
| 移动工作保持整轮终点，最小休息一分钟推动终点 | 前轮用户确认规则 | 本轮继续沿用 |

两小时开关继续限制每个阶段，不改为整轮两小时；Cycle 是 Work 与 Rest 之和。

## 当前确认规则：固定 Rest 联动与零时长

- 拖 Work 保持 Rest 时长不变，Cycle 随 Work 同步增减，绿色扇区角度固定。
- 拖 Cycle 先保持 Work 不变；缩到 Rest 为零后，继续向内会推动 Work 缩短，向外则重新增加 Rest。
- Work 与 Rest 均可为零；零阶段自动跳过。两者同时为零允许保留设定，但不启动计时。运行中仍保护已用时间。
- 拖动时中央固定上 Work、下 Rest 双读数，松手恢复倒计时。
- 零休息不画绿色扇区；绿杆仅保留外圈末端短段，与内圈 Work 端点径向分开，不伪造时间夹角。端点优先选择，抓取目标直到释放保持不变。
- 连续角度驱动杆与扇区，模型仍按整分钟记录。

参考：[Apple Gestures](https://developer.apple.com/design/human-interface-guidelines/gestures)、[Apple Motion](https://developer.apple.com/design/human-interface-guidelines/motion)。以上具体规则由用户最新反馈确定。
