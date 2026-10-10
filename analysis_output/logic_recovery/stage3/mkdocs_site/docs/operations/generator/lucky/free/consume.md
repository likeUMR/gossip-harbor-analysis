# 阈值检查与消费

`_CanFreeLuckyProduce` 检查队首阈值是否已被当前能量消耗计数达到；命中后 `_PostProcessOnFreeLuckyProduce` 移除队首并保存队列。本次不减少 `tl_<sourceType>`。

**源码**：`_CanFreeLuckyProduce`、`_PostProcessOnFreeLuckyProduce`。**状态**：`elpec`、EnergyCostCount。每日重置和实际能量计数来源 `runtime-pending`。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：A 免费资格也失败，所以普通产出；B 不走该路径。

### 代入本页的值

A 演示 `_CanFreeLuckyProduce()=false`：不调用免费消费后处理。若改为 true，则消费队首，`tl_105` 保持 60，进入 Free Lucky 物品抽取。这是对照分支，非 A 的实际演示路径。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
