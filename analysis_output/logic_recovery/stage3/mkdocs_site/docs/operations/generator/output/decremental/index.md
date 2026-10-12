# Decremental

Decremental 把配置中的每个 `Weight` 当作可消耗的剩余份数。每次用当前权重做一次加权整数选择，选中项减 1，减到 0 就从列表移除并保存；因此候选池随点击变化，等价于按权重展开后逐份无放回抽取。它与 Lucky 机会池的计数状态分开维护。

**配表**：`Spread_WeightType=2`、候选代码与 `Weight`，当前 54 行。**源码**：`ItemSpread:_GenerateItemCode`、`Table.ListWeightSelectOne`、`GetAutoSpreadDecrementalRemainTypes`。
---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：假设本次母体使用 Decremental 类型，玩家每次抽中某候选后，该候选后续出现机会会降低，降到零后从池中移除；普通 Fixed 母体不会发生这一变化。

### 代入本页的值

假设 `m_weightType=2 (Decremental)`，候选 201 初始权重为 5。第一次抽中 201 后权重降为 4，后续再次抽中继续递减；降到 0 时 201 从候选池移除，玩家之后不会再得到它。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Sta

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>
