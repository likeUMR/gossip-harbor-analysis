# 次数扣除、变换与销毁

`CosetRestNumber` 先增加 `m_spreadCount`。一次性母体默认扣除 `floor(2 ^ energyBoostRatio)`；普通母体调用 `EnergyBoostModel:NextEnergyBoostCostIndex`；OrderItem 使用命中代码权重。

`TryRemoveSelf` 先检查 `m_transformNumber == m_spreadCount` 并 Transform；否则剩余次数为 0 且不可恢复时删除并发送 `CollapseItem`。

**字段/配表**：`m_spreadCount`、`m_transformNumber`、EnergyBoost 索引、TransformNumber。**源码**：`CosetRestNumber`、`TryRemoveSelf`。**证据**：扣除顺序 `source-confirmed`。

普通路径在产物计算期间先扣次数、更新计时并保存状态；落子后才检查变换与销毁。对应通知见落子与棋盘事件和状态持久化。


---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：A 普通点击消耗一个可用次数；食品袋仍留在棋盘。

### 代入本页的值

A 初始 `m_spreadCount=0,m_itemRestNumber=80`，普通基础档扣次后为 1/79。`Spread_TransformNumber` 未配置且母体可恢复，不因这一点击销毁。储备 240 不在这里立即减 1。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
