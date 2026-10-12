# 能量链升级与 FishNet 补缺算法

## 1. 决定实际升级几级

记录原始代码。只有最大增益指数>0、普通算法允许能量升级、代码无特殊前缀三项成立时才使用最大指数b；否则从指数0开始。

若棋盘提供订单缺口图，按i=0..b检查原代码同链的第L+i级：此代码在缺口图中存在，或同时满足 `L+i<b+1`、库存映射中有此代码、`max(库存−订单需求,0)` 为奇数，就把实际指数截为i并停止。存在性判断采用Lua真值，不是单独比较缺口数>0。奇数判断受等级边界限制，不能泛化成每个等级都配对。

然后按实际指数次读取MergedType，缺MergedType时保留原代码；即使没有变成更高等级，指数本身不会因此自动减少。记录升级后的代码。

## 2. FishNet 在升级后再检查

FishNetProduceSmart服务器开关开启、升级后代码无特殊前缀、代码链为RwaFish时才执行。统计同链1..最高级−1的现有物品，每件等级l换算成 `2^(l−1)` 一级鱼；最高级库存不计入。总一级量记为T，合成一件最高级需要M，缺口 `D=M−(T mod M)`。

D必须是二次幂且不等于M；T恰好是M倍数时D=M，故不改写。候选等级范围是 `[1+实际指数, min(3+实际指数,最高级)]`，不是“原始产物等级+1到+3”。D还须至少达到该范围最小等级的一级等价量。

在范围内由低到高查找一级等价量恰好为D的等级，且该等级必须严格低于当前升级后产物等级，才替换产物并记录FishNetProduceSmart场景。此机制只能下调当前产物到补齐缺口的等级，不是再次向上升级；返回能量指数保持不变，后续活动仍可能再改代码/指数。

**来源**：ItemSpread SpreadCheckEnergyRatioAndCode；ItemModelConfig.MergedType及链等级映射；棋盘订单缺口/需求/库存；服务器FishNetProduceSmart开关。阈值1、3及二次幂公式来自代码，不是配表。

---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：食品袋105不属于生鱼链，主例不执行FishNet；独立生鱼对照展示“补缺降级”而不是再升级。

### 代入本页的值

假设生鱼最高级6，M=32，已有一级等价T=24，D=32−24=8，对应4级。实际能量指数2时候选等级为3..5；若升级后产物等级5，4在范围内且4<5，改给4级鱼，指数仍2。若当前产物已经4级，严格小于不成立，不改。链级数、库存和指数为对照输入。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

<a id="configuration-fish-smart"></a>

## 本页涉及的配表：生鱼链智能升级开关

**实际读取链**：`ItemSpread:SpreadCheckEnergyRatioAndCode 读取服务器通用开关 FishNetProduceSmart，再沿 ItemDataModel 的合成链计算升级。`

本组配表集中展示在本页；其它使用同一份已加载配置的页面提供查阅链接。包内值与服务器生效值分开标注。


### FishNetProduceSmart 服务器字段（1 条）

来源：`ItemSpread:SpreadCheckEnergyRatioAndCode`。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 1 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>字段</th><th>作用</th><th>配置值</th><th>完整记录</th></tr></thead><tbody><tr><td>FishNetProduceSmart</td><td>生鱼链智能升级开关</td><td>服务器通用配置，未采集</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;字段&quot;: &quot;FishNetProduceSmart&quot;,
  &quot;作用&quot;: &quot;生鱼链智能升级开关&quot;,
  &quot;配置值&quot;: &quot;服务器通用配置，未采集&quot;
}</pre></details></td></tr></tbody></table></div></div>


## 本逻辑使用的配表在哪里

- 母体配置与包内变体：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。
- 能量增益适用母体：EnergyBoostModel:OnSyncDataFinished 直接 require EnergyBoostItemConfig，建立 m_mapTargetItemType；CanEnergyBoost 读取此适用集合。


<!-- generator-configs:end -->

<!-- source-links:start -->

## 对应源码

[ItemSpread.lua](../../../../assets/recovered-source/ItemSpread.lua)

<!-- source-links:end -->
