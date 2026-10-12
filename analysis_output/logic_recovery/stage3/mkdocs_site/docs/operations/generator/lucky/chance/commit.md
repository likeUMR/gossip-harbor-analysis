# 计数扣减与保存

普通 Lucky 命中时，`luckyLeftSpreadCount -= 1` 并保存；只要不是免费 Lucky，`totalLeftSpreadCount -= 1` 并保存。免费 Lucky 不走总机会扣减。

**结论**：下一次抽样使用已经改变的分母和配额，所以不能复刻为独立伯努利概率。**源码**：`Try2ProduceLuckyItem`、`_SetLuckyLeftSpreadCount`、`_SetTotalLeftSpreadCount`。证据 `source-confirmed`。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：A 留住本周期 Lucky 配额；B 用掉它。下一点击概率随剩余计数变化。

### 代入本页的值

A（免费未命中）：`tl_105:60→59`，`ll_105:1→1`，下一次概率 1/59。B：`tl_105:60→59`，`ll_105:1→0`，本周期后续普通机会不会再命中。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [Lucky 包内配置及活动变体](load.md#configuration-lucky)：配表文件/字段：`LuckyProduceConfig、LuckyProduceConfig_shell/triple/tripleshell`；LuckyProduceModel:_LoadFileConfig → _GetLevelFitConfig → Try2ProduceLuckyItem；按 generator、等级区间选择记录，再用 lucky_chance 重装机会池。


<!-- generator-configs:end -->

