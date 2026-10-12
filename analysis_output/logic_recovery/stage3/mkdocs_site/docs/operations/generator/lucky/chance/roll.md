# 随机比较

使用 `MathUtil.Random(totalLeftSpreadCount)`，等价于 `Random(1,total)`，两端包含。若 `luckyLeftSpreadCount >= index`，本次获得普通 Lucky；测试模式的强制 Lucky 开关可以额外改变结果。

**源码**：`Try2ProduceLuckyItem`。**随机语义**：从当前有限机会数中抽取位置，而不是每次调用固定概率。测试开关 `TestLuckyProduce` 的正式账号可用性为 `runtime-pending`。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：A 是普通产出；B 获得 Lucky 资格。

### 代入本页的值

A 演示整数 `index=60`，比较 `1>=60` 为 false；B 改为 `index=1`，`1>=1` 为 true。随机区间 `[1,60]`；演示关闭测试强制开关。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [Lucky 包内配置及活动变体](load.md#configuration-lucky)：配表文件/字段：`LuckyProduceConfig、LuckyProduceConfig_shell、LuckyProduceConfig_triple、LuckyProduceConfig_tripleshell、GeneratorBoostLuckyProduceConfig、GeneratorBoostLuckyProduceConfig_shell`；LuckyProduceModel:_LoadFileConfig → _GetLevelFitConfig → Try2ProduceLuckyItem；按 generator、等级区间选择记录，再用 lucky_chance 重装机会池。


<!-- generator-configs:end -->

