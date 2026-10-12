# 能量余额比较与扣除

`CheckEnergy` 先用 `GetCostEnergyNum` 返回的最大档调用 `HasEnoughEnergy(boardModel:GetCostEnergyType(), maxCostCount)`；不足时设置 `popupBundleEnergyWindowForLackingEnergy=true`，发送 `BoardEventType.LackEnergy`，返回 false，次数和权重池都不变。通过时先把标记清 false，随后 `_TrySpread` 生成最终代码；`SpreadCostEnergy` 将棋盘能量类型映射为属性类型，按 `EnergyBoostModel.GetBoostCostNum(energyBoostRatio)` 调用 `PropertyDataManager:Consume(..., EBIType.SpreadItem, sourceCode)`，并记录实际扣除数。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。

<!-- execution-inline:start -->
## 能量消耗、资源通知与免费 Lucky 进度

## 1. 次数先处理，再扣实际能量

手动点击在GenerateItemCode返回后才SpreadCostEnergy，然后记录Lucky的增益历史，最后落子。普通产出在GenerateItemCode内已改次数、更新计时、保存；Lucky直接返回没有普通扣次。不是先扣Energy再把次数写成1。

SpreadCostEnergy把棋盘能量类型映射为属性类型；costEnergy真时，用最终指数的GetBoostCostNum作为请求数量，调用PropertyDataManager Consume，并把请求数写测试记录。此函数不检查Consume返回值，外层也不因失败自动撤回之前的状态。

## 2. 属性消耗的实际分流

Consume默认num为1，负数报错返回false，0返回true且不通知；测试无限属性开关命中也直接返回true。活动专用属性及礼物有各自handler。能量属性则调用EnergyModel SubtractEnergy，只有成功才派发PropertyConsumed并记录用户资源、SDK统计。

SubtractEnergy先拒绝负数；无限能量直接返回true与实际消耗0。否则余额不足返回false；足够时写余额减请求数，到0记录耗尽统计，根据上传开关检查能量上传。若本次从不低于上限降到低于上限，开始恢复计时；最后返回实际消耗数。

## 3. 请求量和实际量不能混用

DispatchConsumeEvent消息包含property（类型、实际数量）和ext；能量分支ext.origin为请求数。先发全局PropertyConsumed，再LogUseItem。无限能量可能请求1却实际扣0；免费Lucky监听资源消耗时，必须按其读取的消息字段累计，不能用本次UI能量档代替所有入口的真实消耗。

本次GenerateItemCode已完成，所以此次消耗推动的免费资格通常供后续点击使用；其它消耗入口也可能推进免费计数。具体服务器日重置、阈值生成与消费见免费Lucky。

**证据**：ItemSpread _TrySpread、SpreadCostEnergy；PropertyDataManager Consume、DispatchConsumeEvent；EnergyModel SubtractEnergy。上传handler、全局PropertyConsumed的其它监听还需按实际配置和订阅继续核对，不能推定为固定成功上传。

<!-- execution-inline:end -->

---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页是该阶段的第四层证据节点；沿用食品袋 105 的同一组案例输入，只展示当前节点涉及的算法和状态变化。

### 代入本页的值

本页没有新增运行时输入；具体字段以本页正文的源码和配表为准。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- source-links:start -->

## 对应源码

[PropertyDataManager.lua](../../../../assets/recovered-source/PropertyDataManager.lua) · [EnergyModel.lua](../../../../assets/recovered-source/EnergyModel.lua) · [ItemSpread.lua](../../../../assets/recovered-source/ItemSpread.lua)

<!-- source-links:end -->

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [母体配置与包内变体](../../state/model/detail.md#configuration-item-model)：配表文件/字段：`ItemModelConfig.json；ItemModelConfig_shell/carditem2/extracust`；ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。
- [能量增益适用母体](../boost/detail.md#configuration-energy-boost)：配表文件/字段：`EnergyBoostItemConfig；服务器 EnergyBoostEight`；EnergyBoostModel:OnSyncDataFinished 直接 require EnergyBoostItemConfig，建立 m_mapTargetItemType；CanEnergyBoost 读取此适用集合。


<!-- generator-configs:end -->

