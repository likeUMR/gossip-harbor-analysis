# 候选与累计权重选择

调用 `Table.ListWeightSelectOne(config.lucky_items)`，按累计权重选择一个对象；该调用不删除候选、不减少原始 `Weight`，因此物品池是有放回语义。

**配置**：`LuckyProduceConfig.lucky_items` 的 `Item` 和 `Weight`。**源码**：`_GetGenerateLuckyItem`、`Table.ListWeightSelectOne`。连续点击出现同一物品是允许结果。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-204.png" alt="Lucky 产物 204" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例获得 Lucky 资格后，从完整候选池抽到 204 并放入棋盘；抽完后候选仍可在下一次点击继续使用，因此玩家可能连续看到同一种 Lucky 物品。

### 代入本页的值

池为 `204:63,205:10,303:15,304:10,305:2`，总权重 100。抽样点 50 落在 1..63，选中 204；抽样点 95 落在 89..98，选中 304。每次抽样后权重仍是原值，不做无放回删除。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [Lucky 包内配置及活动变体](../chance/load.md#configuration-lucky)：LuckyProduceModel:_LoadFileConfig → _GetLevelFitConfig → Try2ProduceLuckyItem；按 generator、等级区间选择记录，再用 lucky_chance 重装机会池。


<!-- generator-configs:end -->
