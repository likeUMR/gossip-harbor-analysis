# 棋盘三类玩家操作：可复刻级静态分析

版本：Gossip Harbor 3.98.10  
分析范围：主棋盘上的母体点击/产出、棋子合成、订单交付。  
证据原则：下面写成“确定”的内容均能在已解密 Lua 反编译结果或本地配置中定位；服务端开关、动态对象身份和异步时序单独标为“运行时待确认”。机器可读入口索引见 [stage3_board_operation_manifest.json](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/stage3_board_operation_manifest.json)。

## 一、先给结论

1. **母体点击不是一次简单随机。** 入口 `ItemSpread:OnTap` 依次执行状态检查、落点检查、能量检查、产出模式选择、能量扣除、落子、消耗次数、CD/恢复处理。Lucky 发生在普通产出之前；一旦本次命中 Lucky，普通权重池不会再抽。
2. **Lucky 的“机会”是按棋子类型分开的配额抽样，属于无放回机会池。** 每个母体类型保存 `tl_<type>` 总机会和 `ll_<type>` 剩余 Lucky 机会；从 `1..总机会` 抽一个整数，命中 `index <= Lucky剩余` 后两个计数器相应递减。机会池耗尽后按配置重新装载。Lucky 物品本身再从 `lucky_items` 做一次累计权重抽样，但该配置项不会被删除，因此物品权重抽样是可重复的、有放回的。
3. **普通产出有五种权重模式。** Fixed、Decremental、OrderItem、ChestCustomItem、SmartItem 的代码路径不同，不能用一个“按权重随机”概括。Decremental 会抽中后减权，权重降为零就从池中移除；OrderItem 会反复抽候选订单代码，并把已尝试候选从候选表移除。
4. **合成完成后还有一串副作用。** 基础合成替换棋子并发出 `ItemMerged`，主棋盘随后按优先级尝试活动临时棋子、卡牌棋子、能量气泡、普通气泡，最后按系统配置的最小链等级喷一级金币；任一分支成功会抑制后续同类分支，但金币检查独立执行。
5. **订单交付先验证需求，再发奖励和移除需求棋子。** `CanDeliver` 对重复需求按出现次数计数；移除时每项优先从棋盘找一个匹配棋子，找不到才从仓库移除。随后订单标记完成、补位、更新订单状态并发出完成事件和同步上传。

## 二、操作一：点击母体棋子

### 2.1 触发链

核心链条是：

`ItemSpread:OnTap`（[ItemSpread.lua:132](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:132)）
→ `CheckSpreadState`（约 801 行）
→ `CheckSpreadPosAndAuto`
→ `CheckEnergy`
→ `GenerateItemCode`
→ `SpreadCostEnergy`
→ `MainBoardModel:SpreadItem`（[MainBoardModel.lua:238](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:238)）
→ `TryRemoveSelf`
→ `TryUseCDBuff`。

测试模式下 `TestSuperTap=1` 会把一次点击循环成 10 次，但教程棋盘强制仍为 1 次。正式复刻不应把这个测试开关当作正常规则。

### 2.2 点击前的失败条件

`CheckSpreadState` 将母体分为四种状态：Initializing、Closed、Opening、Opened。Closed 和 Opening 分别产生“未打开”和“正在打开”失败事件；Initializing 或剩余产出数为 0 时，非一次性母体进入恢复中并产生 Recharging 失败事件。随后 `CheckSpreadPosAndAuto`：自动产出母体若有自动落点，会直接走自动路径；普通点击找不到扩散位置则产生 BoardFull 失败事件。能量不足时不会扣除任何次数，主棋盘发出 LackEnergy。

### 2.3 普通产出五种模式

配置字段来自 `ItemModelConfig`。548 条物品配置中，163 条带 `Spread_*` 字段，权重模式计数为：Fixed 97、Decremental 54、OrderItem 6、ChestCustomItem 1、SmartItem 5。模式枚举和字段装载见 [ItemSpread.lua:1](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua:1) 和 `ItemSpread:Init`（约 21 行）。

