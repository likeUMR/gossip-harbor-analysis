# 棋盘操作详细规格

这份规格是对 `BOARD_OPERATIONS_ANALYSIS.md` 的底层展开。阅读顺序是：玩家操作 -> 子流程 -> 伪代码 -> 配置字段 -> 状态和事件 -> 验收用例。

## 0. 覆盖边界

本规格覆盖主棋盘的三种操作：

- 棋子拖拽：移动、交换、特殊棋子影响、普通合成、吞噬。
- 母体点击：状态、空位、能量、Lucky、五类普通产出、增益、CD、落子和销毁。
- 订单提交：需求验证、奖励、棋子扣除、订单完成、补位和同步。

源码证据索引：

- [ItemSpread.lua](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua)
- [MainBoardModel.lua](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Board_MainBoardModel.lua)
- [BaseBoardModel.lua](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/014680c92d54a5137aca22bd58674db5e2f720b14f2dcf28cadc00d9d47defce.lua)
- [LuckyProduceModel.lua](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua)
- [BaseOrder.lua](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Order_BaseOrder.lua)
- [MainOrderModel.lua](C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/Board_Model_Order_MainOrderModel.lua)

## 1. 母体点击

### 1.1 完整时序

```text
ItemSpread:OnTap
  1. 计算本次点击循环次数
  2. CheckSpreadState
  3. CheckSpreadPosAndAuto
  4. CheckEnergy
  5. GenerateItemCode
     5.1 CheckLuckyProduce
     5.2 Disco 特殊产出
     5.3 _GenerateItemCode
     5.4 SpreadCheckEnergyRatioAndCode
     5.5 DealActivityLimit
     5.6 CosetRestNumber
     5.7 UpdatePerSecond / 保存棋子属性
  6. SpreadCostEnergy
  7. MainBoardModel:SpreadItem
  8. TryRemoveSelf
  9. TryUseCDBuff
```

关键点：能量检查发生在产出算法之前；产出算法可能决定代码和能量增益倍率，但不会绕过空位检查；落子完成后才扣除母体剩余次数。

### 1.2 状态机

| 状态 | 进入条件 | 点击结果 | 计时字段 |
|---|---|---|---|
| Initializing | `Spread_InitDuration` 存在 | 失败，非一次性报告 Recharging | `m_initDuration` |
| Closed | 只有 `Spread_OpenDuration` 的母体初始状态 | 失败，报告 ItemClosed | 无 |
| Opening | 调用 `OnOpen` | 失败，报告 ItemOpening | `m_openDuration` |
| Opened | 初始化/打开计时完成 | 允许产出；剩余数不足时启动恢复 | `m_itemRecoveryDuration` 或 `m_storageRecoveryDuration` |

`UpdatePerSecond` 以服务器时间计算 `elapsed / duration`，结果限制在 0 到 1。计时完成后，Initializing/Opening 转为 Opened；储备恢复分支补回 `m_itemRestNumber` 并减少 `m_storageRestNumber`。

### 1.3 空位算法

1. **手动点击（一次性和可恢复母体都相同）**：`CheckSpreadPosAndAuto` 调用 `FindEmptyPositionInSpreadOrder(sourcePosition)`，以母体为中心按方形环扫描，返回第一个合法空位。
2. **自动产出的一次性母体**：`FindSpreadPosition` 调用 `FindRandomPosition()`，从当前全盘空位集合中均匀抽取。
3. **自动产出的可恢复母体**：`FindSpreadPosition` 调用 `FindEmptyPositionInCircleOrder(sourcePosition)`，按八邻域顺序寻找。
4. 自动母体：没有落点时，一次性递减母体在 `AutoSpreadToCache` 开关开启时可把剩余代码放入缓存。
5. 主动点击若没有有效落点，触发 `SpreadFailed(BoardFull)`，不扣能量、不改次数。

`FindRandomPosition` 每次重新扫描当前空位并重新建立候选数组，不保存历史抽样；因此抽样本身是有放回语义，只有实际落子后该格才从下一次候选集合消失。

