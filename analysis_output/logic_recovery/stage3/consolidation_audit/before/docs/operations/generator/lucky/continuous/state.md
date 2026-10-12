# 连续状态写入

`_TriggerContiLuckyProduce` 写入 `clpit`（目标类型）、`clpmc`（最大次数）、`clpc=0`（当前次数），并把 `clpeet` 设置为服务器时间加 10 秒。

**源码**：`_TriggerContiLuckyProduce`。**状态**：`clpit`、`clpmc`、`clpc`、`clpeet`。期限使用服务器时间，不能用客户端本地时间替代。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例没有设定连续命中。以下只说明一旦二连/三连触发会保存什么。

### 代入本页的值

对照输入：服务器时间 T=1000，触发函数最大次数参数 N；写入 `clpit="105"`、`clpmc=N`、`clpc=0`、`clpeet=1010`。T 是演示输入，N 必须由实际触发调用确定。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [连续 Lucky 服务器字段](trigger.md#configuration-continuous-lucky)：配表文件/字段：`服务器 luckyProduceConfig（energy_cost.range_entry、triple_lucky_chance、double_lucky_chance）`；_CalculateLuckyProduceConfigIndex 按 energy_cost.range_entry 选段；_Try2TriggerContiLuckyProduce 直接读取 triple_lucky_chance / double_lucky_chance。


<!-- generator-configs:end -->

