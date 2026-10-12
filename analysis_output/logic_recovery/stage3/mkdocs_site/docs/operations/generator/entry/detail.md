# OnTap、测试十连和通知判定

`OnTap` 每次先把 `spreadCount` 设为 1；测试模式且 `PlayerPrefs.TestSuperTap==1` 时改为 10，但 Tutorial 棋盘再次限制为 1。循环逐次调用 `_TrySpread`，任何 false 结果立即终止，因此测试十连不会绕过状态、空位或能量门禁。循环后，非一次性且存在冷却计时的母体才计算 `GetTimerDuration()+GetStartTimer()-serverTime`；剩余时间至少 1200 秒并且 `m_itemRestNumber==0` 时调用 `TryOpenIOSNotificationWindow(ItemCoolDown)`。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页把一次点击已通过状态检查后的循环行为具体化：成功的一轮产生 1 个物品；下一轮重新检查能量、空位和次数，失败就停止。

### 代入本页的值

以 `loopCount=1`、`_TrySpread` 返回 `true` 为例：入口只调用一次产出链，成功后不再重复扣能量。若测试循环为 10，循环变量在第 1 轮成功后进入第 2 轮；此时假设余额已为 0，`CheckEnergy` 返回 `false`，循环立即停止，最终仍只产出 1 件。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
