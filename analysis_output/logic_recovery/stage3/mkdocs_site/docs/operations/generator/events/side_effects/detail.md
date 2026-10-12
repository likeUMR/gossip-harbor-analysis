# 落子通知后的 GeneratorBoost 追加产出

追加产出发生在已生成的棋子通知中，不能当成Super Lucky额外的奖池。GeneratorBoostActivityModel在Init注册EEventType.ItemSpread、Destroy移除自己全部监听；_OnItemSpread首先确认Source有ItemSpread且CanSupportGeneratorBoost。

## 1. 普通双倍资格先算，复制后落

Fixed分支调用TryExtraProduceItem：ExtraProduce Buff有效且配置存在才继续。有ExtraProduceCached标记时优先消费缓存资格，不再抽资格；否则按剩余机会总数T、双倍配额L抽1..T，T减1，抽到≤L时L减1；T为0才装填配置新周期。这是另一个有限配额池。

随后要求母体附近至少两个空位：够用时缓存资格移除，外层标记GeneratorBoostExtraNormal或GeneratorBoostExtraSmart；不够时将资格记为一个布尔缓存标记，外层不标双倍。多个不足时的资格不会作为整数累积。

主物品落下后，_OnItemSpread看到上述双倍来源类型，调用_ExtraProduceItemSpread。ItemLandOpt开启用物品相关落点，否则用扩散顺序空位；再找不到位置时不落追加件，本函数不重新缓存。复制的是message.New的实际代码，不再抽物品，不再次扣母体次数；追加args沿用能量指数、costEnergy=false、类型GeneratorBoostExtra。

## 2. Lucky 追加复制

主类型为Lucky、SuperLucky、FreeLucky或FreeSuperLucky才进入TryExtraLuckyProduceItem；本监听条件不包括DoubleLucky和TripleLucky1/2。ExtraLuckyProduce Buff有效时，从母体位置找一个扩散空位；有位置则复制message.New代码，costEnergy=false，类型GeneratorBoostExtraLucky；无位置本方法不落子也不写缓存。

资格阶段的HaveAndCanExtraLuckyProduce是另一方法：检查至少两个空位，可能保存/消费ExtraLuckyProduceCached；不能把这个缓存逻辑写成TryExtraLuckyProduceItem内部行为。追加件类型与监听触发类型不同，所以这些分支不会把自己无限递归复制。

## 3. 记录信息与其它监听

主普通代码改写链可返回原始代码和FishNet扩展场景；落子日志使用eb、md、st、oriEle、sc等字段，GeneratorBoost活动文本为ab。不能仅凭“Lucky”就写成通用活动进度必加1，各活动消费者有自己的条件；气泡及其它活动监听必须另按实际注册方法追溯。

**证据**：GeneratorBoostActivityModel Init、Destroy、_OnItemSpread、TryExtraProduceItem、_CanExtraProduceItem、_ExtraProduceItem、_ExtraProduceItemSpread、TryExtraLuckyProduceItem、HaveAndCanExtraLuckyProduce及缓存方法。活动配置由账号/活动来源决定，具体开关和周期数不能用假设数代替。

---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：食品袋105主例未开启追加Buff，没有第二件。独立Lucky追加对照说明活动监听复制已落下的物品，不重抽Super资格。

### 代入本页的值

对照假设Source支持GeneratorBoost、ExtraLuckyProduce Buff有效，主事件BoardSpreadType=SuperLucky、New代码205、EnergyBoostRatio=0，还有一个扩散空位Q：复制205到Q，追加类型GeneratorBoostExtraLucky，costEnergy=false。改为TripleLucky1时本监听不进入；改为空位不足时本方法不复制。主分类和Buff是对照输入，没有凭空写活动进度+1。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
