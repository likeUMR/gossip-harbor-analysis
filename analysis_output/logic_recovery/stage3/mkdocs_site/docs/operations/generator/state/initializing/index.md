# Initializing：初始化中

母体拥有 `Spread_InitDuration` 且初始化计时未完成时处于此状态。点击不会产出棋子，也不会扣能量或次数，返回非一次性错误 `Recharging`。

**字段/配表**：`m_initDuration`、`ItemModelConfig.Spread_InitDuration`、服务器时间起点。**源码**：`CheckSpreadState`、`UpdatePerSecond`。计时完成后转为 Opened；实际离线补时需运行时确认。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例已可产出且次数充足，既不在初始化，也没有耗尽。

### 代入本页的值

`m_state=3`；`m_itemRestNumber=80`。`state==Initializing or rest==0` 为 false。反事实：把次数改为 0 时，即使仍是 Opened，也会阻止产出。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
