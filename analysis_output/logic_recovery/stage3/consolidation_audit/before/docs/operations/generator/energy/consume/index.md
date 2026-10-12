# 余额不足与实际扣除

余额不足返回 `LackEnergy`，停止产出，不改母体次数。余额足够时调用 `PropertyDataManager:Consume` 扣除，并记录 `EBIType.SpreadItem`。

**源码**：`CheckEnergy`、`SpreadCostEnergy`。**证据**：失败和扣除顺序 `source-confirmed`；UI 提示和 BI 网络上报时机 `runtime-pending`。

扣能量时触发的资源通知属于这一步，见资源事件与监听；落子通知稍后才发生，见落子与棋盘事件。


---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：余额 10 足够一次点击。母体先算出产物，随后扣到 9。

### 代入本页的值

余额检查：`10>=1`。`SpreadCostEnergy(0,true)` 调用 `Consume`；`m_testLastCostEnergyCount=1`。对照余额 0：在生成产物前返回 false。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
