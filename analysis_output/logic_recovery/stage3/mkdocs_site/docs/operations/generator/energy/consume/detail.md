# 能量余额比较与扣除

`CheckEnergy` 先用 `GetCostEnergyNum` 返回的最大档调用 `HasEnoughEnergy(boardModel:GetCostEnergyType(), maxCostCount)`；不足时设置 `popupBundleEnergyWindowForLackingEnergy=true`，发送 `BoardEventType.LackEnergy`，返回 false，次数和权重池都不变。通过时先把标记清 false，随后 `_TrySpread` 生成最终代码；`SpreadCostEnergy` 将棋盘能量类型映射为属性类型，按 `EnergyBoostModel.GetBoostCostNum(energyBoostRatio)` 调用 `PropertyDataManager:Consume(..., EBIType.SpreadItem, sourceCode)`，并记录实际扣除数。

<!-- reconciliation-failure:start -->
## 缺能量后先显示什么窗口

主棋盘局部 LackEnergy 由 `MainBoardView:_OnLackEnergy` 转交 `EnergyModel:OnLackEnergy(EnergyType.Main)`。它和状态失败的 SpreadFailed 是不同通知链。

1. 主能量且没有强制教程进行时，先读取内购资格并取得能量礼包模型。内购开启且模型存在，才尝试触发能量礼包。
2. 尝试之后，如果当前礼包配置存在，且不是“先显示能量窗口”的弹出类型，则直接打开 BundleEnergyWindow 并返回。
3. 其余情况调用 `ShopModel:OpenEnergyWindow(type,true)`。商城若已开启链式能量窗口，就选择当前链式窗口，否则选择 BuyEnergyWindow；此调用未传等待空闲参数，因此立即请求打开。

尝试触发礼包不是纯查询：`Try2TriggerEnergyBundle` 通过资格后，可能写入礼包组编号、Open状态和组结束时间；选择当前礼包，清旧礼包数据，保存剩余购买次数1、刷新时间INVALID_TIME、礼包到期、商品和组编号，增加触发次数，派发 BundleDataRefreshed。`IsBundleWindowPopupAfterEnergyWindow` 在没有组时返回false；有组时严格判断 PopType==1。具体触发资格、选组和界面初始化由各自模型继续处理，不能把“缺能量”直接等同于必定出现某个固定礼包。

本次母体点击仍不会生成棋子或扣母体次数；玩家随后确认购买属于新的交互，不能把购买奖励自动算进本次点击。
<!-- reconciliation-failure:end -->

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

**本页发生什么**：本页具体说明余额足够时扣除能量并继续落子，余额不足时在产出前失败。

### 代入本页的值

假设 `energy=3`、`cost=1`。先判断 `3>=1`，条件成立后调用 `Consume(1)`，余额变为 2，并写入 `m_testLastCostEnergyCount=1`；若输入改为 `energy=0`，`0>=1` 为假，直接返回 `false`，不生成物品。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Sta

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- 母体配置与包内变体：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。
- 能量增益适用母体：EnergyBoostModel:OnSyncDataFinished 直接 require EnergyBoostItemConfig，建立 m_mapTargetItemType；CanEnergyBoost 读取此适用集合。


<!-- generator-configs:end -->

<!-- source-links:start -->

## 对应源码

[PropertyDataManager.lua](../../../../assets/recovered-source/PropertyDataManager.lua) · [EnergyModel.lua](../../../../assets/recovered-source/EnergyModel.lua) · [ItemSpread.lua](../../../../assets/recovered-source/ItemSpread.lua)

<!-- source-links:end -->