**Fixed：** 优先检查 GeneratorBoost 的 SmartProduce 或 Smart Buff；若命中则由 `RandomGenerateCodeHelper.TrySmartProduceItem` 给出代码，否则交给 `ItemFixedSpreadModel:GenerateItemCode`。Fixed 本身的候选表在另一份固定产出配置中，不能从 `Spread_Weight` 推断。

**Decremental：** `Table.ListWeightSelectOne(self.m_codeWeightPairs).Code` 做一次累计权重抽样；找到对应项后 `Weight -= 1`，降到 0 就 `table.remove`。因此它是“带权的有限库存”：同一份母体实例内不会无限重复某个权重单位，且每次抽样会改变后续概率。剩余项会通过 `GetAutoSpreadDecrementalRemainTypes` 展开成代码列表，用于自动产出塞入缓存。

**OrderItem：** 先由 `CalculateOrderCodeLackNumMap(false,true,false)` 得到订单缺口，只考虑主棋盘，不把仓库计入缺口；候选权重是 `min(DiffScore, 300)`，属于 OrderBoost 缺口的候选权重再乘 1000。每次 `ListWeightSelectOne` 后立刻 `Table.ListRemove` 已尝试项，调用 `_TryGenerateItemCodeByOrderItem` 找同链且低于目标等级的母体产出；失败就继续下一个候选，全部失败才退回 `_TryGenerateItemCodeAll`。这条路径明确是“候选不放回，直到找到可生成目标”。

**ChestCustomItem：** 调用 `RandomGenerateCodeHelper.GenerateChestCustomCodeRule`，以当前剩余分值/数量生成一个订单箱棋子；生成失败硬回退到代码 `205` 并记录错误。消耗量取该代码在 `OrderItemConfig` 中的 `DiffScore`，不是固定扣 1。

**SmartItem：** 首次使用时收集 `OrderItemConfig` 中 `DiffScore <= Spread_StorageMaxNumber` 的候选，交给 `SmartRewardHelper.GetCodesFor_ItemSpread` 根据剩余次数和分值组合选择；代码没有在此处修改权重池，但消耗次数按选中候选的 DiffScore 记账。

### 2.4 Lucky 机制：两层随机、两种“放回”语义

`ItemSpread:CheckLuckyProduce`（约 585 行）先排除教程棋盘和 Disco；再调用 `LuckyProduceModel:Try2ProduceLuckyItem`。该模型必须处于 Started，且源母体类型必须匹配当前等级配置。

**机会层：**

```text
total = DB["tl_" .. sourceType] 或 0
lucky = DB["ll_" .. sourceType]
若 total == 0：total = lucky_chance[1]，lucky = lucky_chance[2]，写回 lucky
index = Random(1, total)       -- 两端包含
命中 = (index <= lucky)
命中时 lucky -= 1
非免费时 total -= 1
```

这等价于在一个大小为 `total`、其中有 `lucky` 个成功签的袋子里抽签后不放回；但实现没有保存签本身，而是保存两个计数器。`total` 和 `lucky` 均按源母体类型分开存储。免费 Lucky 发生时不扣 `total`，只消耗免费机会队列中的第一个能量阈值。

**物品层：** 命中后从 `config.lucky_items` 用 `Table.ListWeightSelectOne` 抽一个 `Item`。这里不会删除候选，也不会递减 `Weight`，所以连续 Lucky 的物品选择是有放回的累计权重抽样。若 Smart Produce 开启，先把满足订单缺口和能量增益等级的候选权重乘 `m_smartProduceRatio`，再抽样。

**连续 Lucky：** 特殊配置按能量消耗区间选当前段；先用 `Random(1,10000)` 检查 triple，再用第二次 `Random(1,10000)` 检查 double。命中后写入 `clpit/clpmc/clpc/clpeet`，有效期为服务器时间 + 10 秒。后续同源母体点击会直接走 DoubleLucky 或 TripleLucky 分支。

**免费 Lucky 队列：** 每个能量段用 `MathUtil.RandomN(rangeSize, min(rangeSize, extra_lucky))` 生成互不重复的区间位置，排序后存入数据库；能量累计达到队首位置才免费。这里是明确的无放回抽样，且抽出的阈值会从队列删除。

### 2.5 能量、增益和 CD

