# Smart Produce 权重修正

Smart 修正改变“本次 Lucky 物品更倾向哪条订单链”，不增加 Lucky 资格，也不额外产出物品。它在获得 Lucky 资格后、物品权重抽取前执行。

## 1. 开启条件

`_LoadOtherServerConfig` 使用 `MiscConfigReader:GetInteger` 读取 `lucky_produce_smart` 到 `m_smartProduceRatio`。`_UseSmartProduce` 仅当该值非 nil 且至少为1才返回 true。`0.25` 不会开启，值1虽开启却不改变数值权重；真正倾斜需要大于1。账号当前值未取得。

## 2. 决定哪些候选能帮助订单

读取当前主棋盘订单缺口映射，只使用缺口代码是否存在，不把缺少数量乘入公式。母体支持当前能量增益时取增益指数 `b`，否则取0。

对每个缺口代码，按合成链找到 `config.itemChainMap[chainId]` 的候选；只有 `订单目标等级 >= 候选原始等级 + b` 才标记候选。不同合成链不匹配；多个缺口同时匹配同一候选也只标记一次。

## 3. 从原权重重新计算临时权重

`Weight_Smart = Weight × (已标记 ? m_smartProduceRatio : 1)`。每次从原始 Weight 重算，不在上一次 Weight_Smart 上复乘，也没有 `1+倍率×缺口数` 的公式。然后 `Table.ListWeightSelectOne(config.lucky_items, "Weight_Smart")` 使用临时池选择。

| 输入 | 作用 |
|---|---|
| lucky_items.Weight | 原始份额，本函数不修改 |
| ItemChainLevel / itemChainMap | 候选等级与同链索引，由配置预处理建立 |
| 当前订单缺口代码 | 仅作为匹配标志；缺口数量不直接入公式 |
| 能量增益指数 b | 检查该候选升级后是否超过需求等级 |
| lucky_produce_smart | 匹配候选直接乘的整数倍率 |

**边界**：没有订单缺口或没有同链匹配时，所有临时权重等于原权重；订单变化后重新计算可恢复原值。此处使用当前能量档，后续 Lucky 产物可能使用历史均值调整档，二者是不同读取点。**证据**：`CalculateItemChainMap`、`_UseSmartProduce`、`_UpdateSpreadConfigSmartWeight` 为 `source-confirmed`；账号倍率与运行时订单为 `runtime-pending`。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-204.png" alt="Lucky 产物 204" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：主案例关闭Smart，仍按原始Lucky权重抽出204；下面的独立对照开启整数倍率3，订单缺205且能量指数1时，只把同链可帮助订单的204权重乘3，说明倾向如何改变。

### 代入本页的值

本地食品袋105的默认Lucky池为204×63、205×10、303×15、304×10、305×2，总100。主案例未开启Smart。独立对照假设服务器倍率3、订单缺205（等级5）、能量指数1：204等级4满足5≥4+1，权重63×3=189；205等级5不满足5≥5+1，仍10；薯条链仍15、10、2。总226，204占189/226≈83.63%。演示整数抽样点50命中204。倍率、订单和抽样点为假设，原权重为本地配表；缺多少个205不再乘入权重。

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

<a id="configuration-lucky-smart"></a>

## 本页涉及的配表：Lucky Smart Produce 参数

**实际读取链**：`_LoadOtherServerConfig 用 MiscConfigReader:GetInteger(MiscConfKey.LuckyProduceSmart) 载入倍率；_UpdateSpreadConfigSmartWeight 使用原始物品池计算临时权重。`

本组配表集中展示在本页；其它使用同一份已加载配置的页面提供查阅链接。包内值与服务器生效值分开标注。


### Smart Produce 参数与临时权重（2 条）

来源：`LuckyProduceModel:_LoadOtherServerConfig / _UpdateSpreadConfigSmartWeight`。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 2 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>字段</th><th>值</th><th>用途</th><th>完整记录</th></tr></thead><tbody><tr><td>LuckyProduceSmart</td><td>服务器整数，未采集</td><td>控制 Smart Produce 倍率</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;字段&quot;: &quot;LuckyProduceSmart&quot;,
  &quot;值&quot;: &quot;服务器整数，未采集&quot;,
  &quot;用途&quot;: &quot;控制 Smart Produce 倍率&quot;
}</pre></details></td></tr><tr><td>SpreadSmartWeightKey</td><td>由订单缺口与倍率计算</td><td>运行时临时权重，不是另一个包内配表文件</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;字段&quot;: &quot;SpreadSmartWeightKey&quot;,
  &quot;值&quot;: &quot;由订单缺口与倍率计算&quot;,
  &quot;用途&quot;: &quot;运行时临时权重，不是另一个包内配表文件&quot;
}</pre></details></td></tr></tbody></table></div></div>


## 本逻辑使用的配表在哪里

- [Lucky 包内配置及活动变体](../chance/load.md#configuration-lucky)：配表文件/字段：`LuckyProduceConfig、LuckyProduceConfig_shell、LuckyProduceConfig_triple、LuckyProduceConfig_tripleshell、GeneratorBoostLuckyProduceConfig、GeneratorBoostLuckyProduceConfig_shell`；LuckyProduceModel:_LoadFileConfig → _GetLevelFitConfig → Try2ProduceLuckyItem；按 generator、等级区间选择记录，再用 lucky_chance 重装机会池。


<!-- generator-configs:end -->

