# 订单提交：可复刻级调用链与配置审计

版本：Gossip Harbor 3.98.10（当前已恢复客户端样本）  
机制编号：`BOARD.ORDER.DELIVERY.001`  
证据范围：已解密 Lua、Lua 字节码反汇编、本地 JSON 配置。  
证据标记：`source-confirmed` 表示代码或配置直接确认；`runtime-pending` 表示依赖实际活动/账号/服务端状态；`unavailable` 表示当前样本没有客户端实现。

## 1. 结论摘要

一次点击订单交付按钮包含两个不同层面的逻辑：普通订单先在 UI 入口检查库存，成功后进入主棋盘的奖励、扣除、完成、补位和事件链；特殊订单和分支订单在同一个入口分流到专用完成逻辑，不走普通奖励路径。订单“可交付”只由棋盘统计传入的代码数量决定，按钮本身不会把仓库数量并入第一次检查；库存不足时才打开使用库存物品确认窗口。

普通订单的成功链是：

```text
BaseOrderCell:OnGoButtonClicked
  -> GetCodeCountMap(true, false, false)
  -> BaseOrder:CanDeliver
  -> MainBoardModel:FinishOrder
     -> GetOrderRewardByFinishOrder / GetRewards
     -> 发放普通、礼物、Buff 奖励
     -> OrderBoost / CookingFrenzy / ChestCustomer 副作用
     -> SetFinished
     -> RemoveOrderRequirementItems
     -> 发放延迟奖励
     -> 所属 OrderModel:FinishOrder
        -> 写完成日志、补位、OrderFinished 事件
     -> UpdateOrderState
     -> 同步上传检查、棋盘 FinishOrder 事件
```

源码不会在 `OnGoButtonClicked` 内再次判断订单是否仍属于当前模型；`MainBoardModel:FinishOrder` 的普通分支也没有显式再次调用 `CanDeliver`。因此复刻实现应在入口和模型边界分别提供并发/重复点击保护，实际客户端是否依靠按钮禁用或单线程事件顺序避免竞态，需要运行时确认（`runtime-pending`）。

## 2. 玩家点击入口

### 2.1 普通订单按钮

证据：`Board_View_Order_BaseOrderCell.lua:22-33`。

执行顺序：

1. 如果 `m_bGoButtonEnabled == false`，立即返回；不播放音效，不读取棋盘，不打开窗口。
2. 播放 `sfxOrderServe`。
3. 通过 `m_orderArea -> BoardView -> GetModel()` 取得当前棋盘模型。
4. 调用 `boardModel:GetCodeCountMap(true, false, false)`，得到传给订单检查的代码数量映射。
5. 调用 `m_order:CanDeliver(codeCountMap)`。
6. 返回真时调用 `boardModel:FinishOrder(m_order)`。
7. 返回假时调用 `GM.UIManager:OpenView(UseInventoryItemConfirmWindow, boardModel, m_order)`，进入“使用仓库物品补交”窗口；该窗口后续是否允许直接消耗仓库、如何再次确认，属于另一条 UI 子链，当前入口文件只确认了窗口参数。

`MainOrderCell:OnGoButtonClicked` 只在特殊订单子类中覆写（`Board_View_Order_MainOrderCell.lua:536-542`）：按钮门控和音效相同，但不检查需求，直接打开 `SpecialOrderItemWindow`。这不是普通交付成功；特殊窗口中的操作需要单独追踪。

### 2.2 入口之外的显示逻辑不等于交付逻辑

`BaseOrderCell:Init`（`BaseOrderCell.lua:41-58`）只负责绑定订单、更新头像/需求/奖励和按钮位置；`_UpdateReward`、`_SplitRewards`（`145-211`）负责预览奖励，不会发放资源。页面上出现“可交付”按钮由 `OnOrderStateChanged`（同文件约 `532-545`）根据 `OrderState.CanDeliver` 控制。显示为可交付不构成服务器或模型提交成功的证明。

## 3. 需求检查：`CanDeliver` 的精确算法

### 3.1 订单对象初始化和状态

`BaseOrder:Init`（`Board_Model_Order_BaseOrder.lua:23-39`）遍历传入的需求数组，跳过空字符串；保留其余顺序，并为每项建立一个 `false` 的填充状态。没有需求时状态为 `Dormant`，否则为 `Init`。

