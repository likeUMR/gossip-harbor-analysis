"""Reviewed source-rule explanations, preserving existing asset/config sections."""
from pathlib import Path
import re

BODIES = {
'output/fixed/index.md': '''# Fixed：按类型共享的有限产出池

Fixed 的“固定”指每轮按配置补回同一组配额，不是每次独立地按固定概率抽奖。母体把类型或 ItemStateCollection 的状态类型交给 `ItemFixedSpreadModel`；模型从剩余权重抽一个物品，抽中配额减 1，整轮耗尽后重新装填。

同类型母体共享模型里的同一个类型池；Decremental 则消费各个母体实例自己的池。这是复刻时不能省略的状态归属差别。

## 执行顺序

1. 先检查 GeneratorBoost SmartProduce / Smart Buff 资格；智能算法能给出结果时优先返回，不进入普通 Fixed 抽取。
2. 没有智能结果时，检查并装载该类型的剩余池，包括旧存档迁移与配置变更。
3. 在剩余权重总量中抽取并扣减抽中物品配额。
4. 有剩余时保存剩余池；耗尽时补回整轮原配置。后续能量升级、活动改写及母体次数处理仍在外层继续。

同一物品在配置池中有多份，因此连续两次抽到它仍然可能；这不代表放回。食品袋105的普通池是三种代码、42份，不要与五种Lucky候选混淆。具体池状态、共享范围与迁移见[底层算法](detail.md)。
''',
'output/fixed/detail.md': '''# Fixed 的有限池、共享状态与重装

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
''',
'lucky/items/smart.md': '''# Smart Produce 权重修正

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
''',
'lucky/chance/load.md': '''# 配置选择、预处理与重载

## 1. 装载并建立母体索引

`Init` 先执行 BaseActivityModel 初始化，`_LoadFileConfig` 优先使用显式传入的 boostConfig，否则读取 LocalConfigKey.LuckyProduce。遍历每条配置的 generator，将同一母体的记录按源列表顺序放入 `m_mapGeneratorType2Config`；同一母体可以有多个等级段。

`LateInit → CalculateItemChainMap` 将 `"204-63"` 等字符串拆成 `{Item="204",Weight=63}`，补 ItemChainLevel 与 itemChainMap。模型配置不存在的候选保留在幸运物品列表，但不进入链索引。如果某配置第一项已经包含 Item，源码直接退出整个预处理函数；这依赖载入数据状态，不是逐条跳过。

## 2. 本次点击选择适用记录

`_GetLevelFitConfig` 先查母体键，再按列表顺序寻找玩家等级满足的第一条记录。level_min / level_max 缺失分别表示没有该侧限制，存在时两端均包含。区间重叠时第一条优先；没有适配记录就没有 Lucky 资格。实际使用哪个分组还取决于上层 ConfigModel 与活动配置，不能把所有包内变体相加。

## 3. GeneratorBoost 与重新加载

`GetGeneratorBoostConfig` 查询已开始的 GeneratorBoost 活动并读取 GetLuckyProduceConfig。`ReloadFileConfig(boostConfig,bUpdate)` 重新装载并预处理；bUpdate 为真时，只对新配置列出的母体调用两种机会计数清除方法。清除方法还要求该类型的数据库键已进入本进程键缓存，未缓存时直接返回。源码没有遍历数据库删除所有旧母体，也没有在这里清免费或连续状态。

## 4. 重装周期机会

点击读到总剩余为0时，才用已选配置的 `lucky_chance[1]`、`[2]` 重装总机会和 Lucky 配额。它不是每点击都重置。首次计数缺失按总剩余0处理；非零总剩余却缺 Lucky 计数的损坏状态没有这段代码的独立修复兜底。

**配表字段**：generator、level_min、level_max、lucky_chance、lucky_items、super_items。下方保留全部包内变体和记录；它们是可选来源，不代表账号同时生效。**源码**：Init、_LoadFileConfig、LateInit、CalculateItemChainMap、_GetLevelFitConfig、GetGeneratorBoostConfig、ReloadFileConfig、_ClearLuckyLeftSpreadCount、_ClearTotalLeftSpreadCount。
''',
'lucky/free/generate.md': '''# 免费阈值的生成、跨段与每日重置

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
''',
'energy/boost/detail.md': '''# 能量档、Lucky 历史均值与最终扣费

## 1. 预检查最大档

`GetCostEnergyNum` 默认成本1、指数0；母体支持当前能量档时读取当前最大成本和指数。余额预检查使用这个最大成本；后续产物可能降档，不能把余额检查数值当作最终消费。

## 2. Lucky 路径的历史调整

`GetAdjustedMaxEnergyBoostRatio`：AdjustLuckyProduceBoostRatio 服务端开关关闭或历史为空时返回传入指数；否则对历史指数求平均并向上取整。源码没有再取 min(当前档,均值)，因此不能自行给复刻加这项上限。

`_InitEnergyBoostRatioAdjustData` 从 PlayerPrefs 的 LuckyProduceEnergyBoostRatioAdjustData 读取逗号序列。`RecordBoostRatioAdjustData` 只记录开关开启、实际扣能量、来源为 Normal 或 GeneratorBoostSmart、且母体属于能量增益目标的点击。最多保存最近4条：满时移除最旧一条，再追加本次实际指数并保存。Lucky 本身及其它来源不会更新这段历史。

`TryGenerateLuckyItem` 取调整指数后沿 MergedType 升级相应次数；缺 MergedType 时保留当前代码继续循环。它不走普通次数扣除链。

## 3. 普通路径的订单截档

`SpreadCheckEnergyRatioAndCode` 只有最大指数>0、算法允许增益且代码无特殊前缀时，先取最大档，再按 i=0..最大档扫描同链等级：目标等级存在订单缺口，或满足源码中的低等级正奇数剩余条件时，截为 i 并停止。奇数条件的等级限制是 `chainLevel+i < maxEnergyBoostRatio+1`，不能泛化成“所有等级有奇数就截档”。随后沿 MergedType 升级，生鱼专用逻辑见[链升级与 FishNet](../../overrides/boost/detail.md)。

## 4. 真正扣能量与母体次数

`SpreadCostEnergy` 在产物计算后使用 EnergyBoostModel.GetBoostCostNum(最终指数) 消费资源；普通可恢复母体的次数由 NextEnergyBoostCostIndex 决定。该函数按 `floor(2^指数)` 查服务器 EnergyBoostCost 循环序列，按 PlayerPrefs 的 EnergyBoostCost_成本 键读取并推进索引；缺配置或未开启增益返回1，索引失效时回退序列首项。一次性母体默认次数扣 `floor(2^指数)`，算法显式提供 costCount 则优先使用它，包括0。

**边界**：历史可能调整出不同于当前预检查的 Lucky 档；原版最终资源系统如何处理余额边界仍需端到端验证，不应假设这里自动二次检查。**来源**：ItemSpread.GetCostEnergyNum、TryGenerateLuckyItem、SpreadCheckEnergyRatioAndCode、SpreadCostEnergy；LuckyProduceModel 的历史三个函数；EnergyBoostModel.NextEnergyBoostCostIndex。服务端开关、次数序列与真实账号历史为 runtime-pending。
''',
'lifecycle/cooldown/detail.md': '''# CD、恢复计时与 Buff 资格

## 1. 哪些条件启动计时

`UpdatePerSecond` 没有 m_startTimer 时，在 Initializing、Opening，或 Opened 且（次数未满或储备为0）且非一次性时，写服务器时间并保存；状态通知随后发送。可恢复母体第一次消费使次数未满即可开始恢复，不只在最后一次耗尽时才开始。

已有计时且 ItemAccelerateTime 生效时，以 min(加速结束时间,服务器当前时间) 修正起点，保存后检查 GetTimerAmount。比例恰为1时执行恢复并保存，最后发 StateChanged。`GetNextTimerAmount` 以当前已过时间+1计算，供视图预测下一秒。

## 2. 比例与阶段

GetTimerDuration 在 Initializing 取初始化时长、Opening 取开启时长；Opened 且储备为0取储备恢复时长，否则取单轮恢复时长。`_GetTimerAmount` 为 min(已过时间/阶段时长,1)，没有下限截0；时长0直接为1，时长缺失记录错误、清起点并返回1。不能把负比例或缺字段当作普通“还没到期”。

## 3. 到期如何补回

初始化/开启到期清起点、改为Opened，派发 ItemOpened 并刷新开启列表。储备为0时补满储备和次数并清计时。否则先把次数补到上限，再从储备扣“上限-当前次数”；即使储备不足，也先补满次数、把储备截为0，起点增加一个单轮恢复时长并再次更新。这个顺序允许离线经过多个阶段，不是仅一次补回。

## 4. CD Buff 谁可用

普通 CD Buff：BuffItemcd 生效、主棋盘、消耗能量、非一次性，四项同时满足。GeneratorBoost CD：CanSupportGeneratorBoost 成立且活动 IsNoCDActive。测试免费CD：测试模式与TestSpreadItemCDFree开关、消耗能量、非一次性。CanSupportGeneratorBoost / CanSupportSmart 的母体资格为主棋盘且（消耗能量并非一次性，或 RawFish05 特例），前者另要求活动已开始，后者要求 buff_smart 生效。

TryUseCDBuff 任一资格成立后，只有次数0才 OnTimeSkip(nil,Buff)，但无论是否0均派发状态通知。TryUnlockCdByZroCd 只在次数0调用它。OnTimeSkipInZeroRestNumber 是另一路：要求生成器、消耗能量且主棋盘，次数0才跳时；不能把两条入口的资格合并。

## 5. 费用、表现与跳时

GetSpeedUpCost 先读教程强制费用，否则按阶段基准费用×(1-比例)，向上取整且至少1。`_SpeedUp(false)` 检查宝石、失败派发 LackGem，成功扣宝石；存在计时才跳时并派发 SpeedUp。OnTimeSkip 有明确时长时把原起点减该值；无时长时先设起点为当前时间再减整个阶段时长，保存、播放加速音效、执行恢复并记BI。

ShowCountDown 在仍有次数且非初始化/开启时隐藏；一次性次数0也隐藏。ShowCountdownAnimation 要求已有计时且加速组件生效。IsChestUsedOnce 仅检查配置有开启时长且当前次数不同于上限，不是持久化“曾开过”布尔值。

**配表**：Spread_*Duration / SpeedUpCost；活动及测试开关独立读取。**源码**：UpdatePerSecond、_UpdateRecoveryState、GetTimerAmount、GetNextTimerAmount、_GetTimerAmount、GetTimerDuration、GetSpeedUpCost、OnSpeedUp、_SpeedUp、OnTimeSkip、TryUnlockCdByZroCd、TryUseCDBuff、各CanSupport资格、ShowCountDown、ShowCountdownAnimation、IsChestUsedOnce。恢复与判定为 source-confirmed，原版离线/重登、父类存档与实际活动为 runtime-pending。
''',
'position/auto/detail.md': '''# 自动母体为何可能忽略点击，以及棋盘满如何缓存

## 点击与自动更新的关系

手动 CheckSpreadPosAndAuto 对自动母体先查询自动落点：如果能找到，直接返回false，交给 Update 的自动循环处理，不另外因手动点击产出。自动落点为空才继续手动的方形环落点检查；因此“自动母体点击无反应”可能是主动避免重复产出，不是棋盘满错误。

Update 只有 Spread_Auto==1 才反复调用 _TryAutoSpread，直到返回false。每轮要求次数不为0且状态Opened；一次性自动母体走全盘随机空格，可恢复自动母体只扫描固定八邻域。

## 无空位的特殊缓存

只有一次性、Decremental、棋盘提供CacheItemFromSpread、AutoSpreadToCache开关开启，四项同时成立才允许缓存。没有空位时GetAutoSpreadDecrementalRemainTypes把剩余权重逐份展开成列表，缓存后m_spreadCount加列表长度，EmptySpreadCount清次数、储备与实例权重，更新计时、通知并保存。不是所有自动母体都会转缓存。

## 自动路径与手动的区别

有位置时自动路径调用GenerateItemCode并落子，但只取其第一个返回值，落子参数默认增益0；存在ItemDig时标记Dig且costEnergy=false。此处不调用手动SpreadCostEnergy，也不调用手动TryRemoveSelf；无ItemDig且到变换点击数时执行Transform并停止。次数0后下一轮停止。不能把手动点击的销毁、事件类型、费用顺序直接套给自动路径。

**来源**：Update、IsAutoSpread、_TryAutoSpread、_GetAutoSpreadPosition、CheckSpreadPosAndAuto、GetAutoSpreadDecrementalRemainTypes、EmptySpreadCount、MainBoardModel.FindSpreadPosition。动态缓存开关与棋盘实现需运行验证。
''',
}

