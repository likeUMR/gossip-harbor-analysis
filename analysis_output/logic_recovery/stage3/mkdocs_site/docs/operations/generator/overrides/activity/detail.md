# Disco 的订单选择、助力分值与普通回退

## 1. 支持条件与优先级

ItemSpread只在主棋盘调用Disco支持判断。处理器要求缓存存在且boostChargeNum>0、该母体没有被缓存为不支持、IsGeneratorItem为真、模型配置存在且Spread_CostEnergy恰好1。配置缺失返回false，非生成器会缓存false。是否显示入口另受canPopUpWindow限制，不能用显示资格代替玩法资格。

支持时CheckEnergy把costEnergy设false，返回指数0并跳余额检查；CheckLuckyProduce也直接返回false。GenerateItemCode随后调用TryGetSpreadItem，有目标就直接返回 `(code,Disco,0)`；没有目标才把普通最大指数设3、来源设Disco。Lucky与Disco并不是同时各抽一次。

## 2. 直接目标如何找

按母体Spread_Weight缓存可产出链，没有配置/权重就缓存false。订单缺口来自 `CalculateOrderCodeLackNumMapByLevelSize(false,true,false)`，数量是该接口返回的等价缺口。按代码链等级升序，同等级优先MapItemSubChain中存在的链；再同级同类别没有稳定排序键。

只考虑母体能产出的链。目标难度默认链等级，有订单DifficultyLevel时覆盖。允许难度上限来自当前DiscoContentConfig.difficulty_level；可负担等级 `floor(log2(剩余助力+8))+1`，实现用反复右移算，不用浮点log。

若目标难度不高于配置阈值，母体不是RawFish05且母体链没有ItemSpecailGenearteItemChain标记：优先目标本身；难度超出可负担等级时，从目标等级−1向一级查，第一个难度可负担的同链代码成为直接目标。

否则，先从母体普通权重中筛该缺口链并按Weight抽原始物品，起始候选等级取 `min(原始等级+3,可负担等级)`；由这个等级向一级倒序查，第一条 `2^(等级−1)≤该订单一级等价缺口` 的代码成为目标。DifficultyLevel用于该目标实际费用。全局只采用第一个找到的目标，不把多个订单作为独立奖池。

## 3. 直接目标的费用

TryGetSpreadItem按 `2^(目标DifficultyLevel−1)` 扣助力；ReduceDiscoScore将剩余截0，发TriggerBoostDiscoUpdate（参数是费用）、归零则CloseDisco，最后保存。8分是选物品可负担性的宽限，不给助力余额真正加8。直接产出已经扣了Disco分值，但没有扣母体普通次数、没有消费Fixed池。

## 4. 无直接目标：普通结果再降级

普通路径先走SafeSpreadItem、普通候选、能量升级/FishNet。DealActivityLimit再次检查Disco支持：TryUseDiscoItem将最终代码的DifficultyLevel（缺时用链等级）转为 `2^(难度−1)`。费用超过剩余助力+8就每次降代码一级、重新查DifficultyLevel、能量指数减1；到一级停止。

指数在这个循环没有截到0。之后扣Disco助力并返回代码/指数，DealActivityLimit将costCount置0，CosetRestNumber仍让累计点击+1、次数不减。正常外层costEnergy=false，因此不额外消耗Energy；不能把母体次数、Energy和Disco助力混成一个数。

## 5. 结束与配置边界

CloseDisco记录将关闭的属性、清m_cacheData、保存、异步加载关闭提示并发TriggerBoostDiscoFinished。DiscoContentConfig按type建映射，重复type由后记录覆盖；score用于获得Buff时换算助力，difficulty_level用于上述直接目标判定。远端当前配置未取得时，不应给出一个假定的原版固定费用表。

**证据**：ItemSpread CanSupportBoostDisco、CheckEnergy、CheckLuckyProduce、GenerateItemCode、TryGenerateDiscoItem、DealActivityLimit；BoostChargeDiscoBoostHandler LoadServerConfig、CanSupportItem、RefreshGenerateCodeCache、IsCurDiscoSpreadItem、GetMaxLevelByScore、TryGetSpreadItem、TryUseDiscoItem、ReduceDiscoScore、CloseDisco。

## 6. 助力从哪里来，以及再次获得会发生什么

获得Disco奖励时，Acquire先按奖励type查DiscoContentConfig；配置不存在则返回，不增加助力。获得分值=配置score×奖励数量。无缓存时建立boostChargeNum=0、canPopUpWindow=false、MaxChargeNum=0；随后把分值加到当前余额，将MaxChargeNum设为增加后的当前余额，余额大于0时开启弹窗资格，并将curProperty改为本次奖励类型。先保存，再发TriggerBoostDiscoStarted，最后记录激活及获得日志。