### 1.4 能量算法

```text
costEnergy = (Spread_CostEnergy == 1)
若 Disco 对当前母体生效，则 costEnergy = false
若不需要能量：返回 (true, 0, false)
读取 GetCostEnergyNum(itemType)
  -> 基础消耗 nCostNum
  -> 最大 EnergyBoost 倍率 nEnergyBoostRatio
余额不足：LackEnergy，停止
余额足够：允许产出
实际扣除 = EnergyBoostModel.GetBoostCostNum(energyBoostRatio)
```

`SpreadCostEnergy` 使用 `PropertyDataManager:Consume` 扣除主棋盘对应能量，并以 `EBIType.SpreadItem` 记录 BI。Lucky、Disco、GeneratorBoost 可能改变 `energyBoostRatio` 或 `costEnergy`，这些变化必须记录在运行时回放中。

### 1.5 Lucky：机会池和物品池是两套不同语义

#### 机会池

每种源母体类型独立保存两个数据库字段：

- `tl_<sourceType>`：当前周期剩余总机会。
- `ll_<sourceType>`：当前周期剩余 Lucky 机会。

```text
total = tl_<type> 或 0
lucky = ll_<type>
若 total == 0:
    total = config.lucky_chance[1]
    lucky = config.lucky_chance[2]
    保存 lucky
index = Random(1, total)       # 两端包含
hit = (index <= lucky)
若 hit:
    lucky = lucky - 1
    保存 lucky
若不是免费 Lucky:
    total = total - 1
    保存 total
```

这是等价于“有限数量成功签 + 普通签，不放回抽取”的计数器实现。它不是每次都用固定概率重新独立抽样。

#### Lucky 物品池

命中后从 `config.lucky_items` 调用 `Table.ListWeightSelectOne`。该调用只按累计权重选出一个对象，不删除对象、不减少 `Weight`，所以同一个 Lucky 物品可以在连续点击中再次出现。

Smart Produce 开启时，先根据订单缺口和能量增益等级，把符合条件的权重乘 `m_smartProduceRatio`，再进行一次累计权重抽样。

#### 免费和连续 Lucky

- 免费阈值队列存储在 `elpec`；每次能量段用 `MathUtil.RandomN(rangeSize, min(rangeSize, extra_lucky))` 生成不重复位置，排序后追加到队列。
- 免费 Lucky 消耗队首阈值，不减少 `tl_<type>`。
- 特殊模式使用 `clpit`、`clpmc`、`clpc`、`clpeet` 保存连续 Lucky 的目标类型、最大次数、当前次数和到期时间。
- `triple_lucky_chance` 先与 `Random(1,10000)` 比较；未命中才检查 `double_lucky_chance`。
- 连续 Lucky 有效期为服务器时间加 10 秒。

### 1.6 五类普通产出

| WeightType | 算法 | 候选是否变化 | 次数消耗 |
|---|---|---|---|
| Fixed | 固定产出模型；可被 SmartProduce 替换 | 配置不变 | 普通能量增益索引 |
| Decremental | 按权重抽取后 `Weight -= 1`，归零删除 | **变化；不放回权重单位** | 普通母体规则 |
| OrderItem | 订单缺口候选按 `min(DiffScore,300)` 加权，Boost 缺口乘 1000；失败候选删除后重试 | **候选不放回** | 选中代码对应权重 |
| ChestCustomItem | `GenerateChestCustomCodeRule` 生成代码，消耗该代码 DiffScore | 由箱子规则控制 | DiffScore |
| SmartItem | 取 DiffScore 不超过 `Spread_StorageMaxNumber` 的订单棋子，调用 SmartRewardHelper | 由辅助算法决定 | 选中 DiffScore 或 1 |

本地 `ItemModelConfig.json` 共 548 行，其中 163 行含 Spread 字段：Fixed 97、Decremental 54、OrderItem 6、ChestCustomItem 1、SmartItem 5。全部 Spread 行已经在现有配置索引中保留，不能只抽样说明。

### 1.7 次数扣除、变换和销毁

