# 普通次数扣除、保存与落子后的收尾

## 1. 本次是否进入扣除

普通GenerateItemCode路径在候选选择、能量链升级、活动改写之后才调用CosetRestNumber。Lucky直接返回和Disco直接代码返回不进入这次扣除；Disco普通改写把costCount设0时仍进入，点击累计仍加1。

## 2. 扣除的优先级

先 `m_spreadCount+=1`。算法显式给costCount（包括0）时，次数减该值并截0，函数立即返回。没有显式值时：OrderItem在原配对列表中查最终代码Weight；其它一次性母体扣 `floor(2^实际能量指数)`；其它可恢复母体调用NextEnergyBoostCostIndex，消费该档循环序列。OrderItem匹配不到代码时costRestNumber仍nil，源码没有另加默认1。

## 3. 何时更新计时与保存

CosetRestNumber本身只改计数，没有UpdatePerSecond、事件或保存。回到GenerateItemCode后依次UpdatePerSecond、发ItemSpreadEventType.StateChanged、SaveItemProperty。它们在实际能量扣除和SpreadItem落子之前发生。不能把这些写成落子成功后的原子事务；发生异常时需要按实际执行点追踪已变状态。

## 4. 落子后先变换，再销毁，再CD Buff

手动路径落子并发VibrationLight之后调用TryRemoveSelf：有TransformNumber且精确等于累计次数时优先Transform并返回false；否则一次性且次数0就RemoveItem并发CollapseItem、返回false。两者都不发生才返回true，外层再TryUseCDBuff。相等不是大于等于；Transform优先于耗尽销毁。自动路径另有自己的收尾，不可套用此手动顺序。

**来源**：ItemSpread GenerateItemCode、CosetRestNumber、_TrySpread、TryRemoveSelf；次数分值、Weight、TransformNumber及EnergyBoost循环来源见下方配表。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：食品袋105普通分支扣次数，Lucky分支不进入普通扣次。状态更新与保存先发生，落子后的变换/销毁再判定。

### 代入本页的值

对照初始次数80、累计0、基础指数0，假设NextEnergyBoostCostIndex(0)返回1：普通A产201，次数79、累计1；随后计时更新、状态通知、保存，之后才扣能量和落子。Lucky B产204直接返回，次数仍80、累计仍0。循环返回值1是演示输入，不代替远端循环配置。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- source-links:start -->

## 对应源码

[ItemSpread.lua](../../../../assets/recovered-source/ItemSpread.lua)

<!-- source-links:end -->

<!-- generator-configs:start -->

<a id="configuration-energy-cost"></a>

## 本页涉及的配表：能量增益次数扣除配置

**实际读取链**：`EnergyBoostModel:LoadServerConfig 读取 EnergyBoostCost.boost_num / cost；ItemSpread:CosetRestNumber → NextEnergyBoostCostIndex 消费循环次数序列。`

本组配表集中展示在本页；其它使用同一份已加载配置的页面提供查阅链接。包内值与服务器生效值分开标注。


### EnergyBoostCost 服务器字段（2 条）

来源：`EnergyBoostModel:LoadServerConfig / NextEnergyBoostCostIndex`。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 2 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>字段</th><th>作用</th><th>配置值</th><th>完整记录</th></tr></thead><tbody><tr><td>boost_num</td><td>消耗档位索引</td><td>服务器下发，未采集</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;字段&quot;: &quot;boost_num&quot;,
  &quot;作用&quot;: &quot;消耗档位索引&quot;,
  &quot;配置值&quot;: &quot;服务器下发，未采集&quot;
}</pre></details></td></tr><tr><td>cost</td><td>该档位的循环扣除次数序列</td><td>服务器下发，未采集</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;字段&quot;: &quot;cost&quot;,
  &quot;作用&quot;: &quot;该档位的循环扣除次数序列&quot;,
  &quot;配置值&quot;: &quot;服务器下发，未采集&quot;
}</pre></details></td></tr></tbody></table></div></div>


## 本逻辑使用的配表在哪里

- [母体配置与包内变体](../../state/model/detail.md#configuration-item-model)：配表文件/字段：`ItemModelConfig.json；ItemModelConfig_shell/carditem2/extracust`；ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。
- [产物难度分与解锁配置](../../output/order/detail.md#configuration-order-item)：配表文件/字段：`OrderItemConfig.json；OrderItemConfig_shell/hard/nerf/nerf_more/extracust`；ItemSpread:GetOrderItemCode 读取 Slot:GetItemCodeConfigMap()[code].DiffScore；ChestCustomItem 与 SmartItem 复用同一个代码配置映射。


<!-- generator-configs:end -->

