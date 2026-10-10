# 状态检查

状态检查是 `OnTap → _TrySpread` 的第一道闸门。代码按固定顺序读取同一个 `ItemSpread` 实例：先处理明确的关闭/开启状态，再处理初始化或次数耗尽，只有全部通过才允许寻找落点。

## 实际执行顺序

1. `Closed`：派发 `SpreadFailed(ItemClosed)`，立即结束。
2. `Opening`：派发 `SpreadFailed(ItemOpening)`，立即结束。
3. `Initializing`，或 `m_itemRestNumber == 0`：可恢复母体派发 `SpreadFailed(ItemRecharging)`；一次性母体在耗尽时静默返回 false，因为它会在成功落子后销毁。
4. 其它情况视为 `Opened`，进入空位检查。

这里的“状态”不是独立布尔值：`m_state` 与 `m_itemRestNumber`、`m_startTimer` 共同决定点击结果。`UpdatePerSecond` 依据服务器时间把 Initializing/Opening 推进到 Opened，或把可恢复母体的次数补回；它不会改变本次点击的检查顺序。

左侧每个状态页继续说明进入条件、计时字段、失败事件和边界行为；底层页给出对应源码分支。

**源码入口**：`ItemSpread:CheckSpreadState`、`ItemSpread:UpdatePerSecond`、`ItemSpread:_UpdateRecoveryState`。**证据**：分支顺序 `source-confirmed`；实际账号计时、活动覆盖和前后台回放 `runtime-pending`。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：按源码顺序先排除关闭、开启中，再排除初始化或次数为零。本例均通过，进入空位检查。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