`CosetRestNumber` 先增加 `m_spreadCount`。一次性母体的默认扣除是 `floor(2 ^ energyBoostRatio)`；普通母体通过 `EnergyBoostModel:NextEnergyBoostCostIndex` 获取扣除量；OrderItem 使用命中代码的权重作为扣除量。

`TryRemoveSelf` 的顺序是：

1. 若 `m_transformNumber == m_spreadCount`，执行 ItemTransform，不删除母体。
2. 否则若剩余次数为 0 且母体不可恢复，删除棋子并发出 CollapseItem。
3. 其他情况保留母体。

## 2. 棋子拖拽和合成

### 2.1 拖拽分派顺序

```text
目标位置非法 -> 恢复原位
源位置对象不是拖拽对象 -> 恢复原位
目标为空 -> 移动、更新加速、ItemMoveEnd
CanItemAffect 成立 -> LevelUp/LevelDown 确认回调
CanItemMerge 成立 -> 合成
目标 ItemSwallow 可吞噬 -> Swallow
目标不可移动 -> 恢复原位
否则 -> 交换两个棋子
```

`CanItemMerge` 要求两个棋子类型相同，并且至少一个棋子的 `MergedType` 非空；若棋子带 ItemSpread 且一次性箱子已经使用过，也不能合成。

### 2.2 基础合成

基础实现位于 BaseBoardModel 的 `_DoMergeItem`，主棋盘通过 MainBoardModel 扩展。目标位置被替换为 `MergedType`，源棋子被移除，新棋子保存属性。随后发送：

- `BoardEventType.MergeItem`；
- `EEventType.ItemMerged`；
- 合成日志和活动监听。

`ItemGeneratorFactoryModel` 会监听 ItemMerged 并更新生成器工厂相关状态；ScoreRace 等活动也会在主棋盘扩展合成函数中得到合成分数。

### 2.3 合成副产物顺序

```text
新棋子生成
  -> TempItem.GenerateType
  -> CardItem.TryGenerateItem
  -> EnergyBubble.CanSpreadEnergyBubble
  -> _TrySpreadBubbleByMerge
  -> SystemConfig.SpreadCoinMinChainLevel 检查金币
```

前四种副产物通过 `hasCreateItem` 互斥；金币检查在互斥流程之后独立执行。每一步都必须有空位，否则跳过该副产物。

### 2.4 普通气泡的精确计算顺序

```text
若 Bubble 功能未开启：结束
p = newItem.BubbleChance
若已有相同 inner bubble：取消
否则若购买气泡加成成立：p = 100
否则若订单需求加成成立：p = 100
否则：
    p = p * 高等级棋子衰减
    p = p * 订单缺口衰减
    p = p * BubbleDecreaseModel 全局衰减
    p = max(p, 1)
若 TestBubbleMustSpread：p = 100
r = Random(100)
若 p >= r：生成 Bubble + newItem.Type
```

`BubbleChance` 是棋子自身的基础百分比；BubbleDecrease、订单衰减和购买加成的实际值可能来自服务端配置，必须在运行时配置快照中记录。

### 2.5 特殊棋子和吞噬

- LevelUp：确认后移除特殊棋子，将目标替换为目标的 MergedType。
- LevelDown：普通目标拆成两个前一级棋子；两个 LevelDown 目标会合并拆分使用次数。
- ItemSwallow：按两个 `Swallow_Weight` 生成目标代码，逐个吞噬后保存进度；两个目标的吞噬数量都达到配置值才 Transform。
- 吞噬批处理扫描有效棋盘位置，不随机打乱扫描顺序。

## 3. 订单提交

### 3.1 需求可交付判断

订单按钮调用 `GetCodeCountMap(true,false,false)` 后进入 `BaseOrder:CanDeliver`。对第 `i` 个需求，先统计该代码在前 `i` 项中出现了几次，再要求库存数量至少达到该出现次数。因此重复需求不会被集合去重。

### 3.2 奖励和扣除顺序

