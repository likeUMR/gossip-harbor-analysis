# 能量消耗、资源通知与免费 Lucky 进度

## 1. 次数先处理，再扣实际能量

手动点击在GenerateItemCode返回后才SpreadCostEnergy，然后记录Lucky的增益历史，最后落子。普通产出在GenerateItemCode内已改次数、更新计时、保存；Lucky直接返回没有普通扣次。不是先扣Energy再把次数写成1。

SpreadCostEnergy把棋盘能量类型映射为属性类型；costEnergy真时，用最终指数的GetBoostCostNum作为请求数量，调用PropertyDataManager Consume，并把请求数写测试记录。此函数不检查Consume返回值，外层也不因失败自动撤回之前的状态。

## 2. 属性消耗的实际分流

Consume默认num为1，负数报错返回false，0返回true且不通知；测试无限属性开关命中也直接返回true。活动专用属性及礼物有各自handler。能量属性则调用EnergyModel SubtractEnergy，只有成功才派发PropertyConsumed并记录用户资源、SDK统计。

SubtractEnergy先拒绝负数；无限能量直接返回true与实际消耗0。否则余额不足返回false；足够时写余额减请求数，到0记录耗尽统计，根据上传开关检查能量上传。若本次从不低于上限降到低于上限，开始恢复计时；最后返回实际消耗数。

## 3. 请求量和实际量不能混用

DispatchConsumeEvent消息包含property（类型、实际数量）和ext；能量分支ext.origin为请求数。先发全局PropertyConsumed，再LogUseItem。无限能量可能请求1却实际扣0；免费Lucky监听资源消耗时，必须按其读取的消息字段累计，不能用本次UI能量档代替所有入口的真实消耗。

本次GenerateItemCode已完成，所以此次消耗推动的免费资格通常供后续点击使用；其它消耗入口也可能推进免费计数。具体服务器日重置、阈值生成与消费见[免费Lucky](../../lucky/free/generate.md)。

**证据**：ItemSpread _TrySpread、SpreadCostEnergy；PropertyDataManager Consume、DispatchConsumeEvent；EnergyModel SubtractEnergy。上传handler、全局PropertyConsumed的其它监听还需按实际配置和订阅继续核对，不能推定为固定成功上传。

---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：A普通产出先扣母体次数再扣能量；B Lucky不扣普通次数，但仍按本例条件扣能量。新的消耗通知推进后续免费Lucky进度。

### 代入本页的值

初始能量10、母体次数80；A示例次数循环返回1，GenerateItemCode先把次数改79并保存；最终指数0请求1能量，非无限、余额足够时Energy变9，PropertyConsumed数量1、ext.origin=1，再落201。B直接产204，次数仍80，能量同样10→9。无限能量对照请求仍1但真实消耗0、消息数量0；不能当成免费Lucky已累计1。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Sta

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- source-links:start -->

## 对应源码

[PropertyDataManager.lua](../../../../assets/recovered-source/PropertyDataManager.lua) · [EnergyModel.lua](../../../../assets/recovered-source/EnergyModel.lua) · [ItemSpread.lua](../../../../assets/recovered-source/ItemSpread.lua)

<!-- source-links:end -->
