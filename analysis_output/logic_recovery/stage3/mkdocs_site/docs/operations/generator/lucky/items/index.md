# Lucky 物品权重

只有在 Lucky 资格已经确定后才选择物品。该机制不再决定“是否 Lucky”，而是从 `lucky_items` 中决定产出内容，随后判断是否属于 `super_items` 并设置产出类型。

- [候选与累计权重选择](select.md)
- [Smart Produce 权重修正](smart.md)
- [Super Lucky：奖励分类与表现](type.md)

<!-- lucky-classification-explanation:start -->

## 物品抽取与 Super 分类的顺序

1. 先按普通权重或 Smart Produce 修正后的权重，从同一个 `lucky_items` 池选择物品。
2. 若连续 Lucky 已指定 Double/Triple 类型，保留该类型；否则检查选中物品是否属于 `super_items`，并结合免费资格选择 Lucky、SuperLucky、FreeLucky 或 FreeSuperLucky。
3. 类型和物品一同返回。Super 名称影响后续表现，不会要求另抽一个物品或另扣一份机会。

因此 `super_items` 是对物品的分类名单，不是另一个奖池。细节见[Super Lucky：奖励分类与表现](type.md)。

<!-- lucky-classification-explanation:end -->

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-204.png" alt="Lucky 产物 204" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：A 没有 Lucky 资格，所以不进入 Lucky 物品池；B 已经获得 Lucky 资格，系统从 Lucky 候选中抽取并放置 1 个 204。玩家看到的是特殊奖励物品，而普通物品池不会参与 B 的这次选择。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
