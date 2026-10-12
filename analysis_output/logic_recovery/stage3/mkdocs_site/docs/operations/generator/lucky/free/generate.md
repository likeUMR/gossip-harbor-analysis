# 免费阈值的生成、跨段与每日重置

免费 Lucky 由能量消费进度产生资格，不是一个额外物品池。它的阈值存档独立于普通周期机会与连续资格。

## 1. 载入能量段

`_LoadOtherServerConfig` 从服务器 luckyProduceConfig 读取记录，并按 energy_cost.range_entry[1] 升序排序。`_IsSpecialModeOn` 要求列表非空。活动进入 Started 时 `_UpdateSpecialModeData` 计算当前段并从数据库 elpec 读取已有阈值队列；初次进入该步骤本身不随机生成整段阈值。

## 2. 消费资源后检查跨段

Init 注册 PropertyConsumed 监听；`_OnPropertyConsumed` 只在属性类型为 Energy 时把消费数量加入 ecc，并调用 `_CheckLuckyProduceConfigIndex`。因此其它入口消费同种 Energy 也可能推进资格，不只母体点击。

`_CalculateLuckyProduceConfigIndex` 按排序后列表找 `下限 <= ecc <= 上限` 的第一段，无匹配返回0。段变化时，从“旧索引+1”到新索引生成阈值；新索引为0时结束索引取最后一段。这是源码的索引行为，不能自行解释为所有缺口段都重新生成。

## 3. 在每个新增段内抽取阈值

设区间 `[L,U]`，长度 `N=U-L+1`；`MathUtil.RandomN(N,min(N,extra_lucky))` 选不重复的序号，排序后转为 `L+序号-1` 并追加队列，最后把完整队列以逗号字符串保存到 elpec。RandomN 自身使用标记表跳过已选序号；准确随机接口见 MathUtil，而不是额外“命中概率”。

跨过多个段时会逐段追加；每段内部排序，不额外全局重排。超大消费可以让多项阈值已经可用，但一次免费资格只消费队首一项。

## 4. 按服务器日界重置

每秒更新调用 `_CheckIfNeedResetEnergyCost`，特殊模式存在且 `serverTime // Sec2Day` 与 ecrt 所属日不同才重置。`_ResetEnergyCost` 删除 ecc、elpec，写 ecrt，清除内存段索引与队列并重新装载。它不会在此处清普通 tl_/ll_ 机会计数，也不会删除连续 clpit/clpmc/clpc/clpeet。

活动 `_DropData` 先调用父类，再清本模型内存的特殊模式数据；父类数据库清理行为须单独核对，不能据本函数推断全部存档永久保留。服务器日界不同于客户端本地时区日期。

**状态与来源**：ecc（消费累计）、elpec（阈值队列）、ecrt（重置服务器时间）；energy_cost.range_entry / extra_lucky 为服务器字段，实际账号数值未取得。**源码**：_LoadOtherServerConfig、_OnStateChanged、_UpdateSpecialModeData、_OnPropertyConsumed、_AddEnergyCostCount、_CalculateLuckyProduceConfigIndex、_CheckLuckyProduceConfigIndex、_AddFreeLuckyProduceEnergyCostCount、UpdatePerSecond、_CheckIfNeedResetEnergyCost、_ResetEnergyCost、_ClearSpecialModeData、_DropData。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例假设食品袋105已积累足够能量并命中免费阈值。队首免费资格被消费，玩家得到一件 Free Lucky 物品；跨服务器日只清免费进度，不会顺带清普通周期或连续资格。

### 代入本页的值

假设能量段[0,9]、extra_lucky=2，随机序号3、8转为阈值2、7；这是服务器配置与受控抽样演示。累计Energy到5时队首2已满足，一次免费资格只移除2，7仍在队列。跨服务器日后ecc归0、elpec清空；tl_105/ll_105和已有连续clp字段不由_ResetEnergyCost直接删除。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- source-links:start -->

## 对应源码

[LuckyProduceModel.lua](../../../../assets/recovered-source/LuckyProduceModel.lua)

<!-- source-links:end -->

<!-- generator-configs:start -->

<a id="configuration-free-lucky"></a>

## 本页涉及的配表：免费 Lucky 服务器字段

**实际读取链**：`LuckyProduceModel:_LoadOtherServerConfig 载入 luckyProduceConfig；_AddFreeLuckyProduceEnergyCostCount 读取 energy_cost.range_entry 与 extra_lucky。`

本组配表集中展示在本页；其它使用同一份已加载配置的页面提供查阅链接。包内值与服务器生效值分开标注。


### 本页服务器配置字段（2 条）

来源：`LuckyProduceModel:_LoadOtherServerConfig`。这些字段不是 LuckyProduceConfig_triple 的包内字段；当前材料只确认读取结构，不能填写账号实际阈值。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 2 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>字段</th><th>用途</th><th>来源</th><th>本地值</th><th>完整记录</th></tr></thead><tbody><tr><td>energy_cost.range_entry</td><td>当前能量消耗区间 [下界,上界]，用于选段与生成阈值</td><td>活动服务器 luckyProduceConfig</td><td>未采集服务器生效配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;字段&quot;: &quot;energy_cost.range_entry&quot;,
  &quot;用途&quot;: &quot;当前能量消耗区间 [下界,上界]，用于选段与生成阈值&quot;,
  &quot;来源&quot;: &quot;活动服务器 luckyProduceConfig&quot;,
  &quot;本地值&quot;: &quot;未采集服务器生效配置&quot;
}</pre></details></td></tr><tr><td>extra_lucky</td><td>区间内免费 Lucky 的阈值数量；取 min(区间长度,extra_lucky)</td><td>活动服务器 luckyProduceConfig</td><td>未采集服务器生效配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;字段&quot;: &quot;extra_lucky&quot;,
  &quot;用途&quot;: &quot;区间内免费 Lucky 的阈值数量；取 min(区间长度,extra_lucky)&quot;,
  &quot;来源&quot;: &quot;活动服务器 luckyProduceConfig&quot;,
  &quot;本地值&quot;: &quot;未采集服务器生效配置&quot;
}</pre></details></td></tr></tbody></table></div></div>


<!-- generator-configs:end -->