订单状态枚举（同文件 `1-12`）：`Dormant=0`、`Init=1`、`PartiallyFinished=2`、`CanDeliver=3`、`Finished=4`。`_SetState`（`69-80`）记录状态升降方向和服务器时间；普通 `SetFinished`（`130-135`）直接写 `Finished`，不经过 `_SetState`，因此完成状态不会更新 `m_stateChange`。

### 3.2 重复需求不是去重集合

`BaseOrder:CanDeliver`（`112-128`）逐项扫描需求。对第 `i` 项，先从 `i-1` 向前数相同代码出现次数，得到该项在需求列表中的序号 `count`；然后要求 `codeCountMap[requirement] >= count`。因此需求 `[203,203,204]` 的门槛是 203 至少 2 个、204 至少 1 个，而不是只要求每种代码出现一次。

失败时返回 `false, lackedCodeCountMap`。缺口按代码聚合写入 `count - (当前数量或0)`；同一代码的后续重复项会覆盖为更大的缺口值，结果等价于最终所需总数减去当前数量。入口只使用第一个布尔返回值，缺口映射由库存确认窗口继续使用。

### 3.3 `UpdateState` 与交付检查的关系

`BaseOrder:UpdateState`（`82-110`）使用同一套重复计数，写入每项 `m_requirementFillStates`，并根据已满足项数设置订单状态。`BaseOrderModel:UpdateState`（`Board_Model_Order_BaseOrderModel.lua:30-48`）再把所有未完成订单中已满足的代码汇总到 `codeStateMap`，用于棋盘提示和 UI。它不会扣除物品，也不会把仓库加入数量；交付扣除发生在后面的 `RemoveOrderRequirementItems`。

## 4. 普通订单完成链

### 4.1 入口分流

`MainBoardModel:FinishOrder`（`Board_Model_Board_MainBoardModel.lua:1101-1108`）先按 `order:GetInnerType()` 分流：

| 类型 | 行为 | 证据 |
|---|---|---|
| `MainOrderType.Special` | `_FinishSpecialOrder`，立即返回 | `MainBoardModel.lua:1102-1104` |
| `MainOrderType.Branch` | `_FinishBranchOrder`，立即返回 | `MainBoardModel.lua:1105-1107` |
| 其它主订单 | 进入普通奖励、扣除、补位链 | `MainBoardModel.lua:1109-1162` |

这意味着特殊/分支订单不会执行普通订单的 `GetOrderRewardByFinishOrder`、亲密度礼物、普通需求逐项扣除或普通 `OrderFinished` 事件链；它们有专用的批量清除和奖励逻辑（见第 8 节）。

### 4.2 普通奖励快照与发放顺序

普通分支首先调用 `order:GetOrderRewardByFinishOrder()`，随后对两个返回值 `DeepCopy`（`MainBoardModel.lua:1109-1112`）。这样后续异步或活动代码改变原订单对象时，本次完成事件仍携带完成瞬间的奖励快照。

接着按以下顺序发放：

1. `targetRewards` 通过 `RewardApi.AcquireRewardsLogic(rewards, Give, FinishOrder, gameMode, Type2)` 发放。
2. `order:GetGiftRewards()` 非空且 `CharacterIntimacyModel:IsOpen()` 时发放亲密度礼物（无 `CacheItemType.Type2` 参数）。
3. 如果订单实现了 `GetBuffRewards`，取得 Buff 奖励；非空即发放。
4. 处理 OrderBoost 分数和标记（下一小节）。
5. `order:SetFinished()` 缓存订单最终奖励并写完成状态。
6. 扣除需求棋子。
7. 尝试 `TryAcquireCookingFrenzyReward(order)`。
8. ChestCustomer 订单发出 `ChestCustomerOrderFinish`。
9. 遍历延迟奖励映射，逐组调用 `AcquireRewardsLogic`。

奖励生成本身在 `MainOrder:GetRewards`（`Board_Model_Order_MainOrder.lua:136-254`），并非在 FinishOrder 内临时拼装。订单完成后再次读取奖励会命中 `m_cacheRewards`（`136-139`）。

### 4.3 订单价格和金币奖励

