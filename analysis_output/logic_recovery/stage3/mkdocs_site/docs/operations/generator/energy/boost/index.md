# 基础消耗与增益

`GetCostEnergyNum(itemType)` 返回基础 `nCostNum` 和最大 `nEnergyBoostRatio`；最终扣除由 `EnergyBoostModel.GetBoostCostNum(energyBoostRatio)` 计算。

**配置/状态**：EnergyBoost 字段、母体类型、当前增益索引。**源码**：`CheckEnergy`、`SpreadCostEnergy`。不同母体的实际增益覆盖 `runtime-pending`。

最终等级在产物计算中确定，见链升级与 FishNet 算法，不能把预检查的最大消耗视为最终扣费。
---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：假设 GeneratorBoost 已生效，系统按增益规则调整本次能量或产出结算，玩家看到增强后的结果；没有增益时才使用基础值。

### 代入本页的值

演示输入 `maxEnergyBoostRatio=0`；基础扣能量 1。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>
