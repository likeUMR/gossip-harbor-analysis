# Smart Produce 权重修正

`_UseSmartProduce()` 为真时，先根据订单缺口和能量增益等级调用 `_UpdateSpreadConfigSmartWeight`，再使用 `SpreadSmartWeightKey` 进行累计权重选择；原始配置权重与本次临时修正权重需分开保存。

**字段**：`m_smartProduceRatio`、Smart 权重字段、订单缺口映射。**源码**：`_UseSmartProduce`、`_UpdateSpreadConfigSmartWeight`。服务端 Smart Produce 开关和值 `runtime-pending`。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-204.png" alt="Lucky 产物 204" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例关闭 Smart 修正，直接用原始 Lucky 权重。

### 代入本页的值

演示 `m_smartProduceRatio=nil`；`_UseSmartProduce()` 为 false；使用 `Weight`，不读 `Weight_Smart`。启用时还需订单缺口和修正倍率，不能由本例推断实际账号值。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