`MainOrder:GetPrice`（`110-126`）逐个需求代码查 `MainOrderModel:GetItemCodeConfigMap()`；缺少配置时记录 `cfg_err` 并返回 0。普通订单用 `OrderItemConfig.Price` 相加；仅当 `m_bIsBaseline` 且该条配置有 `RecommendedPrice` 时改用 `RecommendedPrice`。重复需求会重复加价。

`GetRewards` 在最后阶段（`242-253`）决定是否发金币：

- `_HasGoldReward`（`106-108`）对 `CharacterIntimacyRandom` 且亲密度开放的订单返回假，其余返回真。
- 基础数量为 `ceil(price * nMultiple)`。
- `BuffGold` 生效时 `nMultiple=2`，否则为 1。
- 属性类型由 `GetFirstRewardPropertyType`（`337-342`）选择：非 Special 且 BakeOut 可领取代币时为 `BakeOutToken`，否则为 `Gold`。
- 写入 `PROPERTY_CRYPT = Crypt.CryptCurrency(count)`。

### 4.4 活动奖励的逐项来源

`MainOrder:GetRewards` 的代码顺序就是奖励列表追加顺序。以下活动返回非空/正值时追加一项：

1. 主装饰活动：`GetMainOrderCoinToEventToken(price, diffScore)`（`147-157`）。
2. FloatRace：`GetAddScoreByOrder`（`158-163`）。
3. TimedOrder 专属 `GetTimedOrderRewards`；若其中已有相册缓存道具，设置 `skipAlbumReward`（`165-173`）。
4. Album：`GetMainOrderScore2AlbumPack(diffScore, slot 或 orderType+innerType, true)`；相册 Buff 可将数量乘 2（`174-185`）。
5. Avenue、Upward、Road、HitBricks、Ring、Combo：依次调用各自 `GetAddScoreByOrder`，分别见 `187-231`。
6. `ActivityModuleManager:GetRewardsByOrder` 追加整个数组（`233-234`）。
7. ChestCustomer 订单追加键为 `RewardKey .. innerType .. "_" .. slot`、数量 1 的延迟奖励标记（`235-240`）。
8. 最后追加金币或 BakeOutToken（`242-253`）。

`GetOrderRewardByFinishOrder`（`257-271`）把 ChestCustomer 键前缀的奖励从即时目标奖励中分离到 `otherMapReward[ChestCustomerModel.RewardKey]`；普通奖励列表与延迟映射因此不是同一组。

## 5. 需求扣除：棋盘优先、仓库兜底

### 5.1 算法

`MainBoardModel:RemoveOrderRequirementItems`（`Board_Model_Board_MainBoardModel.lua:1164-1200`）按 `order:GetRequirements()` 原始顺序逐项执行：

1. 从 `GetValidPositionIterator()` 的固定棋盘遍历顺序开始。
2. 读取每格 `GetItem(position)`；第一个 `item:GetCode() == requirement` 的棋子调用 `RemoveItem(item, false)`。
3. 若棋盘遍历没有找到，按仓库索引 `1..ItemStoreModel:GetItemCount()` 扫描；第一个代码匹配的物品调用 `RemoveItem(j)`，再调用 `_RemoveItemProperty(item)`。
4. 每项扣除后调用 `CountItemsCode()` 和 `UpdateOrderState()`，因此后续需求看到的是实时数量；重复需求会逐个扣除不同实例。
5. 两处都找不到时记录 `FinishOrderRemoveItemError`，但代码不会抛出异常或回滚前面已发放的奖励/已扣除项目。
6. 返回 `{RemovedFromBoard=..., RemovedFromInventory=...}`；棋盘列表保存实际物品对象，仓库列表保存需求代码字符串。

参数语义在模型代码中已直接确认：`BaseBoardModel:GetCodeCountMap`（`014680...lua:507-518`）默认/按 `includeBoard` 加入棋盘；`BaseActionBoardModel:GetCodeCountMap`（`Board_Model_Board_BaseActionBoardModel.lua:136-150`）只有 `includeCache ~= false` 才加入缓存；`MainBoardModel:GetCodeCountMap`（`Board_Model_Board_MainBoardModel.lua:187-202`）只有 `includeStore ~= false` 才加入仓库。因此入口的 `(true,false,false)` 明确表示“棋盘计数 + 不含缓存 + 不含仓库”。这解释了为什么库存不足时才打开确认窗口；扣除函数随后仍会按棋盘优先、仓库兜底执行。当前仍需运行时确认确认窗口是否重新计算数量，以及库存扣除后的网络/动画时序。