```text
MainBoardModel:FinishOrder
  -> Special/Branch 专用完成分支
  -> GetOrderRewardByFinishOrder
  -> 立即发放主奖励
  -> 发放亲密度礼物
  -> 发放 Buff 奖励
  -> OrderBoost / CookingFrenzy / ChestCustomer 副作用
  -> RemoveOrderRequirementItems
  -> 发放延迟奖励
  -> 所属订单模型 FinishOrder
  -> 补位、UpdateOrderState、OrderFinished
  -> 同步上传和 BoardEventType.FinishOrder
```

### 3.3 棋子移除

每个需求独立处理：

1. 按有效棋盘位置顺序找第一个相同代码。
2. 找到则 `RemoveItem(item)`，并记录 `RemovedFromBoard`。
3. 棋盘找不到才扫描仓库，移除第一个相同代码，记录 `RemovedFromInventory`。
4. 每项之后重新 `CountItemsCode` 和 `UpdateOrderState`。
5. 两处都找不到时记录 `FinishOrderRemoveItemError`。

### 3.4 订单完成后的 Lucky

`MainOrderModel:FinishOrder` 读取当前订单类型的 `LuckyTriggerChance`，调用 `MathUtil.Random()` 比较；订单已经标记为 Lucky 时直接允许连续触发。这个 Lucky 与母体产出的 LuckyProduce 是独立机制，不能共用同一个机会池。

## 4. 配置全量索引要求

本三类操作的配置入口至少包括：

- `ItemModelConfig`：548 行；其中 163 行为母体配置，370 行含 MergedType，138 行 BubbleChance 大于 0。
- `OrderItemConfig`：74 行，DiffScore 为 2 到 3000。
- `OrderFixedConfig`、`OrderRandomConfig`、`OrderRandomRecallConfig`：订单创建和刷新。
- `LuckyProduceConfig`：`lucky_chance`、`lucky_items`、`super_items`、等级区间。
- `SystemConfig`：`SpreadCoinMinChainLevel` 等全局开关。
- 服务端 GeneralConf：BubbleDecrease、FishNetProduceSmart、AdjustLuckyProduceBoostRatio 等。

服务端配置不能在本地文件缺失时默认为“不存在”；必须标记为“客户端代码存在、当前包体未提供实际值、需要运行时快照”。

## 5. 三类操作的验收矩阵

### 母体点击

- 五种 WeightType 各选一个完整生命周期。
- Lucky 机会池从初始化抽到 `total=0`，验证计数器递减。
- Lucky 物品连续抽样，验证配置权重不被删除。
- 普通、免费、Double、Triple Lucky 分别回放。
- Initializing、Closed、Opening、Recharging、BoardFull、LackEnergy 全部覆盖。
- EnergyBoost、GeneratorBoost、Disco、SmartProduce、FishNetProduceSmart 分别开关验证。
- 一次性母体耗尽、可恢复母体储备耗尽、TransformNumber 到达分别验证。

### 拖拽和合成

- 空位移动、普通交换、不可移动目标。
- 普通同类合成、不同类拖拽、已使用箱子合成。
- LevelUp、LevelDown、ItemSwallow。
- Temp、Card、EnergyBubble、Bubble、Coin 副产物逐项触发。
- 棋盘满时各副产物的跳过行为。
- 气泡基础概率、订单修正、购买修正、全局衰减和最低值修正。

### 订单提交

- 单需求、多需求、重复需求。
- 全部来自棋盘、全部来自仓库、棋盘和仓库混合。
- 不足需求、确认窗口、取消确认。
- 主奖励、延迟奖励、亲密度、Buff、OrderBoost、CookingFrenzy。
- Special、Branch、Lucky、Timed、Contiorder 等不同订单类型。
- 完成后补位、订单状态更新、事件和同步上传。

## 6. 当前验收状态

静态层面：入口、调用顺序、状态变化、随机语义和本地配置索引已建立。  
尚未达到最终运行时验收：服务端配置实际值、动态活动对象身份、异步回调时序、网络失败分支，以及原版与复刻版逐字段差分仍需第三阶段回放确认。