`CheckEnergy` 先看母体是否消耗能量；Disco 可把本次消耗改为 0。若需要能量，`ItemSpread.GetCostEnergyNum` 根据 EnergyBoost 状态给出基础消耗和最大增益倍率，余额不足则停止整个点击。成功后 `SpreadCostEnergy` 使用 `EnergyBoostModel.GetBoostCostNum(energyBoostRatio)` 扣除能量。

产出代码还会执行 `SpreadCheckEnergyRatioAndCode`：根据订单缺口、现有奇偶数量和链最大等级，决定把基础代码沿合成链提升几级；鱼网链在服务端开关 `FishNetProduceSmart` 打开时还有“刚好补齐二进制缺口”的特殊修正。

点击成功后，`CosetRestNumber` 增加 `m_spreadCount` 并扣剩余次数。一次性母体扣除 `floor(2^energyBoostRatio)`；普通母体走 `EnergyBoostModel:NextEnergyBoostCostIndex`；OrderItem 按被选代码的权重扣除。次数为 0 且不可恢复时，`TryRemoveSelf` 从棋盘删除母体并发出 CollapseItem。

CD 使用服务器时间戳 `m_startTimer`。Initializing、Opening、Opened+剩余次数不足或储备为 0 时启动计时；计时结束后打开母体或把储备次数补回。`TryUseCDBuff` 只在剩余次数为 0 且 CD Buff、GeneratorBoost NoCD 或测试免 CD 条件成立时跳过恢复时间。SpeedUp 会按剩余比例向上取整，最少消耗 1 钻石，并记录 BI。

## 三、操作二：合成

### 3.1 拖拽入口与优先级

主棋盘入口为 `MainBoardModel:DragItem`（[MainBoardModel.lua:282](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:282)）。顺序是：

1. 目标位置是否合法；源位置仍是否为该棋子。
2. 目标为空：移动棋子，更新加速状态，发出 `ItemMoveEnd`。
3. 特殊棋子 LevelUp/LevelDown 是否能影响目标；能影响则弹确认窗，回调中再次检查。
4. `CanItemMerge`：两棋子类型相同且至少一个有 `MergedType`，且未使用过的一次性箱子不能再合成。
5. 目标有 `ItemSwallow` 且允许吞噬：走吞噬进度逻辑。
6. 目标不可移动则失败；否则交换两个棋子位置。

### 3.2 基础合成与事件

合成将目标位置替换为 `MergedType`，源棋子被移除，生成新棋子并保存属性；主棋盘发出 `BoardEventType.MergeItem` 和全局 `EEventType.ItemMerged`。`ItemGeneratorFactoryModel`、教程、ScoreRace 等监听这个事件，因此“合成完成”并不等于逻辑结束。

### 3.3 合成后的副产物优先级

`MainBoardModel:_DoMergeItem`（[MainBoardModel.lua:445](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:445)）在新棋子生成后按以下顺序处理：

- TempItem 活动临时棋子；成功后停止本轮副产物竞争。
- CardItem 活动卡牌棋子；成功后停止本轮副产物竞争，并发 `CardItemGenerate`。
- EnergyBubble 活动能量气泡；成功后停止本轮副产物竞争。
- 普通气泡：先取新棋子的 `BubbleChance`，叠加订单缺口、购买气泡、BubbleDecrease 等修正，最终至少保留 1%，再与 `Random(100)` 比较。
- 金币：若新棋子链等级达到 `SystemConfig.SpreadCoinMinChainLevel`，且棋盘仍有空位，再独立喷出 `Coin01`。

因此复刻时不能把“合成奖励”实现成单一 if/else：前四类副产物互斥，但金币检查在后面单独执行。棋盘满会阻止需要新位置的副产物。`ItemSwallow` 则按两个吞噬目标的 `Count` 逐个累计，满足全部数量才 Transform；批量点击会扫描有效棋盘位置并按配置顺序收集目标。

## 四、操作三：订单交付

### 4.1 UI 点击到模型

订单按钮入口为 `BaseOrderCell:OnGoButtonClicked`（[BaseOrderCell.lua:21](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_View_Order_BaseOrderCell.lua:21)）：播放交付音效，读取棋盘 `GetCodeCountMap(true,false,false)`，调用 `order:CanDeliver`。不足时打开使用库存物品确认窗；足够时直接 `boardModel:FinishOrder(order)`。