### 5.2 非原子失败边界

奖励发放发生在需求扣除之前（`MainBoardModel.lua:1112-1123` 对比 `1135-1137`）。如果扣除阶段发生异常或找不到某项，代码只记录 BI 错误，不撤销奖励；复刻时必须保留该顺序，并单独实现幂等/回滚策略是否存在的验证记录，不能假设事务性。

## 6. 订单完成、补位与事件

### 6.1 所属模型完成

普通主棋盘完成后遍历 `self.m_orderModels`，找到包含该订单的模型并调用其 `FinishOrder`（`MainBoardModel.lua:1145-1150`）。`SlotOrderModel:FinishOrder`（`Board_Model_Order_SlotOrderModel.lua:65-74`）依次：

1. `ContainsOrder` 失败返回 `false`，不会完成或补位。
2. `order:SetFinished()`。
3. `_LogOrderAction(order,"finish")`：按订单类型写 fixed/random/special，并将需求数组聚合为代码计数。
4. `_TryFillOrders()`：清除已完成槽位、尝试创建新订单、写数据库。
5. 派发 `EEventType.OrderFinished`，参数为 `{order=order}`。

注意：普通路径在 `MainBoardModel:FinishOrder` 中已调用一次 `order:SetFinished()`（`1135`），模型层又调用一次（`SlotOrderModel.lua:69`）；第二次因状态已 Finished，`SetFinished` 会复用缓存奖励。该双写是源码顺序，不应简化成单次调用。

### 6.2 补位循环

`SlotOrderModel:_TryFillOrders`（`Board_Model_Order_SlotOrderModel.lua:29-59`）用 `repeat` 循环：按 `slot=1..m_slotCount` 扫描空槽或 Finished 槽；删除旧订单，调用 `_TryCreateOrder(slot)`；新订单加入数据库和 `arrNewOrders`。只要本轮创建过订单，就再扫一轮，直到一整轮没有创建。最终调用 `boardModel:UpdateOrderState()`，再逐个记录新订单的 `unlock` 日志。

这意味着补位不是“每个槽只尝试一次”：一个 creator 可能返回 nil，后续轮次仍会重试；运行时是否会因活动/时间变化产生新订单由配置和活动状态决定。

### 6.3 MainOrderModel 的完成副作用

`MainOrderModel:FinishOrder`（`Board_Model_Order_MainOrderModel.lua:560-602`）在调用父类补位前执行：

- 分支订单写入 `_SetBranchOrderFinished`。
- `CharacterIntimacyModel:OnMainOrderFinished()`。
- 清除 `m_canTriggerLucky`，然后若当前订单本身是 Lucky，设回真；普通订单读取 `GetRandomOrderConfigBySlot(order:GetSlot())[innerType].LuckyTriggerChance`，调用 `MathUtil.Random()`，只有 `randomNum <= chance` 才设为真。
- 普通订单位于 `NormalOrderSlot` 时，把 `order:GetDiffScore()` 加入 `TotalDiffScore` 元数据。
- 遍历需求代码；若 `OrderItemConfig.RepeatWeightDecrease > 0`，按链 ID调用 `ResetRepeatWeightDecreaseByChainId`。
- 最后调用 `SlotOrderModel.FinishOrder`。

订单 Lucky 的机会抽样与生成器 LuckyProduce 无关；这里是一次订单完成后为下一次订单创建设置 `m_canTriggerLucky` 的概率分支。`MathUtil.Random()` 的底层范围/包含端点在本报告证据中未恢复，标为 `runtime-pending`。

### 6.4 事件与同步顺序

普通主订单完成链尾部（`MainBoardModel.lua:1151-1161`）依次：

1. `UpdateOrderState()` 更新所有订单的填充状态。
2. 若 OrderBoost 首次微笑条件满足，派发 `SmileOrderDeliver_1`。
3. `GM.SyncModel:CheckMoreUpload(nil,nil,order:GetRequirements())` 检查上传。
4. `self.event:Call(BoardEventType.FinishOrder, payload)`，payload 包含订单、棋盘/仓库扣除结果、即时奖励和延迟奖励。

