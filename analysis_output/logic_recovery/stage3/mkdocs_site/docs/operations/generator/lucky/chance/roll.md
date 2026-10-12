# 随机比较

使用 `MathUtil.Random(totalLeftSpreadCount)`，等价于 `Random(1,total)`，两端包含。若 `luckyLeftSpreadCount >= index`，本次获得普通 Lucky；测试模式的强制 Lucky 开关可以额外改变结果。

**源码**：`Try2ProduceLuckyItem`。**随机语义**：从当前有限机会数中抽取位置，而不是每次调用固定概率。测试开关 `TestLuckyProduce` 的正式账号可用性为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例把一次点击的机会判断视为“从当前机会池抽取一次”。A 抽到普通结果，继续普通产出；B 抽到 Lucky 结果，改走 Lucky 物品池并在结果中得到额外奖励。

### 代入本页的值

假设当前总机会 `left=60`，本次随机结果 `index=1`。比较 `1>=1` 为真，因此本次点击获得 Lucky 资格，随后进入 Lucky 物品池并消耗一次普通机会和一次 Lucky 配额。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- Lucky 包内配置及活动变体：LuckyProduceModel:_LoadFileConfig → _GetLevelFitConfig → Try2ProduceLuckyItem；按 generator、等级区间选择记录，再用 lucky_chance 重装机会池。


<!-- generator-configs:end -->
