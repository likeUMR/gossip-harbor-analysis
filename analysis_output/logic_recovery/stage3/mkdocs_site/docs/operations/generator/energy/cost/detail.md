# 能量需求布尔值的具体来源

`Init` 原样保存 `Spread_CostEnergy` 到 `m_costEnergy`，并不在读入时转成布尔值。`CheckEnergy` 首先调用 `CostEnergy()`：先读教程强制数据，只要结果不是 nil 就直接返回（包括 false）；没有强制值才判断 `m_costEnergy == 1`。因此正常配置数值1表示需能量，数值0、nil或布尔true都不等于数值1，不能把它改写成一般的非零判断。教程 getter 没有强制数据表时返回 nil，有表时返回其 CostEnergy 字段。

随后 `CanSupportBoostDisco()` 取得 Disco 处理器；只有棋盘对象就是 `GM.MainBoardModel` 且处理器支持该母体类型，才把局部 `costEnergy` 覆盖为 false。它在教程强制值之后执行，因此也可覆盖教程要求扣能量的结果。免能量分支直接返回 `(true, 0, false)`，不读取余额、不设置缺能量弹窗标记；此前的状态和落点检查仍已执行。需能量时按最大可用档检查余额：不足先把 `popupBundleEnergyWindowForLackingEnergy` 写为 true，再发送棋盘 LackEnergy 事件并返回 false；充足写为 false，返回 `(true, 最大档指数, costEnergy)`。这里尚未消费能量，最终消费在产物代码确定以后。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页具体说明配置如何决定本次点击是否需要能量，以及免能量活动如何改变玩家看到的资源结果。

### 代入本页的值

假设 `Spread_CostEnergy=1`、Disco 未生效。布尔式为 `costEnergy=(1==1)=true`，因此后续需要检查余额并扣除 1 点；若改为 `Spread_CostEnergy=0`，则结果为 `false`，跳过扣能量但仍继续检查落点。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Sta

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- 母体配置与包内变体：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。
- Generator Boost 母体替换配置：GeneratorBoostActivityModel:GetItemModelConfig → ReloadItemModelConfig；按 Buff 选择 MoreLuckyProduce / ExtraProduce 并替换 ItemDataModel 中的母体配置。


<!-- generator-configs:end -->