全局 `EEventType.OrderFinished` 在 `SlotOrderModel:FinishOrder` 的补位完成后派发，因此它发生在 `BoardEventType.FinishOrder` 之前。奖励对应的各活动监听器、商店和 Google Play Games 等回调是动态注册关系，应以事件索引和运行时日志继续核对（`runtime-pending`）。

## 7. 订单类型与创建/补位优先级

### 7.1 `_TryCreateOrder` 的实际优先级

`MainOrderModel:_TryCreateOrder`（`Board_Model_Order_MainOrderModel.lua:527-558`）按以下顺序，只在前一项返回 nil 时继续：

1. `MainOrderCreatorFixed.Create`：固定配置。
2. `MainOrderCreatorReturnFreeOrder`：回归免费订单。
3. `TutorialOrderModel:CanCreate/CreateOrder`：教程订单。
4. 活动 `Contiorders`：连续订单。
5. `ExtraCustomer`：额外顾客。
6. `MainOrderCreatorLuckyOrder`：Lucky 订单。
7. `MainOrderCreatorRandom`：普通随机订单。

成功订单若无 ID 且类型为 Random，则由 `DBIdGenerator` 生成 ID；随后追加亲密度礼物信息并派发 `MainOrderCreated`。因此“订单补位”本身不是简单随机，活动和教程优先级可以完全覆盖随机 creator。

### 7.2 普通随机订单可确认的内部阶段

`MainOrderCreatorRandom.luac.txt` 的函数原型标注了以下阶段（源码行号是 Lua 原始行号）：`RandomOrderHelper:CanCreate`（119-168）、`Create`（185-309）、`TryLuckyRandom`（312-370）、`LuckRandomRemoveCode`（373-382）、`GetSelectedFilterConfig`（385-412）、`CreateNormalRandomOrder`（421-537）、`CreateNormalRandomOrderWithChainIdFilter`（539-588）、`GetAvailableItems`（671-824）、`_CheckItemCode`（840-928）、`GetBaselineAvailableItems`（931-958）、`GetDynamicMaxLevel`（971-1080）、`FilterByLevel`（1087-1117）、`FilterByChainId`（1122-1131）。

可直接确认的筛选规则：

- 读取随机订单类型元数据计时器；首次创建写入服务器时间，之后只有 `serverTime - startTimer >= RefreshTime` 才允许刷新（反汇编函数 `MainOrderCreatorRandom.lua:119-168`）。
- 按 `OrderRandomConfig.Filters` 选择一个满足玩家等级、`DiffSum` 等条件的过滤器；第一、第二、第三需求分别用 `FirstMin/FirstMax`、`SecondMin/SecondMax`、`ThirdMin/ThirdMax` 限制物品难度层。
- 物品候选经过解锁等级、进度解锁、禁用槽位、生成器可用性、上一个订单和其它订单需求排除，再要求配置 `Weight > 0`。
- `ItemAmounts` 控制一项/两项/三项需求数量的权重；抽取函数为 `Table.ListWeightSelectOne`。当前 `OrderRandomConfig.json` 有 9 个类型（1,2,3,4,9,12,15,16,21），其中常见类型的 `OneItemWeight=50, TwoItemsWeight=50, ThreeItemsWeight=0`。
- `OrderItemConfig` 候选字段包括 `Code, DiffScore, Price, RecommendedPrice, UnlockLevel, ProgressUnlock, ForbiddenSlot, Weight, WeightMultiple, RepeatWeightDecrease, RecommendedNumber, DifficultyLevel`。当前 JSON 74 行，`DiffScore` 2..3000；配置字段实际存在性以每行缺失为准，不能把缺省当零。

### 7.3 固定订单与特殊配置