因此再次获得不同类型Disco时，剩余助力与新奖励分值相加，但后续difficulty_level使用最新curProperty对应的配置；MaxChargeNum也不是永远累加的历史总收入。PopWindowFinished只清canPopUpWindow并保存，不清助力余额、不关闭玩法。不能把“已看过提示”当成“Disco已结束”。

## 7. Disco 本身的配置字段

| 来源与字段 | 具体含义 | 对本次点击的影响 |
|---|---|---|
| 服务器DiscoContentConfig.type | 奖励类型，按type建字典，同键后记录覆盖前记录 | 当前缓存curProperty决定读取哪条 |
| score | 每单位奖励增加的助力分值 | 获得时乘奖励数量，加入余额；不直接作抽样权重 |
| difficulty_level | 直接帮助订单的难度阈值 | 与目标DifficultyLevel比较，选择直给目标或特殊母体选物路径 |
| 订单物品DifficultyLevel | 目标费用难度，缺省用链等级 | 费用为2^(难度−1)，降级后需重新查 |
| 母体Spread_CostEnergy、Spread_Weight | 支持资格及可产出链 | 前者严格为1；后者用于确定能帮哪些订单链 |

DiscoContentConfig来自服务器，当前资源没有账号生效记录；上表可以确定算法与字段含义，不能给score或difficulty_level填一个原版固定值。下方Generator Boost母体替换表是另一活动对普通母体配置的改写，**不是DiscoContentConfig，也不是Disco的助力费用表**。

## 8. 两条路径的结算对照

| 结算对象 | 找到直接订单目标 | 未找到目标，回退普通选择 |
|---|---|---|
| 普通候选池 | 不进入五种普通选择 | 进入实际模式；Fixed等池仍按自己的规则变化 |
| 普通母体次数 | 不调用普通扣次 | costCount=0，次数不减 |
| 点击累计 | 不调用CosetRestNumber | CosetRestNumber使累计+1 |
| 普通Energy | costEnergy=false | costEnergy=false |
| Disco助力 | 按直接目标DifficultyLevel扣 | 普通结果经降级后按最终难度扣 |
| 普通状态更新/保存 | 不走普通GenerateItemCode尾部 | 扣次后更新计时、发状态通知并保存 |

这解释了为何“次数没减”仍不足以判断抽样池有没有被消费。具体值对照见下面的食品袋案例：10分助力允许在8分选物宽限内直接产费用16的205，余额截0，普通池仍42；宽限只用于选物，不让助力形成负余额。

---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：105主例未开启Disco。独立Disco对照说明先扣专用助力直接给订单物品，既不消耗普通池，也不扣普通能量和次数。

### 代入本页的值

假设105受Disco支持，剩余助力10，配置difficulty_level=5，订单缺五级205且其DifficultyLevel=5；可负担上限由10+8=18右移算得5，直接给205并扣2^(5−1)=16，助力截0且关闭Disco。返回能量指数0，costEnergy=false，次数仍80、Fixed池仍42。阈值与助力是对照输入，8分宽限来自代码；不足的6分不会成为负余额。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

<a id="configuration-generator-boost"></a>

## 本页涉及的配表：Generator Boost 母体替换配置

**实际读取链**：`GeneratorBoostActivityModel:GetItemModelConfig → ReloadItemModelConfig；按 Buff 选择 MoreLuckyProduce / ExtraProduce 并替换 ItemDataModel 中的母体配置。`

本组配表集中展示在本页；其它使用同一份已加载配置的页面提供查阅链接。包内值与服务器生效值分开标注。


### GeneratorBoostItemModelConfig / MoreLuckyProduce（32 条）