CASES = {
'output/fixed/index.md': ('食品袋105的普通池本轮抽出201，201剩余份额从35减到34，总剩余从42减到41；同类型母体继续共享这41份。整轮耗尽才补回42份，因此下一次仍可能抽到201，但不会恢复成本次抽取前的概率。', '本轮初始201×35、202×2、301×5；演示抽样点20命中201。下一次份额为34、2、5，201占比为34/41；冷却和能量由外层另行处理。'),
'output/fixed/detail.md': ('本页计算食品袋105的一轮份额怎样随抽取变化，以及另一只同类型食品袋为何接着消费同一池。', '源配置201×35、202×2、301×5，总42；演示抽样点20命中201，保存剩余串201×34、202×2、301×5，总41。下一次同类型食品袋按41份抽，201占34/41；轮末最后一份消费后立即重装35、2、5，共42份。数字对应本地配表，抽样点是演示输入。'),
'lucky/items/smart.md': ('主案例关闭Smart，仍按原始Lucky权重抽出204；下面的独立对照开启整数倍率3，订单缺205且能量指数1时，只把同链可帮助订单的204权重乘3，说明倾向如何改变。', '本地食品袋105的默认Lucky池为204×63、205×10、303×15、304×10、305×2，总100。主案例未开启Smart。独立对照假设服务器倍率3、订单缺205（等级5）、能量指数1：204等级4满足5≥4+1，权重63×3=189；205等级5不满足5≥5+1，仍10；薯条链仍15、10、2。总226，204占189/226≈83.63%。演示整数抽样点50命中204。倍率、订单和抽样点为假设，原权重为本地配表；缺多少个205不再乘入权重。'),
'energy/boost/detail.md': ('主案例使用基础档、不调整历史。独立对照显示Lucky如何根据过去几次普通点击的实际指数调整产物档，同时普通母体次数扣除由独立循环序列控制。', '对照假设开关开启且最近指数为[0,1,2,2]，Lucky调整指数ceil(5/4)=2，物品沿MergedType升级两次；假设当前最大指数3，也仍取历史均值2。若可恢复母体的4点能量档次数序列为[1,2,1]，索引1、2、3依次扣1、2、1再回1；序列是假设的服务器值，不能视为原版固定参数。'),
'lifecycle/cooldown/detail.md': ('食品袋105未满次数时开始恢复计时；等待到期补次数并扣储备。下面用一次整轮耗尽说明储备恢复如何接续，额外Buff例子只作为条件对照。', '本地105次数上限80、储备240、单轮恢复30秒、储备恢复60秒。假设serverTime=1000、次数0、储备10、起点1000：1030单轮到期先补次数到80，储备10-80截到0，起点推进到1030，之后按储备阶段60秒计时。1090储备到期补储备240、次数80并清起点。若CD Buff资格成立且次数为0，另走跳时路径；不是每次点击都无条件清CD。'),
'lucky/free/generate.md': ('食品袋105主案例不使用免费阈值；独立对照演示其它入口消费能量也能推进阈值，以及跨服务器日只清免费进度而不直接清普通周期或连续资格。', '假设能量段[0,9]、extra_lucky=2，随机序号3、8转为阈值2、7；这是服务器配置与受控抽样演示。累计Energy到5时队首2已满足，一次免费资格只移除2，7仍在队列。跨服务器日后ecc归0、elpec清空；tl_105/ll_105和已有连续clp字段不由_ResetEnergyCost直接删除。'),
'lucky/chance/load.md': ('食品袋105按母体类型与玩家等级选择一条Lucky配置，使用该条机会与产物池；活动重载可能改变来源并清已缓存键对应的周期计数。', '本地默认105配置等级[1,999]，lucky_chance=[60,1]，Lucky池总100。等级10选择此记录；若假设另一个来源有重叠等级记录，第一条适配优先。bUpdate=true重载会请求清105的周期键，但清除方法只有键在本进程缓存时才执行；免费与连续资格不在本函数清除。'),
'position/auto/detail.md': ('食品袋105的主案例不是自动母体，自动路径不执行。下面对照说明自动Decremental母体在棋盘满时如何缓存剩余配额，而非无限重试点击。', '独立对照假设自动、一次性、Decremental母体余池[201×2,202×1]，没有空格；棋盘实现缓存且开关开启时缓存[201,201,202]，点击累计加3，次数与储备及权重归零。四条件任一不成立则停止，不生成、不缓存。这些自动母体字段是演示输入，不能套给105。'),
}


