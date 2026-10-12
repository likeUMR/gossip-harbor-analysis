# Fixed 的有限池、共享状态与重装

## 1. 决定使用哪个池

`ItemSpread:_GenerateItemCode` 先检查 `CanSupportGeneratorBoost` 和 GeneratorBoost SmartProduce Buff，或 `CanSupportSmart`。任一成立就调用 `RandomGenerateCodeHelper.TrySmartProduceItem`；返回非 nil 时使用智能结果并标记来源，不调用 `_FixedGenerateItemCode`。没有智能结果才回退普通池。GeneratorBoost 还可能检查额外普通产出。

智能选择先确认母体链存在于ItemSubChain映射；把母体配置候选按副链与其余主链分开（记录的主链ID为遍历到的最后一条非副链记录），没有副链候选或两链均无订单缺口时返回nil。然后深拷贝现有棋子计数，遍历非Finished订单，对需求调用同链合成缺口计算，消费的是临时库存；不删除实际棋子。有副链真实缺口时优先副链候选，命中后退出该订单的需求内循环；否则有主链缺口时选主链候选。在选定子列表内按原始Weight抽代码，算法不消耗Fixed类型池。订单采用pairs遍历；不能将其改写成“优先槽位1”。这里的Smart Buff只选主/副链，既不同于Lucky Smart倍率，也不同于SmartItem分值预算。

`_FixedGenerateItemCode` 有 ItemStateCollection 时使用 `GetStateType()`，否则使用母体类型。池由全局 `GM.ItemFixedSpreadModel` 按该键保存，不是每个母体的 `m_codeWeightPairs`。

## 2. 加载、迁移与配置变化

`_Try2InitSpreadWeight(type)`：内存池已存在且当前 `Spread_Weight_Str` 与新数据库 `pairs` 相同时直接复用。否则检查旧 FixedSpread 存档；旧表同时存在 `sequence` 与 `pairs` 时，把每个剩余序号按旧累计权重映射到 Code，统计每个 Code 的剩余份数，写入 FixedSpreadNew，再删除旧类型记录。

随后检查新表。`pairs` 缺失、`sequence` 缺失或配置字符串变化时，写入新配置，并把剩余池重装为整个配置。`_UpdateSpreadWeightInfo` 解析剩余字符串，重算 `m_mapLeftSpreadCount[type]`。配置变化因而可能重启周期，不能继续消费旧配额。

## 3. 抽取及持久化

`GenerateItemCode(type)` 按当前 `Weight` 总和调用 `Table.ListWeightSelectOne`，抽中记录 `Weight -= 1`，总剩余 `-= 1`。总剩余大于 0 时把剩余池串写到 `sequence`；否则 `_ResetSpreadWeightInfo` 从 `pairs` 补回整轮，再更新内存。零配额记录可以留在表内，但不会占正权重区间；Decremental 的实例池会在归零时删除记录。

| 状态 | 保存位置 | 作用域 |
|---|---|---|
| 当前配置字符串 | FixedSpreadNew[type].pairs | 池键对应的类型/状态类型 |
| 剩余权重字符串 | FixedSpreadNew[type].sequence | 同键共享并持久化 |
| 当前剩余记录与总量 | m_mapFixedSpreadWeight / m_mapLeftSpreadCount | 模型内存缓存 |

## 4. 随机与边界

`Table.ListWeightSelectOne` 求和后用 `MathUtil.Random(sumWeight)` 取 `1..sumWeight` 的含端点整数，按列表顺序减权重找累计区间。抽取本身不改池，扣配额由 Fixed 模型完成。权重展开后的每份配额在本轮不放回，轮末重装；不能称为独立同概率点击。

总权重不正时工具函数会记录断言，并可能在非中止日志环境下回退首项；不应自行补成另一个正常概率。正常配置应确保正总权重。随机底层使用 `math.random()`，种子与原版进程重建行为未确认。

**配表**：食品袋105的一轮为 `201×35、202×2、301×5`，共42份。**源码**：ItemFixedSpreadModel 的 GenerateItemCode / _Try2InitSpreadWeight / _ResetSpreadWeightInfo / _UpdateSpreadWeightInfo；ItemSpread 的 Fixed 分支与 `_FixedGenerateItemCode`。有限池与配置迁移为 `source-confirmed`；实际存档重登与动态分组为 `runtime-pending`。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-201.png" alt="普通产物 201" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页计算食品袋105的一轮份额怎样随抽取变化，以及另一只同类型食品袋为何接着消费同一池。

### 代入本页的值

源配置201×35、202×2、301×5，总42；演示抽样点20命中201，保存剩余串201×34、202×2、301×5，总41。下一次同类型食品袋按41份抽，201占34/41；轮末最后一份消费后立即重装35、2、5，共42份。数字对应本地配表，抽样点是演示输入。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [母体配置与包内变体](../../state/model/detail.md#configuration-item-model)：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。
- [Generator Boost 母体替换配置](../../overrides/activity/detail.md#configuration-generator-boost)：GeneratorBoostActivityModel:GetItemModelConfig → ReloadItemModelConfig；按 Buff 选择 MoreLuckyProduce / ExtraProduce 并替换 ItemDataModel 中的母体配置。


<!-- generator-configs:end -->