`MainOrderModel:LoadFileConfig`（`Board_Model_Order_MainOrderModel.lua:31-86`）装载：`OrderFixed`、`OrderRandom`、`OrderRandomReCall`、`OrderSpecial`、`OrderBranch`、`OrderItemNumberWeight`、`OrderItem`、`OrderAvatar`、`ChestOrderRandomConfig`、`ChestOrderRandomRecallConfig`。其中固定订单按 `Id` 建表，特殊奖励通过 `ConfigUtil.GetCurrencyFromArrStr` 转为货币数组；随机配置中 `IsLucky==1` 的行单独存入 `m_luckyOrderConfig`，其它按 `Type` 存入 `m_randomOrderConfig`。

当前可读取的本地 JSON 快照：

| 配置 | 行数/类型 | 关键字段 |
|---|---:|---|
| `OrderItemConfig.json` | 74 | 代码、价格、难度、解锁、权重、禁用槽、重复权重衰减 |
| `OrderRandomConfig.json` | 9 | Type、UnlockLevel、RefreshTime、Filters、ItemAmounts |
| `OrderFixedConfig.json` | 16 | Id、Requirement1..3、Slots、UnlockLevel |
| `OrderSpecialConfig` | 本地 JSON 未导出 | 字节码配置可见，具体生效行需运行时/配置导出补齐 |
| `OrderBranchConfig` | 本地 JSON 未导出 | 分支订单配置由 `OrderBranch` 装载，当前客户端文本未提供完整表 |

`OrderFixedConfig.json` 中固定订单是按 `Slots` 和 `UnlockLevel` 约束的静态候选，例如 ID 7 需求为 `303 + 206`，ID 11 为重复需求 `504 + 504`；该表必须保留重复项。

## 8. 特殊订单与分支订单

### 8.1 Special

`_FinishSpecialOrder`（`MainBoardModel.lua:1258-1285`）先调用 Slot 模型完成订单并补位；然后从特殊配置读取最多三条 `Requirement1..3` 的链 ID，并读取 `GeneratorChain`。棋盘上每个物品若本体或气泡内部代码属于需求链或生成器链，就被批量移除；之后更新订单状态、发放 `orderConfig.Rewards`（`SpecialTaskComplete`）、写入 `EndTimeline` 地图进度，并派发 `BoardEventType.FinishSpecialOrder`。它不是普通订单的“多奖励版本”。

### 8.2 Branch

`_FinishBranchOrder`（`MainBoardModel.lua:1287` 起）先完成 Slot 订单；根据单个 `Requirement` 链和 `GeneratorChain` 批量清除棋盘物品；之后按 `orderConfig.Rewards` 的权重列表用 `Table.ListWeightSelectOne` 反复抽取，直到权重列表为空，并把每个奖励放入可用空位。其余分支（空位不足、奖励落点、后续事件）需继续从 `MainBoardModel.lua:1287` 后续源码逐行核对，当前报告只确认到权重抽取入口，标为 `runtime-pending`。

### 8.3 SpecialOrderCell UI

`SpecialOrderCell:OnGoButtonClicked`（`Board_View_Order_MainOrderCell.lua:536-542`）打开 `SpecialOrderItemWindow`；`SpecialOrderCell:GetDisplayRewards` 返回空表。因此特殊订单的奖励展示和最终提交按钮不应套用普通订单页面。

## 9. 配置与状态持久化清单

| 状态 | 写入/读取位置 | 作用 |
|---|---|---|
| 订单需求、填充状态、状态时间 | `BaseOrder` 字段；同步后由各 Slot 模型恢复 | 交付门槛与 UI 状态 |
| 订单 slot/id/type/avatar | `MainOrder`、`SlotOrderModel` 数据库实现 | 订单身份和补位位置 |
| `FirstOrder`、最近完成订单 | `MainOrderModel` 元数据常量 `3-8`、`_DBGetLastFinishOrder` | 首单与召回/创建条件 |
| `luckorder_` / `m_canTriggerLucky` | `MainOrderModel.lua:5-7`, `560-584` | 下一次 Lucky 订单机会；不是产出 Lucky |
| `TotalDiffScore` | `MainOrderModel.lua:8`, `585-592` | 普通槽难度累计，参与随机订单过滤 |
| `RepeatWeightDecreaseChain` | `MainOrderModel.lua:11`, `605-625` 等 | 订单项重复权重衰减，完成涉及链后重置为 3 |
| 随机订单计时器 | `MainOrderCreatorRandom` 反汇编原始行 119-168 | `RefreshTime` 冷却，使用服务器时间 |
| 奖励缓存 | `BaseOrder:SetFinished` `130-135` | 完成后重复读取仍返回完成瞬间奖励 |

