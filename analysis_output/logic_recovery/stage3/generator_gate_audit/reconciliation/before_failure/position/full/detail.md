# 棋盘满失败的具体副作用

手动路径的落点函数返回 nil 后立即调用 `_NotifySpreadFailed(BoardFull)`，不调用 `GenerateItemCode`、`SpreadCostEnergy`、`SpreadItem` 或 `CosetRestNumber`。通知函数发送棋盘事件 `BoardEventType.SpreadFailed`、全局事件 `EEventType.SpreadFailed` 和 `VibrationHeavy`。自动路径棋盘满不发送这个主动点击失败链，而是让 `_TryAutoSpread` 返回 false；只有缓存条件全部满足时才转入 `CacheItemFromSpread`。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页具体说明有空位时产物成功落盘、无空位时点击提前失败，资源保持不变。

### 代入本页的值

假设 `position=nil`、可用空位集合为空。`CheckSpreadPosAndAuto` 返回 false，发送 `BoardFull`，能量和次数仍为 10 与 80；若集合含 P，则返回 true 并继续产出。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>