`CanDeliver`（[BaseOrder.lua:112](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua:112)）逐项检查需求。重复需求按在列表中出现的次数计数，例如 `[203,203]` 要求数量至少为 2；返回值还包含每种缺口数量。

### 4.2 完成交付的状态和奖励顺序

`MainBoardModel:FinishOrder`（[MainBoardModel.lua:1101](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua:1101)）执行：

1. Special/Branch 订单先转专用完成逻辑。
2. 计算并深拷贝主奖励和延迟奖励，立即 `RewardApi.AcquireRewardsLogic`。
3. 发放亲密度礼物、Buff 奖励。
4. 处理 OrderBoost 微笑分、CookingFrenzy 奖励、ChestCustomer 完成事件。
5. `RemoveOrderRequirementItems` 按订单需求逐项移除：先遍历棋盘，找不到再遍历仓库；每移除一项都重新统计棋子和订单状态。
6. 发放延迟奖励。
7. 找到所属订单模型，调用 `SlotOrderModel:FinishOrder`：置为 Finished、写 BI、填充空缺订单、发出 `OrderFinished`。
8. 更新订单状态；必要时发出 SmileOrderDeliver_1；检查同步上传；发出 `BoardEventType.FinishOrder`，消息包含被移除棋子和奖励明细。

订单模型在启动和每次完成后按固定、回归免费、教程、连续订单、额外顾客、Lucky、随机的顺序尝试补位。随机订单配置来自 `OrderFixedConfig`、`OrderRandomConfig`、`OrderItemConfig` 及其变体；当前本地 `OrderItemConfig` 有 74 行，`DiffScore` 范围 2 到 3000。具体订单创建仍受等级、活动、服务端配置影响，必须在运行时回放中记录实际命中的 creator。

### 4.3 交付后 Lucky 订单触发

`MainOrderModel:FinishOrder`（[MainOrderModel.lua:560](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua:560)）在普通订单完成后读取对应 `OrderRandomConfig` 的 `LuckyTriggerChance`，调用 `MathUtil.Random()` 与概率比较；订单自身已标记 Lucky 时直接允许连续触发。该标志随后影响下一轮订单创建，不等同于母体产出 Lucky。

## 五、复刻实现时必须保留的状态变量

| 子系统 | 必须持久化/可重放状态 |
|---|---|
| 母体产出 | state、startTimer、itemRestNumber、storageRestNumber、spreadCount、递减权重表 |
| Lucky | `tl_<type>`、`ll_<type>`、连续 Lucky 四个键、免费阈值队列、特殊模式能量累计 |
| 棋盘 | 每格 item code/id/property、缓存区、仓库、订单缺口映射 |
| 订单 | requirements、fill states、state、slot、id、Lucky/Baseline 标志、难度累计分、重复链权重衰减 |
| 活动 | Temp/Card/EnergyBubble/BubbleSale/OrderBoost/CookingFrenzy/GeneratorBoost 的当前开关和计数 |

## 六、目前能否称为“完成”

这份结果已经达到**静态代码和本地配置的可复刻说明**：入口、调用顺序、状态变化、随机算法、无放回/有放回边界和主要副作用均已落到源码位置。仍不能把它称为最终运行时验收完成，原因是：

- Lucky、GeneratorBoost、BubbleDecrease、FishNetProduceSmart 等开关可能由服务端下发；
- `self.m_itemModel`、动态活动模型和继承方法的实际对象身份需要运行时确认；
- 动画、协程、网络返回、失败重试的时间顺序不由静态 Lua 单独证明；
- 订单 creator 的实际选择依赖账号等级和活动状态。

第三阶段验收应至少用固定棋盘快照回放：每种母体权重模式各抽取完整生命周期；Lucky 机会池跑到耗尽并检查计数器；CD 从初始、打开中、耗尽、加速、Buff 免 CD 五种状态分别点击；合成覆盖普通、棋盘满、四种副产物和特殊棋子；订单覆盖重复需求、棋盘/仓库混合扣除、奖励失败和补位。每条回放都保存输入、随机数、状态快照、事件顺序、网络请求和 UI 状态，并与复刻版逐字段比较。
