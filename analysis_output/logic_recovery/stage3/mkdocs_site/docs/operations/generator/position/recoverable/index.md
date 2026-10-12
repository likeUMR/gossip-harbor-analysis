# 可恢复母体落点

调用 `FindEmptyPositionInCircleOrder(sourcePosition)`，从母体所在位置向外按圆周顺序寻找空位。它不是全棋盘随机选择，因此同一棋盘状态下通常具有稳定的优先落点。

**源码**：`ItemSpread:CheckSpreadPosAndAuto`。**证据**：圆周扫描顺序 `source-confirmed`；边界棋盘的具体坐标序列需回放。
---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例的可恢复母体按搜索顺序找到第一个空位 P，产物放入 P 后继续流程。搜索不到空位时，玩家只看到棋盘已满反馈，能量、次数和母体状态都保持不变。

### 代入本页的值

演示输入：落点搜索返回 `P`。`CheckSpreadPosAndAuto` 实际调用 `FindEmptyPositionInSpreadOrder`；P 是搜索结果符号，不冒充未核对的坐标或扫描序列。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Sta

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>
