# 读取与周期重装

每种 `sourceType` 从数据库读取 `tl_<sourceType>`（剩余总机会）和 `ll_<sourceType>`（剩余 Lucky 机会）。如果 `totalLeftSpreadCount == 0`，使用 `lucky_chance[1]` 作为总机会、`lucky_chance[2]` 作为 Lucky 配额，并先保存 Lucky 配额。

**源码**：`Try2ProduceLuckyItem`、`_GetTotalLeftSpreadCount`、`_GetLuckyLeftSpreadCount`。**配置**：`LuckyProduceConfig.lucky_chance[1]`、`[2]`。周期何时被清空和重新进入需运行时确认。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：读取食品袋自己的周期计数。本例周期刚装满，不需要重新装填。

### 代入本页的值

`sourceItemType="105"`；`tl_105=60`、`ll_105=1`。若 `tl_105=0`，本地配置 `lucky_chance={60,1}` 重装为 60/1。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
