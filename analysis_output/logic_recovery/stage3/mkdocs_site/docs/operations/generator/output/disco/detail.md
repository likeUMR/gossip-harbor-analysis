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

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- source-links:start -->

## 对应源码

[ItemSpread.lua](../../../../assets/recovered-source/ItemSpread.lua) · [BoostChargeDiscoBoostHandler.lua](../../../../assets/recovered-source/BoostChargeDiscoBoostHandler.lua)

<!-- source-links:end -->
