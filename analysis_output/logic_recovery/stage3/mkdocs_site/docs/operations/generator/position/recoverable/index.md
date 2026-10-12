# 可恢复母体落点

调用 `FindEmptyPositionInCircleOrder(sourcePosition)`，从母体所在位置向外按圆周顺序寻找空位。它不是全棋盘随机选择，因此同一棋盘状态下通常具有稳定的优先落点。

**源码**：`ItemSpread:CheckSpreadPosAndAuto`。**证据**：圆周扫描顺序 `source-confirmed`；边界棋盘的具体坐标序列需回放。

---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：食品袋是可恢复母体，演示棋盘已提供有效空格 P。点击入口找到 P 后继续。

### 代入本页的值

演示输入：落点搜索返回 `P`。`CheckSpreadPosAndAuto` 实际调用 `FindEmptyPositionInSpreadOrder`；P 是搜索结果符号，不冒充未核对的坐标或扫描序列。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