## 10. 随机语义审计

| 随机点 | 算法 | 是否放回 | 证据状态 |
|---|---|---|---|
| 普通随机订单需求数量 | `Table.ListWeightSelectOne(ItemAmounts)` | 每次创建重新建表；跨订单不保存候选池 | `source-confirmed`，底层随机接口端点待确认 |
| 随机订单物品候选 | 过滤后 `Table.ListWeightSelectOne` | 单个订单内已选项/重复链规则会改变候选；完整移除策略需补读 Create 函数 | `source-confirmed` 部分，`runtime-pending` 边界 |
| 订单完成后 Lucky 订单机会 | `MathUtil.Random() <= LuckyTriggerChance` | 每次完成独立调用；Lucky 订单自身直接连续触发 | `source-confirmed`，随机端点 `runtime-pending` |
| 分支奖励 | `Table.ListWeightSelectOne` 循环并移除权重项 | 代码明确消耗候选列表，具体复制/变异需逐行确认 | `source-confirmed` 部分 |
| 价格/奖励 | 无随机，按配置和活动模型顺序累加 | 不适用 | `source-confirmed` |

当前没有证据支持“订单需求按一个固定全局无放回池抽取”的结论。与母体 Decremental 或 Lucky 机会池不同，订单随机创建每次从过滤后的配置候选重建列表；若某种类型有 `RepeatWeightDecrease`，它通过链级元数据影响权重，而不是把已抽出的订单项永久从全局表删除。

## 11. 未确认项与下一步取证

1. **使用库存确认窗口**：计数参数的代码语义已确认，尚未闭合“确认按钮 -> 仓库扣除 -> 再次 FinishOrder”的调用链。
3. **Special/Branch 完整尾部**：Branch 权重奖励落点和空位失败分支需从 `MainBoardModel.lua:1287` 后续全文逐函数核销。
4. **`OrderSpecialConfig`、`OrderBranchConfig` 生效行**：当前只恢复到 Lua 配置模块和装载代码，没有可直接读取的 JSON 快照。
5. **动态奖励活动**：`ActivityModuleManager`, `CharacterIntimacy`, `OrderBoost`, `CookingFrenzy` 等回调的注册顺序、异常重试和网络副作用需要运行时事件追踪。
6. **重复点击/并发交付**：静态代码没有事务锁；需要客户端运行时双击和网络延迟案例确认实际保护层。
7. **奖励 API 原子性与失败重试**：当前只确认调用顺序，服务端失败响应、回滚和重发由外部接口决定，标为 `runtime-pending`。
8. **订单创建动态 creator 的完整配置优先级**：活动/教程/账号状态可能覆盖普通随机订单，需要逐种活动状态回放。

这些项目不是“没有逻辑”，而是当前静态证据尚未闭合；在阶段三门禁中必须保留为未确认项，不能用普通订单成功案例替代。

## 12. 验收案例矩阵

| 案例 | 必须观察的证据 |
|---|---|
| 普通单项订单 | 按钮门控、CanDeliver、即时奖励、棋盘扣除、补位、事件顺序 |
| 重复需求 `[504,504]` | 第二项计数、逐项扣除两个实例、缺口聚合 |
| 棋盘/仓库混合 | 首次 `GetCodeCountMap`、确认窗口、棋盘优先扣除和库存兜底 |
| 余额不足 | 不完成订单、不发奖励、不扣除，窗口/错误提示 |
| Special | 不走普通奖励链，链级批量清除、时间线和专用事件 |
| Branch | 权重奖励循环、空位边界、补位和事件 |
| Lucky 订单完成 | 已标记 Lucky 的连续机会与普通 `LuckyTriggerChance` 分支 |
| 订单配置缺失 | `cfg_err`、价格 0、后续是否阻断奖励 |
| 双击/延迟 | 订单是否可重复完成，奖励与扣除是否幂等 |

报告完成度：普通订单静态链已达到 `source-confirmed` 的可实现描述；库存确认、特殊/分支尾部、动态活动和运行时事务性仍为明确缺口。不能据此宣称订单系统整体已完成运行时验收。
