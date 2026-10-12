# CD、加速与恢复

CD 使用服务器时间字段 `m_startTimer`。加速费用按剩余时长比例向上取整，最低 1 宝石；恢复分支补回 `m_itemRestNumber` 并减少 `m_storageRestNumber`。

**字段/配表**：`m_startTimer`、`m_itemRecoveryDuration`、`m_storageRecoveryDuration`、`Spread_ItemRecoveryDuration`、`Spread_StorageRecoveryDuration`。**源码**：`UpdatePerSecond`、CD Buff 处理。Buff 叠加顺序和离线补时 `runtime-pending`。

点击结束后的系统通知见入口与通知分支，它不改变冷却计时。


---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：食品袋启动短恢复，补回本次缺少的次数，并从储备里支付。

### 代入本页的值

A 演示 `serverTime=T`、`m_startTimer=nil`：扣次至 79 后 UpdatePerSecond 写 `m_startTimer=T`。配置 105 的物品恢复 30 秒、储备恢复 60 秒；物品恢复时 79→80，储备 240→239。实际 tick 时间需回放。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