来源：`Data.Config.GeneratorBoostItemModelConfig`。仅在对应活动分组生效时替换母体配置，不能与默认配置累加。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 32 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>母体/棋子 ID<small style="display:block">Type</small></th><th>自动产出<small style="display:block">Spread_Auto</small></th><th>是否消耗能量<small style="display:block">Spread_CostEnergy</small></th><th>单轮次数上限<small style="display:block">Spread_ItemMaxNumber</small></th><th>单轮恢复（秒）<small style="display:block">Spread_ItemRecoveryDuration</small></th><th>单轮加速（宝石）<small style="display:block">Spread_ItemSpeedUpCost</small></th><th>储备次数上限<small style="display:block">Spread_StorageMaxNumber</small></th><th>储备恢复（秒）<small style="display:block">Spread_StorageRecoveryDuration</small></th><th>储备加速（宝石）<small style="display:block">Spread_StorageSpeedUpCost</small></th><th>普通产物 × 权重<small style="display:block">Spread_Weight</small></th><th>产出模式<small style="display:block">Spread_WeightType</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span></td><td>0</td><td>1</td><td>80</td><td>30</td><td>1</td><td>240</td><td>60</td><td>1</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 37<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 60,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;106&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 1,
  &quot;Spread_Weight&quot;: [
    &quot;201-37&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 1,
  &quot;Spread_ItemRecoveryDuration&quot;: 30,
  &quot;SellingPrice&quot;: 3,
  &quot;Type&quot;: &quot;105&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 36<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;107&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-36&quot;,
    &quot;202-1&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;106&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;108&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-35&quot;,
    &quot;202-2&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;107&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 34<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;109&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-34&quot;,
    &quot;202-3&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;108&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;110&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-33&quot;,
    &quot;202-4&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;109&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;111&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-32&quot;,
    &quot;202-5&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;110&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/302.png" alt="302"><span><b>302</b><small>切片土豆</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-32&quot;,
    &quot;202-5&quot;,
    &quot;301-4&quot;,
    &quot;302-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;111&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 37<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;406&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-37&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 3,
  &quot;Type&quot;: &quot;405&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 36<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;407&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-36&quot;,
    &quot;502-1&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;406&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;408&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-35&quot;,
    &quot;502-2&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;407&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 34<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;409&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-34&quot;,
    &quot;502-3&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;408&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;410&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-33&quot;,
    &quot;502-4&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;409&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;411&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-32&quot;,
    &quot;502-5&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;410&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/602.png" alt="602"><span><b>602</b><small>热茶</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-32&quot;,
    &quot;502-5&quot;,
    &quot;601-4&quot;,
    &quot;602-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;411&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/706.png" alt="706"><span><b>706</b><small>贝类网</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 97<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 3</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;707&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-97&quot;,
    &quot;802-3&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;706&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/707.png" alt="707"><span><b>707</b><small>大贝类网</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 96<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;708&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-96&quot;,
    &quot;802-4&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;707&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/708.png" alt="708"><span><b>708</b><small>高级钓鱼冷却器</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 95<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;709&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-95&quot;,
    &quot;802-4&quot;,
    &quot;803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;708&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/709.png" alt="709"><span><b>709</b><small>鱼箱</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 94<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;710&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-94&quot;,
    &quot;802-5&quot;,
    &quot;803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;709&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/710.png" alt="710"><span><b>710</b><small>爱好者鱼缸</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 93<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;711&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-93&quot;,
    &quot;802-6&quot;,
    &quot;803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;710&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/711.png" alt="711"><span><b>711</b><small>豪华海鲜柜</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 92<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/901.png" alt="901"><span><b>901</b><small>鲑鱼片</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-92&quot;,
    &quot;802-7&quot;,
    &quot;803-1&quot;,
    &quot;901-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;711&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td>0</td><td>1</td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/901.png" alt="901"><span><b>901</b><small>鲑鱼片</small></span></span> × 96<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/902.png" alt="902"><span><b>902</b><small>蜂蜜釉面鲑鱼</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 10,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_Weight&quot;: [
    &quot;901-96&quot;,
    &quot;902-4&quot;
  ],
  &quot;SellingPrice&quot;: 3,
  &quot;Type&quot;: &quot;805&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;LevelDownPiece&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1208&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-35&quot;,
    &quot;1302-1&quot;,
    &quot;1401-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;1207&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 37<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1209&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-37&quot;,
    &quot;1302-1&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;1208&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 36<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1210&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-36&quot;,
    &quot;1302-2&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;1209&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1211&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-35&quot;,
    &quot;1302-3&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;1210&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1402.png" alt="1402"><span><b>1402</b><small>潜水护目镜</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-35&quot;,
    &quot;1302-3&quot;,
    &quot;1401-5&quot;,
    &quot;1402-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;1211&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 97<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 3</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1707&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-97&quot;,
    &quot;1802-3&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;1706&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 96<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1708&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-96&quot;,
    &quot;1802-4&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;1707&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 96<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1709&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-96&quot;,
    &quot;1802-3&quot;,
    &quot;1803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;1708&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 95<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1710&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-95&quot;,
    &quot;1802-4&quot;,
    &quot;1803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;1709&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 94<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1711&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-94&quot;,
    &quot;1802-5&quot;,
    &quot;1803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;1710&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 93<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-93&quot;,
    &quot;1802-6&quot;,
    &quot;1803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;1711&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr></tbody></table></div></div>


### GeneratorBoostItemModelConfig / ExtraProduce（32 条）

来源：`Data.Config.GeneratorBoostItemModelConfig`。仅在对应活动分组生效时替换母体配置，不能与默认配置累加。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 32 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>母体/棋子 ID<small style="display:block">Type</small></th><th>自动产出<small style="display:block">Spread_Auto</small></th><th>是否消耗能量<small style="display:block">Spread_CostEnergy</small></th><th>单轮次数上限<small style="display:block">Spread_ItemMaxNumber</small></th><th>单轮恢复（秒）<small style="display:block">Spread_ItemRecoveryDuration</small></th><th>单轮加速（宝石）<small style="display:block">Spread_ItemSpeedUpCost</small></th><th>储备次数上限<small style="display:block">Spread_StorageMaxNumber</small></th><th>储备恢复（秒）<small style="display:block">Spread_StorageRecoveryDuration</small></th><th>储备加速（宝石）<small style="display:block">Spread_StorageSpeedUpCost</small></th><th>普通产物 × 权重<small style="display:block">Spread_Weight</small></th><th>产出模式<small style="display:block">Spread_WeightType</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span></td><td>0</td><td>1</td><td>80</td><td>30</td><td>1</td><td>240</td><td>60</td><td>1</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 60,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;106&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 1,
  &quot;Spread_Weight&quot;: [
    &quot;201-35&quot;,
    &quot;202-2&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 1,
  &quot;Spread_ItemRecoveryDuration&quot;: 30,
  &quot;SellingPrice&quot;: 3,
  &quot;Type&quot;: &quot;105&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;107&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-35&quot;,
    &quot;202-1&quot;,
    &quot;203-1&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;106&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 34<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;108&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-34&quot;,
    &quot;202-2&quot;,
    &quot;203-1&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;107&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;109&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-33&quot;,
    &quot;202-3&quot;,
    &quot;203-1&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;108&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;110&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-32&quot;,
    &quot;202-4&quot;,
    &quot;203-1&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;109&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;111&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-32&quot;,
    &quot;202-3&quot;,
    &quot;203-2&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;110&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/302.png" alt="302"><span><b>302</b><small>切片土豆</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-32&quot;,
    &quot;202-3&quot;,
    &quot;203-2&quot;,
    &quot;301-4&quot;,
    &quot;302-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;111&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 37<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;406&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-37&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 3,
  &quot;Type&quot;: &quot;405&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;407&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-35&quot;,
    &quot;502-1&quot;,
    &quot;503-1&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;406&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 34<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;408&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-34&quot;,
    &quot;502-2&quot;,
    &quot;503-1&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;407&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;409&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-33&quot;,
    &quot;502-3&quot;,
    &quot;503-1&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;408&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;410&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-32&quot;,
    &quot;502-4&quot;,
    &quot;503-1&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;409&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;411&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-32&quot;,
    &quot;502-3&quot;,
    &quot;503-2&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;410&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/602.png" alt="602"><span><b>602</b><small>热茶</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-32&quot;,
    &quot;502-3&quot;,
    &quot;503-2&quot;,
    &quot;601-4&quot;,
    &quot;602-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;411&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/706.png" alt="706"><span><b>706</b><small>贝类网</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 97<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 3</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;707&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-97&quot;,
    &quot;802-3&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;706&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/707.png" alt="707"><span><b>707</b><small>大贝类网</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 96<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;708&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-96&quot;,
    &quot;802-4&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;707&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/708.png" alt="708"><span><b>708</b><small>高级钓鱼冷却器</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 95<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;709&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-95&quot;,
    &quot;802-4&quot;,
    &quot;803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;708&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/709.png" alt="709"><span><b>709</b><small>鱼箱</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 94<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;710&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-94&quot;,
    &quot;802-5&quot;,
    &quot;803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;709&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/710.png" alt="710"><span><b>710</b><small>爱好者鱼缸</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 93<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;711&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-93&quot;,
    &quot;802-6&quot;,
    &quot;803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;710&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/711.png" alt="711"><span><b>711</b><small>豪华海鲜柜</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 92<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/901.png" alt="901"><span><b>901</b><small>鲑鱼片</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-92&quot;,
    &quot;802-7&quot;,
    &quot;803-1&quot;,
    &quot;901-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;711&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td>0</td><td>1</td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/901.png" alt="901"><span><b>901</b><small>鲑鱼片</small></span></span> × 96<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/902.png" alt="902"><span><b>902</b><small>蜂蜜釉面鲑鱼</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 10,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_Weight&quot;: [
    &quot;901-96&quot;,
    &quot;902-4&quot;
  ],
  &quot;SellingPrice&quot;: 3,
  &quot;Type&quot;: &quot;805&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;LevelDownPiece&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1208&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-33&quot;,
    &quot;1302-1&quot;,
    &quot;1401-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;1207&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 34<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1209&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-34&quot;,
    &quot;1302-2&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;1208&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1210&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-33&quot;,
    &quot;1302-3&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;1209&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1211&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-32&quot;,
    &quot;1302-4&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;1210&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1402.png" alt="1402"><span><b>1402</b><small>潜水护目镜</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-32&quot;,
    &quot;1302-4&quot;,
    &quot;1401-5&quot;,
    &quot;1402-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;1211&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 97<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 3</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1707&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-97&quot;,
    &quot;1802-3&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;1706&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 94<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1708&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-94&quot;,
    &quot;1802-6&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;1707&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 92<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1709&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-92&quot;,
    &quot;1802-7&quot;,
    &quot;1803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;1708&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 91<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 8<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1710&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-91&quot;,
    &quot;1802-8&quot;,
    &quot;1803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;1709&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 89<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 2</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1711&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-89&quot;,
    &quot;1802-9&quot;,
    &quot;1803-2&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;1710&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 88<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 3</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-88&quot;,
    &quot;1802-9&quot;,
    &quot;1803-3&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;1711&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr></tbody></table></div></div>


### GeneratorBoostItemModelConfig_shell / MoreLuckyProduce（32 条）

来源：`Data.Config.GeneratorBoostItemModelConfig_shell`。仅在对应活动分组生效时替换母体配置，不能与默认配置累加。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 32 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>母体/棋子 ID<small style="display:block">Type</small></th><th>自动产出<small style="display:block">Spread_Auto</small></th><th>是否消耗能量<small style="display:block">Spread_CostEnergy</small></th><th>单轮次数上限<small style="display:block">Spread_ItemMaxNumber</small></th><th>单轮恢复（秒）<small style="display:block">Spread_ItemRecoveryDuration</small></th><th>单轮加速（宝石）<small style="display:block">Spread_ItemSpeedUpCost</small></th><th>储备次数上限<small style="display:block">Spread_StorageMaxNumber</small></th><th>储备恢复（秒）<small style="display:block">Spread_StorageRecoveryDuration</small></th><th>储备加速（宝石）<small style="display:block">Spread_StorageSpeedUpCost</small></th><th>普通产物 × 权重<small style="display:block">Spread_Weight</small></th><th>产出模式<small style="display:block">Spread_WeightType</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span></td><td>0</td><td>1</td><td>80</td><td>30</td><td>1</td><td>240</td><td>60</td><td>1</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 37<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 60,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;106&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 1,
  &quot;Spread_Weight&quot;: [
    &quot;201-37&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 1,
  &quot;Spread_ItemRecoveryDuration&quot;: 30,
  &quot;SellingPrice&quot;: 3,
  &quot;Type&quot;: &quot;105&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 36<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;107&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-36&quot;,
    &quot;202-1&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;106&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;108&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-35&quot;,
    &quot;202-2&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;107&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 34<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;109&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-34&quot;,
    &quot;202-3&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;108&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;110&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-33&quot;,
    &quot;202-4&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;109&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;111&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-32&quot;,
    &quot;202-5&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;110&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/302.png" alt="302"><span><b>302</b><small>切片土豆</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-32&quot;,
    &quot;202-5&quot;,
    &quot;301-4&quot;,
    &quot;302-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;111&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 37<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;406&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-37&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 3,
  &quot;Type&quot;: &quot;405&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 36<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;407&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-36&quot;,
    &quot;502-1&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;406&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;408&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-35&quot;,
    &quot;502-2&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;407&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 34<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;409&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-34&quot;,
    &quot;502-3&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;408&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;410&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-33&quot;,
    &quot;502-4&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;409&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;411&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-32&quot;,
    &quot;502-5&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;410&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/602.png" alt="602"><span><b>602</b><small>热茶</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-32&quot;,
    &quot;502-5&quot;,
    &quot;601-4&quot;,
    &quot;602-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;411&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/706.png" alt="706"><span><b>706</b><small>贝类网</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 97<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 3</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;707&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-97&quot;,
    &quot;802-3&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;706&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/707.png" alt="707"><span><b>707</b><small>大贝类网</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 96<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;708&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-96&quot;,
    &quot;802-4&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;707&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/708.png" alt="708"><span><b>708</b><small>高级钓鱼冷却器</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 95<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;709&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-95&quot;,
    &quot;802-4&quot;,
    &quot;803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;708&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/709.png" alt="709"><span><b>709</b><small>鱼箱</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 94<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;710&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-94&quot;,
    &quot;802-5&quot;,
    &quot;803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;709&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/710.png" alt="710"><span><b>710</b><small>爱好者鱼缸</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 93<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;711&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-93&quot;,
    &quot;802-6&quot;,
    &quot;803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;710&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/711.png" alt="711"><span><b>711</b><small>豪华海鲜柜</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 92<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/901.png" alt="901"><span><b>901</b><small>鲑鱼片</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-92&quot;,
    &quot;802-7&quot;,
    &quot;803-1&quot;,
    &quot;901-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;711&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td>0</td><td>1</td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/901.png" alt="901"><span><b>901</b><small>鲑鱼片</small></span></span> × 96<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/902.png" alt="902"><span><b>902</b><small>蜂蜜釉面鲑鱼</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 10,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_Weight&quot;: [
    &quot;901-96&quot;,
    &quot;902-4&quot;
  ],
  &quot;SellingPrice&quot;: 3,
  &quot;Type&quot;: &quot;805&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;LevelDownPiece&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1208&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-35&quot;,
    &quot;1302-1&quot;,
    &quot;1401-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;1207&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 37<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1209&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-37&quot;,
    &quot;1302-1&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;1208&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 36<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1210&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-36&quot;,
    &quot;1302-2&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;1209&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1211&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-35&quot;,
    &quot;1302-3&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;1210&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1402.png" alt="1402"><span><b>1402</b><small>潜水护目镜</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-35&quot;,
    &quot;1302-3&quot;,
    &quot;1401-5&quot;,
    &quot;1402-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;1211&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 97<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 3<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1707&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-97&quot;,
    &quot;1802-3&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;1706&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 96<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 4<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1708&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-96&quot;,
    &quot;1802-4&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;1707&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 96<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1709&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-96&quot;,
    &quot;1802-3&quot;,
    &quot;1803-1&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;1708&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 95<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1710&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-95&quot;,
    &quot;1802-4&quot;,
    &quot;1803-1&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;1709&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 94<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1711&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-94&quot;,
    &quot;1802-5&quot;,
    &quot;1803-1&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;1710&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 93<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-93&quot;,
    &quot;1802-6&quot;,
    &quot;1803-1&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;1711&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr></tbody></table></div></div>


### GeneratorBoostItemModelConfig_shell / ExtraProduce（32 条）

来源：`Data.Config.GeneratorBoostItemModelConfig_shell`。仅在对应活动分组生效时替换母体配置，不能与默认配置累加。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 32 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>母体/棋子 ID<small style="display:block">Type</small></th><th>自动产出<small style="display:block">Spread_Auto</small></th><th>是否消耗能量<small style="display:block">Spread_CostEnergy</small></th><th>单轮次数上限<small style="display:block">Spread_ItemMaxNumber</small></th><th>单轮恢复（秒）<small style="display:block">Spread_ItemRecoveryDuration</small></th><th>单轮加速（宝石）<small style="display:block">Spread_ItemSpeedUpCost</small></th><th>储备次数上限<small style="display:block">Spread_StorageMaxNumber</small></th><th>储备恢复（秒）<small style="display:block">Spread_StorageRecoveryDuration</small></th><th>储备加速（宝石）<small style="display:block">Spread_StorageSpeedUpCost</small></th><th>普通产物 × 权重<small style="display:block">Spread_Weight</small></th><th>产出模式<small style="display:block">Spread_WeightType</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/105.png" alt="105"><span><b>105</b><small>轻篮</small></span></span></td><td>0</td><td>1</td><td>80</td><td>30</td><td>1</td><td>240</td><td>60</td><td>1</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 60,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;106&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 1,
  &quot;Spread_Weight&quot;: [
    &quot;201-35&quot;,
    &quot;202-2&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 1,
  &quot;Spread_ItemRecoveryDuration&quot;: 30,
  &quot;SellingPrice&quot;: 3,
  &quot;Type&quot;: &quot;105&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/106.png" alt="106"><span><b>106</b><small>重篮</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;107&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-35&quot;,
    &quot;202-1&quot;,
    &quot;203-1&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;106&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/107.png" alt="107"><span><b>107</b><small>篮筐推车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 34<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;108&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-34&quot;,
    &quot;202-2&quot;,
    &quot;203-1&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;107&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/108.png" alt="108"><span><b>108</b><small>轻便杂货车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;109&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-33&quot;,
    &quot;202-3&quot;,
    &quot;203-1&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;108&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/109.png" alt="109"><span><b>109</b><small>丰富商品杂货车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;110&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-32&quot;,
    &quot;202-4&quot;,
    &quot;203-1&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;109&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/110.png" alt="110"><span><b>110</b><small>满载杂货车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;111&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-32&quot;,
    &quot;202-3&quot;,
    &quot;203-2&quot;,
    &quot;301-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;110&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/111.png" alt="111"><span><b>111</b><small>双层豪华购物车</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/201.png" alt="201"><span><b>201</b><small>一袋面粉</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/202.png" alt="202"><span><b>202</b><small>一个面团</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/301.png" alt="301"><span><b>301</b><small>生土豆</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/302.png" alt="302"><span><b>302</b><small>切片土豆</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;201-32&quot;,
    &quot;202-3&quot;,
    &quot;203-2&quot;,
    &quot;301-4&quot;,
    &quot;302-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;111&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/405.png" alt="405"><span><b>405</b><small>普通咖啡壶</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 37<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;406&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-37&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 3,
  &quot;Type&quot;: &quot;405&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/406.png" alt="406"><span><b>406</b><small>咖啡壶套装</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 35<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;407&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-35&quot;,
    &quot;502-1&quot;,
    &quot;503-1&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;406&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/407.png" alt="407"><span><b>407</b><small>自动咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 34<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;408&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-34&quot;,
    &quot;502-2&quot;,
    &quot;503-1&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;407&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/408.png" alt="408"><span><b>408</b><small>工作咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;409&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-33&quot;,
    &quot;502-3&quot;,
    &quot;503-1&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;408&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/409.png" alt="409"><span><b>409</b><small>时尚浓缩咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;410&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-32&quot;,
    &quot;502-4&quot;,
    &quot;503-1&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;409&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/410.png" alt="410"><span><b>410</b><small>双杯浓缩咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;411&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-32&quot;,
    &quot;502-3&quot;,
    &quot;503-2&quot;,
    &quot;601-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;410&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/411.png" alt="411"><span><b>411</b><small>工业咖啡机</small></span></span></td><td>0</td><td>1</td><td>80</td><td>180</td><td>3</td><td>240</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/501.png" alt="501"><span><b>501</b><small>空咖啡杯</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/502.png" alt="502"><span><b>502</b><small>外卖咖啡</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/601.png" alt="601"><span><b>601</b><small>茶包</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/602.png" alt="602"><span><b>602</b><small>热茶</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 80,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;501-32&quot;,
    &quot;502-3&quot;,
    &quot;503-2&quot;,
    &quot;601-4&quot;,
    &quot;602-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;411&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 240
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/706.png" alt="706"><span><b>706</b><small>贝类网</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 97<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 3</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;707&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-97&quot;,
    &quot;802-3&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;706&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/707.png" alt="707"><span><b>707</b><small>大贝类网</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 96<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;708&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-96&quot;,
    &quot;802-4&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;707&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/708.png" alt="708"><span><b>708</b><small>高级钓鱼冷却器</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 95<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;709&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-95&quot;,
    &quot;802-4&quot;,
    &quot;803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;708&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/709.png" alt="709"><span><b>709</b><small>鱼箱</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 94<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;710&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-94&quot;,
    &quot;802-5&quot;,
    &quot;803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;709&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/710.png" alt="710"><span><b>710</b><small>爱好者鱼缸</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 93<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 6<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;711&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-93&quot;,
    &quot;802-6&quot;,
    &quot;803-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;710&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/711.png" alt="711"><span><b>711</b><small>豪华海鲜柜</small></span></span></td><td>0</td><td>1</td><td>26</td><td>180</td><td>3</td><td>78</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/801.png" alt="801"><span><b>801</b><small>生虾</small></span></span> × 92<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/802.png" alt="802"><span><b>802</b><small>鲜鱼</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/803.png" alt="803"><span><b>803</b><small>桶装鱼</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/901.png" alt="901"><span><b>901</b><small>鲑鱼片</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 26,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;801-92&quot;,
    &quot;802-7&quot;,
    &quot;803-1&quot;,
    &quot;901-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;711&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 78
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/805.png" alt="805"><span><b>805</b><small>处理过的海鲜</small></span></span></td><td>0</td><td>1</td><td>12</td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><span title="原始配置中不存在该字段">未配置</span></td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/901.png" alt="901"><span><b>901</b><small>鲑鱼片</small></span></span> × 96<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/902.png" alt="902"><span><b>902</b><small>蜂蜜釉面鲑鱼</small></span></span> × 4</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;BubbleChance&quot;: 10,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_ItemMaxNumber&quot;: 12,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_Weight&quot;: [
    &quot;901-96&quot;,
    &quot;902-4&quot;
  ],
  &quot;SellingPrice&quot;: 3,
  &quot;Type&quot;: &quot;805&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;LevelDownPiece&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1207.png" alt="1207"><span><b>1207</b><small>航海储物箱</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 1<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 5</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1208&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-33&quot;,
    &quot;1302-1&quot;,
    &quot;1401-5&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;1207&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1208.png" alt="1208"><span><b>1208</b><small>泳池玩具仓库</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 34<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 2<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1209&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-34&quot;,
    &quot;1302-2&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;1208&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1209.png" alt="1209"><span><b>1209</b><small>水上运动存储</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 33<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 3<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1210&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-33&quot;,
    &quot;1302-3&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;1209&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1210.png" alt="1210"><span><b>1210</b><small>游泳者储物柜</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 6</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1211&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-32&quot;,
    &quot;1302-4&quot;,
    &quot;1401-6&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;1210&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1211.png" alt="1211"><span><b>1211</b><small>大型泳池储物棚</small></span></span></td><td>0</td><td>1</td><td>36</td><td>180</td><td>3</td><td>108</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1301.png" alt="1301"><span><b>1301</b><small>橡胶鸭</small></span></span> × 32<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1302.png" alt="1302"><span><b>1302</b><small>花式鸭子</small></span></span> × 4<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1401.png" alt="1401"><span><b>1401</b><small>泳镜</small></span></span> × 5<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1402.png" alt="1402"><span><b>1402</b><small>潜水护目镜</small></span></span> × 1</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 36,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1301-32&quot;,
    &quot;1302-4&quot;,
    &quot;1401-5&quot;,
    &quot;1402-1&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;1211&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 108
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1706.png" alt="1706"><span><b>1706</b><small>国王珊瑚群</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 97<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 3<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1707&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-97&quot;,
    &quot;1802-3&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 4,
  &quot;Type&quot;: &quot;1706&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1707.png" alt="1707"><span><b>1707</b><small>珊瑚宝藏</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 94<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 6<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1708&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-94&quot;,
    &quot;1802-6&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 5,
  &quot;Type&quot;: &quot;1707&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1708.png" alt="1708"><span><b>1708</b><small>错综复杂珊瑚丘</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 92<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 7<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1709&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-92&quot;,
    &quot;1802-7&quot;,
    &quot;1803-1&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 6,
  &quot;Type&quot;: &quot;1708&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1709.png" alt="1709"><span><b>1709</b><small>海螺珊瑚</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 91<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 8<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 1<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1710&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-91&quot;,
    &quot;1802-8&quot;,
    &quot;1803-1&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 7,
  &quot;Type&quot;: &quot;1709&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1710.png" alt="1710"><span><b>1710</b><small>珍稀珊瑚</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 89<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 2<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;MergedType&quot;: &quot;1711&quot;,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-89&quot;,
    &quot;1802-9&quot;,
    &quot;1803-2&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 8,
  &quot;Type&quot;: &quot;1710&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1711.png" alt="1711"><span><b>1711</b><small>巨型蛤蜊珊瑚</small></span></span></td><td>0</td><td>1</td><td>42</td><td>180</td><td>3</td><td>126</td><td>300</td><td>5</td><td><div class="config-pool"><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1801.png" alt="1801"><span><b>1801</b><small>贝壳</small></span></span> × 88<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1802.png" alt="1802"><span><b>1802</b><small>普通扇贝</small></span></span> × 9<br><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span> × 3<br><span class="config-piece"><span><b>main_g_artifact_1</b><small>无本地视图映射</small></span></span> × 15</div></td><td>1</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;LevelDownPiece&quot;: 1,
  &quot;BubbleChance&quot;: 0,
  &quot;Rare&quot;: 1,
  &quot;Spread_Auto&quot;: 0,
  &quot;Spread_StorageRecoveryDuration&quot;: 300,
  &quot;Spread_ItemMaxNumber&quot;: 42,
  &quot;Spread_CostEnergy&quot;: 1,
  &quot;Spread_ItemSpeedUpCost&quot;: 3,
  &quot;Spread_Weight&quot;: [
    &quot;1801-88&quot;,
    &quot;1802-9&quot;,
    &quot;1803-3&quot;,
    &quot;main_g_artifact_1-15&quot;
  ],
  &quot;Spread_StorageSpeedUpCost&quot;: 5,
  &quot;Spread_ItemRecoveryDuration&quot;: 180,
  &quot;SellingPrice&quot;: 9,
  &quot;Type&quot;: &quot;1711&quot;,
  &quot;Spread_WeightType&quot;: 1,
  &quot;Spread_StorageMaxNumber&quot;: 126
}</pre></details></td></tr></tbody></table></div></div>


## 本逻辑使用的配表在哪里

- [Lucky 包内配置及活动变体](../../lucky/chance/load.md#configuration-lucky)：LuckyProduceModel:_LoadFileConfig → _GetLevelFitConfig → Try2ProduceLuckyItem；按 generator、等级区间选择记录，再用 lucky_chance 重装机会池。


<!-- generator-configs:end -->

<!-- source-links:start -->

## 对应源码

[ItemSpread.lua](../../../../assets/recovered-source/ItemSpread.lua) · [BoostChargeDiscoBoostHandler.lua](../../../../assets/recovered-source/BoostChargeDiscoBoostHandler.lua)

<!-- source-links:end -->
