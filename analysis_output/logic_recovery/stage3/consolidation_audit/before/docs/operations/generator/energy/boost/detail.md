# 能量档、Lucky 历史均值与最终扣费

## 1. 预检查最大档

`GetCostEnergyNum` 默认成本1、指数0；母体支持当前能量档时读取当前最大成本和指数。余额预检查使用这个最大成本；后续产物可能降档，不能把余额检查数值当作最终消费。

## 2. Lucky 路径的历史调整

`GetAdjustedMaxEnergyBoostRatio`：AdjustLuckyProduceBoostRatio 服务端开关关闭或历史为空时返回传入指数；否则对历史指数求平均并向上取整。源码没有再取 min(当前档,均值)，因此不能自行给复刻加这项上限。

`_InitEnergyBoostRatioAdjustData` 从 PlayerPrefs 的 LuckyProduceEnergyBoostRatioAdjustData 读取逗号序列。`RecordBoostRatioAdjustData` 只记录开关开启、实际扣能量、来源为 Normal 或 GeneratorBoostSmart、且母体属于能量增益目标的点击。最多保存最近4条：满时移除最旧一条，再追加本次实际指数并保存。Lucky 本身及其它来源不会更新这段历史。

`TryGenerateLuckyItem` 取调整指数后沿 MergedType 升级相应次数；缺 MergedType 时保留当前代码继续循环。它不走普通次数扣除链。

## 3. 普通路径的订单截档

`SpreadCheckEnergyRatioAndCode` 只有最大指数>0、算法允许增益且代码无特殊前缀时，先取最大档，再按 i=0..最大档扫描同链等级：目标等级存在订单缺口，或满足源码中的低等级正奇数剩余条件时，截为 i 并停止。奇数条件的等级限制是 `chainLevel+i < maxEnergyBoostRatio+1`，不能泛化成“所有等级有奇数就截档”。随后沿 MergedType 升级，生鱼专用逻辑见链升级与 FishNet。

## 4. 真正扣能量与母体次数

`SpreadCostEnergy` 在产物计算后使用 EnergyBoostModel.GetBoostCostNum(最终指数) 消费资源；普通可恢复母体的次数由 NextEnergyBoostCostIndex 决定。该函数按 `floor(2^指数)` 查服务器 EnergyBoostCost 循环序列，按 PlayerPrefs 的 EnergyBoostCost_成本 键读取并推进索引；缺配置或未开启增益返回1，索引失效时回退序列首项。一次性母体默认次数扣 `floor(2^指数)`，算法显式提供 costCount 则优先使用它，包括0。

**边界**：历史可能调整出不同于当前预检查的 Lucky 档；原版最终资源系统如何处理余额边界仍需端到端验证，不应假设这里自动二次检查。**来源**：ItemSpread.GetCostEnergyNum、TryGenerateLuckyItem、SpreadCheckEnergyRatioAndCode、SpreadCostEnergy；LuckyProduceModel 的历史三个函数；EnergyBoostModel.NextEnergyBoostCostIndex。服务端开关、次数序列与真实账号历史为 runtime-pending。

---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：主案例使用基础档、不调整历史。独立对照显示Lucky如何根据过去几次普通点击的实际指数调整产物档，同时普通母体次数扣除由独立循环序列控制。

### 代入本页的值

对照假设开关开启且最近指数为[0,1,2,2]，Lucky调整指数ceil(5/4)=2，物品沿MergedType升级两次；假设当前最大指数3，也仍取历史均值2。若可恢复母体的4点能量档次数序列为[1,2,1]，索引1、2、3依次扣1、2、1再回1；序列是假设的服务器值，不能视为原版固定参数。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- generator-configs:start -->

<a id="configuration-energy-boost"></a>

## 本页涉及的配表：能量增益适用母体

**实际读取链**：`EnergyBoostModel:OnSyncDataFinished 直接 require EnergyBoostItemConfig，建立 m_mapTargetItemType；CanEnergyBoost 读取此适用集合。`

本组配表集中展示在本页；其它使用同一份已加载配置的页面提供查阅链接。包内值与服务器生效值分开标注。


### EnergyBoostItemConfig：完整适用列表（38 条）

来源：`Data.Config.EnergyBoostItemConfig`。本文件只配置适用母体 ID，不配置次数、CD 或普通产出权重。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 38 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>母体/棋子 ID<small style="display:block">Type</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/104.png" alt="104"><span><b>104</b><small>满载购物袋</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;104&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;105&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;106&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;107&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;108&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;109&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;110&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;111&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/404.png" alt="404"><span><b>404</b><small>无咖啡因咖啡壶</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;404&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;405&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;406&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;407&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;408&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;409&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;410&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;411&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/705.png" alt="705"><span><b>705</b><small>鱼网</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;705&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/706.png" alt="706"><span><b>706</b><small>贝类网</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;706&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/707.png" alt="707"><span><b>707</b><small>大贝类网</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;707&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/708.png" alt="708"><span><b>708</b><small>高级钓鱼冷却器</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;708&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/709.png" alt="709"><span><b>709</b><small>鱼箱</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;709&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/710.png" alt="710"><span><b>710</b><small>爱好者鱼缸</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;710&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/711.png" alt="711"><span><b>711</b><small>豪华海鲜柜</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;711&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1205.png" alt="1205"><span><b>1205</b><small>豪华泳池包</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1205&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1206.png" alt="1206"><span><b>1206</b><small>高级海洋储存箱</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1206&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1207&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1208&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1209&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1210&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1211&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1705.png" alt="1705"><span><b>1705</b><small>小珊瑚丛</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1705&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1706&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1707&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1708&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1709&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1710&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;1711&quot;
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Type&quot;: &quot;805&quot;
}</pre></details></td></tr></tbody></table></div></div>


### 八倍能量档的服务器字段（1 条）

来源：`EnergyBoostModel:TryTriggerEightEnergyBoost / OnLoginFinished`。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 1 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>字段</th><th>作用</th><th>配置值</th><th>完整记录</th></tr></thead><tbody><tr><td>EnergyBoostEight</td><td>八倍能量档触发能量门槛</td><td>服务器通用配置，未采集</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;字段&quot;: &quot;EnergyBoostEight&quot;,
  &quot;作用&quot;: &quot;八倍能量档触发能量门槛&quot;,
  &quot;配置值&quot;: &quot;服务器通用配置，未采集&quot;
}</pre></details></td></tr></tbody></table></div></div>


## 本逻辑使用的配表在哪里

- [母体配置与包内变体](../../state/model/detail.md#configuration-item-model)：配表文件/字段：`ItemModelConfig.json；ItemModelConfig_shell/carditem2/extracust`；ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。


<!-- generator-configs:end -->