def supplement_generator_rules(docs: Path):
    from stage3_generator_deep_repairs import BODIES as DEEP_BODIES, CASES as DEEP_CASES
    BODIES.update(DEEP_BODIES)
    CASES.update(DEEP_CASES)
    for rel in dict.fromkeys([*BODIES, *CASES]):
        p=docs/'operations/generator'/rel
        text=p.read_text(encoding='utf-8')
        idx=text.find('\n---\n')
        if idx<0: idx=text.find('\n\n---\n')
        if idx<0: raise ValueError(f'Cannot locate preserved example in {rel}')
        if rel in BODIES:
            text=BODIES[rel].strip()+'\n'+text[idx:]
        if rel in CASES:
            qualitative,values=CASES[rel]
            text=re.sub(r'(\*\*本页发生什么\*\*：).*?(?=\n\n)',lambda m:m.group(1)+qualitative,text,count=1,flags=re.S)
            text=re.sub(r'(### 代入本页的值\n\n).*?(?=\n\n<details>)',lambda m:m.group(1)+values,text,count=1,flags=re.S)
        p.write_text(text,encoding='utf-8')
    from stage3_generator_downstream_repairs import supplement
    supplement(docs)
    from stage3_generator_source_links import supplement_source_links
    supplement_source_links(docs)
    from stage3_generator_disco_navigation import supplement as supplement_disco
    supplement_disco(docs)
    from stage3_generator_execution_structure import supplement as supplement_structure
    supplement_structure(docs)
    supplement_source_links(docs)


if __name__=='__main__':
    supplement_generator_rules(Path(__file__).resolve().parents[1]/'analysis_output/logic_recovery/stage3/mkdocs_site/docs')
