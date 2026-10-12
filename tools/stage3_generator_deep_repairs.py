"""Source-reviewed additions; merged into existing pages without rewriting configs."""
BODIES = {
'events/board/detail.md': '''# 棋子创建、订单刷新和落子事件的先后

## 1. 创建与保存先于通知

BaseBoardModel SpreadItem调用GenerateItem；它先由ItemModelFactory.CreateWithCode创建棋子（默认允许解锁类型），SaveItemProperty保存，再在位置非nil时_SetItem写入格子。主棋盘的_SetItem调用基类写入之后，除非autoUpdateOrderState显式false，才CountItemsCode、UpdateOrderState；订单状态刷新因此先于落子通知。

GenerateItem返回新模型后构造消息：Source母体、New新棋子、EnergyBoostRatio（nil默认0）、CostEnergy、BoardSpreadType。先发送棋盘局部BoardEventType.SpreadItem；MainBoardModel再派发全局EEventType.ItemSpread。监听回调可在这个同步通知中继续产出追加棋子。

## 2. 通知完成后才写本次日志

MainBoardModel在全局通知之后处理日志。普通双倍来源GeneratorBoostExtraNormal归一为Normal，智能双倍来源GeneratorBoostExtraSmart归一为GeneratorBoostSmart；事件消息此前已经保留双倍类型，所以活动能据它复制，日志则区分另一口径。Disco日志类型再查当前仍有效的Disco属性；若本次用完助力并关闭，查到的属性值可为0。

eb是本次指数、md是能量增益类型、st为日志来源、oriEle为返回的原始代码、sc为特殊场景；支持GeneratorBoost且有效Buff字符串非空时追加ab。之后LogSpread、_TryLogBoardFull。手动点击回到ItemSpread才发VibrationLight，并检查变换/销毁/CD Buff。

## 3. 空位与失败边界

上述SpreadItem没有“AddItem返回false就停止BoardChanged”的分支；文档不能自行补这样一条事务保障。空位前置检查和最终落点在点击链，创建/格层写入的异常或断言要继续追ItemModelFactory及ItemLayerModel。当前方法同样不把已扣能量、次数和保存自动回滚。

**证据**：BaseBoardModel GenerateItem / SpreadItem；MainBoardModel _SetItem / SpreadItem；ItemSpread _TrySpread。完整事件消费者须逐个按其注册条件理解，不能把通知顺序理解成所有活动都无条件生效。
''',
'events/resource/detail.md': '''# 能量消耗、资源通知与免费 Lucky 进度

## 1. 次数先处理，再扣实际能量

手动点击在GenerateItemCode返回后才SpreadCostEnergy，然后记录Lucky的增益历史，最后落子。普通产出在GenerateItemCode内已改次数、更新计时、保存；Lucky直接返回没有普通扣次。不是先扣Energy再把次数写成1。

SpreadCostEnergy把棋盘能量类型映射为属性类型；costEnergy真时，用最终指数的GetBoostCostNum作为请求数量，调用PropertyDataManager Consume，并把请求数写测试记录。此函数不检查Consume返回值，外层也不因失败自动撤回之前的状态。

## 2. 属性消耗的实际分流

Consume默认num为1，负数报错返回false，0返回true且不通知；测试无限属性开关命中也直接返回true。活动专用属性及礼物有各自handler。能量属性则调用EnergyModel SubtractEnergy，只有成功才派发PropertyConsumed并记录用户资源、SDK统计。

SubtractEnergy先拒绝负数；无限能量直接返回true与实际消耗0。否则余额不足返回false；足够时写余额减请求数，到0记录耗尽统计，根据上传开关检查能量上传。若本次从不低于上限降到低于上限，开始恢复计时；最后返回实际消耗数。

## 3. 请求量和实际量不能混用

DispatchConsumeEvent消息包含property（类型、实际数量）和ext；能量分支ext.origin为请求数。先发全局PropertyConsumed，再LogUseItem。无限能量可能请求1却实际扣0；免费Lucky监听资源消耗时，必须按其读取的消息字段累计，不能用本次UI能量档代替所有入口的真实消耗。

本次GenerateItemCode已完成，所以此次消耗推动的免费资格通常供后续点击使用；其它消耗入口也可能推进免费计数。具体服务器日重置、阈值生成与消费见[免费Lucky](../../lucky/free/generate.md)。

**证据**：ItemSpread _TrySpread、SpreadCostEnergy；PropertyDataManager Consume、DispatchConsumeEvent；EnergyModel SubtractEnergy。上传handler、全局PropertyConsumed的其它监听还需按实际配置和订阅继续核对，不能推定为固定成功上传。
''',
'overrides/activity/index.md': '''# Disco：先直接帮助订单，否则改写普通产出

Disco有自己的助力分值，不是把本次产物数量乘一个活动倍率。主棋盘母体获得Disco支持时，能量检查免能量，Lucky入口被跳过；然后先尝试直接提供订单相关代码。

## 执行顺序

1. 检查剩余助力、母体是否生成器、配置Spread_CostEnergy是否为1。
2. 从母体能产出的链中选订单缺口；若找到合适物品，扣Disco分值并直接返回，不进普通池或扣普通次数。
3. 找不到直接目标时，用普通产出算法生成代码，但将最大升级指数设为3。
4. 根据剩余Disco分值逐级降低过贵物品，扣Disco分值，将母体costCount改0；普通点击累计仍加1。
5. Disco分值归零时关闭Buff、保存并发结束通知。

普通算法中的教程强制、Fixed智能分支和FishNet仍在各自位置执行。[底层页](detail.md)解释缺口排序、难度等级、8分宽限与降级方式。追加一件物品属于GeneratorBoost，见[事件后的复制](../../events/side_effects/detail.md)，不要混为Disco倍率。
''',
'overrides/activity/detail.md': '''# Disco 的订单选择、助力分值与普通回退

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
''',
'events/side_effects/index.md': '''# 后续通知怎样影响下一件物品

本次生成的代码和来源类型会进入落子通知。各监听者根据自己的条件响应；不能只凭“Lucky命中”概括为活动进度必加1。

## 处理位置与含义

1. 落子之前，记录此次能量指数历史，供后续Lucky调整升级档。
2. 主棋子落子通知携带Source、New、来源类型和能量指数。GeneratorBoost普通双倍资格在候选阶段先确定，收到通知后才复制实际产物。
3. Lucky类通知在指定Buff开启且有空位时也能复制实际产物；连续Lucky类型不在此监听的条件内。
4. 追加类型与主类型不同，避免同一监听再次无限复制；其它进度、提示、声音按各自监听条件处理。

本次“生成物品”可能通过通知引出第二次SpreadItem，但它不重新抽本次普通或Lucky物品池。[底层说明](detail.md)列出资格池、缓存、位置检查和复制参数。
''',
'output/chest/index.md': '''# ChestCustomItem：用剩余分值帮助完成订单

这类母体的剩余次数实际是奖励分值预算。它先扣除棋盘已有物品能满足的需求，再优先照顾缺分较少的订单；预算不足时改给同链较低等级物品，最后用已解锁的五级物品填补剩余预算。

## 执行顺序

1. 整理未完成订单，并把已有库存依次分配给需求，避免重复使用同一件库存。
2. 按每个订单仍缺的难度分从小到大处理；接近完成时允许最多10分的整单补齐宽限。
3. 预算不足以补齐整单时，先处理便宜的需求，再降级发放。
4. 仍有正预算时随机选五级物品；列表生成结束后，母体本次只取第一件，按这件的难度分扣自己的剩余预算。

这里的“生成奖励列表”和“本次实际落一件棋子”是两件事。传入的 `testNum=1` 只限制测试日志，不能当成算法只生成一件的限制。[预算、降级与兜底的底层算法](detail.md)解释这一差别。
''',
'output/chest/detail.md': '''# ChestCustomItem 的预算、订单选择和降级算法

## 1. 输入和库存分配

ItemSpread 调用 `GenerateChestCustomCodeRule(m_itemRestNumber,1,false)`。三个参数分别是剩余分值、测试日志范围、是否应用库存优化；本调用第三参为false，因此走 `_PickItems_old`，不会进入 RewardStockCount 优化分支。

先深拷贝主棋盘 `GetCodeCountMap(true,false,true)`。遍历 `GetOrders()`，跳过 Finished；按每条需求逐件扣对应代码库存。库存不足才加入该订单的缺少列表，并累计 Slot 配置 `DiffScore`。没有订单代码配置的需求直接略过。库存分配只在临时映射上进行，不删除棋盘棋子；订单采用 `pairs` 遍历，不能擅自写成固定槽位顺序。

缺分大于0的订单按总缺分升序排序；同分没有额外排序键。

## 2. 按预算处理订单

令剩余预算为S、当前订单缺分为D。S≤0停止；若 `S+10≥D`，把该订单所有缺少代码按原需求顺序加入奖励列表，预算变为S−D。这允许最多10分的超预算整单补齐。

否则把该订单需求按单件DiffScore升序处理：S足够支付时加入该代码并减分；S不足时，对该需求调用下述降级规则。每处理一项之前都检查S≤0，没有奖励件数上限；第二参数1只影响测试信息的输出范围。

## 3. 不够买目标物品时如何降级

`_PickItems_old` 从目标等级向一级倒序扫描同链代码。有订单配置就更新选中代码，找到第一个DiffScore≤21的等级立即停止；如果始终没有≤21的记录，仍保留最后找到的有效代码。

发放件数 `n=ceil(S/选中代码DiffScore)`，把n件该代码依次加入列表，每件扣其DiffScore。ceil而不是floor，所以最后一件可以把预算扣到负数。这不是按剩余权重抽取，也不是等价拆分到恰好零分。

## 4. 订单后还有预算

从订单代码配置筛选 `UnlockLevel≤玩家等级`、所在链至少一个生成器已解锁、物品链等级恰好5的代码。没有候选时插入205；然后在候选代码列表中均匀随机选择，允许重复，直到S≤0。若205本身缺少订单配置，后续读DiffScore仍会失败，代码没有再次容错。

## 5. 本次实际使用哪件、如何扣母体

外层只取返回数组第一项；空列表/首项nil时记录错误并用205。再读取实际选中代码的 `DiffScore` 作为costCount；算法内其它候选并不在本次一起落子，也不按整个候选列表总分扣母体。普通后处理中的活动可能把costCount改为0；无活动改写时次数减该分并截到0。

**证据**：ItemSpread `_GenerateItemCode` 的 ChestCustomItem 分支；RandomGenerateCodeHelper `GenerateChestCustomCodeRule` / `_PickItems_old`。本包存在同名模块变体，加载变体需按资源来源核销，不能仅按方法名认定为同一实现。配表完整记录保留在本页下方。
''',
'output/smart/index.md': '''# SmartItem：优先补齐便宜订单的一件物品

SmartItem 把可发物品转成难度分预算，计算已有棋子合成后还差多少，再优先帮助补分较少的订单。本次最多给一件；它和 Lucky 的Smart权重倍率、Fixed中的Smart Buff是三个不同算法。

## 执行顺序

1. 首次使用时按母体储备上限筛出可发物品分值表；后续复用这个缓存。
2. 为已完成/可交付订单预留库存，再计算其它需求还缺的一级物品等价数量。
3. 把缺口换算成补齐分值，按订单总分、订单内单项分值从低到高处理。
4. 足够接近预算时直接补缺；太贵的需求先跳过，再给同链低级物品帮助积累。
5. 仍没有结果且预算为正时使用205/206兜底。本次取第一件并扣它的配置分值。

因此这不是“给权重乘订单缺口”。[底层页](detail.md)说明库存如何分配、二进制拆分、10分宽限、三级最低补发及兜底边界。
''',
'output/smart/detail.md': '''# SmartItem 的订单缺口、预算与单件限制

## 1. 建立可发代码表

首次进入SmartItem时，遍历Slot订单配置，把非nil且 `DiffScore≤m_storageMaxNumber` 的记录存为 `m_SmarOrderConfig[code]=DiffScore`。不在此处检查UnlockLevel；缓存非nil就不重新生成。剩余分值输入为 `m_itemRestNumber`。

`GetCodesFor_ItemSpread` 设置 `resultCount=1`、`isNeedUpFind=true` 后调用GetCodesForPlane。数量限制由该data对象维护；不是随机权重。最终外层取数组第一项，costCount为缓存分值或1，代码本身没有空结果兜底205。

## 2. 先分库存，再算可合成缺口

取主棋盘 `GetCodeCountMap(true,false,true)`；槽位优先序为 `1,2,11,3,8,4,5,18,10,15`，其余槽位追加；特殊槽位跳过。CanDeliver/Finished订单只有全部需求都能从库存扣除时才记为完成；试扣失败会回滚该订单已扣库存，其全部需求进入未完成列表。成功试扣的库存预留给它，不再给后续需求使用。

未完成需求先按链等级升序，同等级按上述槽位优先序排序。每项调用BoardModelHelper的缺口算法：从目标等级往一级扫描，把还需要的数量按相差等级乘 `2^等级差`，消费临时映射中的同级库存；不足部分继续向下。最终返回还差多少一级等价物品，并就地修改临时库存，防止下一需求重复使用。缺口0的需求删除。

## 3. 缺口怎样变成补齐分值

把一级缺口N按二进制从最低位到最高位扫描。第k位为1对应同链k+1级物品：配置中有它就加该分；没有则往下找最近一个可发等级，按 `2^等级差` 件折算分值并缓存。往下也找不到时，因为isNeedUpFind=true，往上最多找5个等级，第一个有配置的代码用于补齐估分。

按槽位累计SupplyScore，再按订单总分升序排序；每个订单内部按单项SupplyScore升序。同分排序没有额外稳定键，不能承诺固定顺序。

## 4. 正常补缺与10分宽限

单项SupplyScore大于 `剩余预算+10` 就加入skippedItems；否则用上述二进制顺序发物品。配置直接有代码就发一件并减分、resultCount减1；向下拆分时逐件发，最多受resultCount限制；向上补时发第一条有效更高级代码。每轮只在进入循环时检查正预算，实际发出后允许预算为负。本入口resultCount从1开始，因此常只实现最低位对应的那部分缺口，不会把整个缺口一次全补齐。

## 5. 太贵的需求如何补发

还有正预算且尚未发物品时，按skippedItems原顺序从目标等级往下找分值可支付的代码。等级≥3时，n1为 `ceil(该需求一级缺口/此代码一级等价量)`，n2为 `ceil(剩余预算/此代码分值)`，发放数为 `min(n1,n2,resultCount)`。可支付代码低于3级时，改给同链3级一件；完全找不到可支付代码也给同链3级一件。三级分值可能大于剩余预算，且源码假定三级存在有效配置，不能自行补一个新的容错算法。

## 6. 最后兜底与母体扣分

还剩正预算且resultCount>0：预算≤205分值时必给205；预算更高且206在表内时，用 `floor(math.random()+0.5)+5` 选五/六级面包（0.5为分界，各占半区间）；206不存在则给205。随后扣该代码分值、数量限制减1。

外层实际扣选中物品的缓存分值，不是用算法返回的负预算替换母体状态。活动后处理可能覆盖costCount。205/同链三级缺配置、空结果、同分排序和临时库存映射来源均是复刻时必须保留或显式处理的边界。

**证据**：ItemSpread SmartItem分支；SmartRewardHelper GetCodesFor_ItemSpread、GetCodesForPlane、MarkItemFinishedOrNot、CalculateLackNumForUnfinished、CalculateSupplyScoreForSingleCode、SortOrderAndItem、CalculateRewardItems、DeliverSkippedItems、DeliverRandom205_206、GetEquivalentCode；BoardModelHelper CalculateLackNumForMergeRequire。完整配置与字段来源见本页下方。
''',
'overrides/boost/detail.md': '''# 能量链升级与 FishNet 补缺算法

## 1. 决定实际升级几级

记录原始代码。只有最大增益指数>0、普通算法允许能量升级、代码无特殊前缀三项成立时才使用最大指数b；否则从指数0开始。

若棋盘提供订单缺口图，按i=0..b检查原代码同链的第L+i级：此代码在缺口图中存在，或同时满足 `L+i<b+1`、库存映射中有此代码、`max(库存−订单需求,0)` 为奇数，就把实际指数截为i并停止。存在性判断采用Lua真值，不是单独比较缺口数>0。奇数判断受等级边界限制，不能泛化成每个等级都配对。

然后按实际指数次读取MergedType，缺MergedType时保留原代码；即使没有变成更高等级，指数本身不会因此自动减少。记录升级后的代码。

## 2. FishNet 在升级后再检查

FishNetProduceSmart服务器开关开启、升级后代码无特殊前缀、代码链为RwaFish时才执行。统计同链1..最高级−1的现有物品，每件等级l换算成 `2^(l−1)` 一级鱼；最高级库存不计入。总一级量记为T，合成一件最高级需要M，缺口 `D=M−(T mod M)`。

D必须是二次幂且不等于M；T恰好是M倍数时D=M，故不改写。候选等级范围是 `[1+实际指数, min(3+实际指数,最高级)]`，不是“原始产物等级+1到+3”。D还须至少达到该范围最小等级的一级等价量。

在范围内由低到高查找一级等价量恰好为D的等级，且该等级必须严格低于当前升级后产物等级，才替换产物并记录FishNetProduceSmart场景。此机制只能下调当前产物到补齐缺口的等级，不是再次向上升级；返回能量指数保持不变，后续活动仍可能再改代码/指数。

**来源**：ItemSpread SpreadCheckEnergyRatioAndCode；ItemModelConfig.MergedType及链等级映射；棋盘订单缺口/需求/库存；服务器FishNetProduceSmart开关。阈值1、3及二次幂公式来自代码，不是配表。
''',
'lifecycle/count/detail.md': '''# 普通次数扣除、保存与落子后的收尾

## 1. 本次是否进入扣除

普通GenerateItemCode路径在候选选择、能量链升级、活动改写之后才调用CosetRestNumber。Lucky直接返回和Disco直接代码返回不进入这次扣除；Disco普通改写把costCount设0时仍进入，点击累计仍加1。

## 2. 扣除的优先级

先 `m_spreadCount+=1`。算法显式给costCount（包括0）时，次数减该值并截0，函数立即返回。没有显式值时：OrderItem在原配对列表中查最终代码Weight；其它一次性母体扣 `floor(2^实际能量指数)`；其它可恢复母体调用NextEnergyBoostCostIndex，消费该档循环序列。OrderItem匹配不到代码时costRestNumber仍nil，源码没有另加默认1。

## 3. 何时更新计时与保存

CosetRestNumber本身只改计数，没有UpdatePerSecond、事件或保存。回到GenerateItemCode后依次UpdatePerSecond、发ItemSpreadEventType.StateChanged、SaveItemProperty。它们在实际能量扣除和SpreadItem落子之前发生。不能把这些写成落子成功后的原子事务；发生异常时需要按实际执行点追踪已变状态。

## 4. 落子后先变换，再销毁，再CD Buff

手动路径落子并发VibrationLight之后调用TryRemoveSelf：有TransformNumber且精确等于累计次数时优先Transform并返回false；否则一次性且次数0就RemoveItem并发CollapseItem、返回false。两者都不发生才返回true，外层再TryUseCDBuff。相等不是大于等于；Transform优先于耗尽销毁。自动路径另有自己的收尾，不可套用此手动顺序。

**来源**：ItemSpread GenerateItemCode、CosetRestNumber、_TrySpread、TryRemoveSelf；次数分值、Weight、TransformNumber及EnergyBoost循环来源见下方配表。
''',
'events/side_effects/detail.md': '''# 落子通知后的 GeneratorBoost 追加产出

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
''',
}

CASES = {
'lucky/items/type.md': ('主例B抽204，它不在本地Super名单中，因此显示普通Lucky。对照抽到名单中的205时，改用Super表现，物品不多抽、不多发。', '食品袋105本地super_items=[205,304,305]，Lucky权重为204×63、205×10、303×15、304×10、305×2。B整数点50选204，isFree=false且无连续类型→Lucky。独立对照点70选205→SuperLucky；isFree=true则同一205→FreeSuperLucky。有TripleLucky1自定义类型时仍保留TripleLucky1，不再按名单分类。Smart关闭且没有连续自定义类型时，取得Lucky资格后的Super占比(10+10+2)/100=22%；不是额外22%的第二次机会。'),
'overrides/activity/detail.md': ('105主例未开启Disco。独立Disco对照说明先扣专用助力直接给订单物品，既不消耗普通池，也不扣普通能量和次数。', '假设105受Disco支持，剩余助力10，配置difficulty_level=5，订单缺五级205且其DifficultyLevel=5；可负担上限由10+8=18右移算得5，直接给205并扣2^(5−1)=16，助力截0且关闭Disco。返回能量指数0，costEnergy=false，次数仍80、Fixed池仍42。阈值与助力是对照输入，8分宽限来自代码；不足的6分不会成为负余额。'),
'overrides/activity/index.md': ('105主例没有Disco。独立对照演示Disco支持时跳过Lucky并直接帮助订单，不能把活动Started理解成一律产物翻倍。', '对照假设Disco助力10、允许难度5、目标205难度5，直接产205并扣16助力，剩余截0；不扣Energy、普通次数或Fixed池。具体分值推导见底层页。'),
'events/side_effects/index.md': ('食品袋105主例未启用追加Buff，Lucky产204没有凭空增加一件或活动进度。对照Buff有效时复制已经落下的Lucky物品。', '对照主Lucky代码204、有一个追加空位、ExtraLuckyProduce Buff有效时：再落一件204，追加类型GeneratorBoostExtraLucky且costEnergy=false。是否另增某项任务进度须由对应任务监听决定，不能统一写+1。'),
'output/chest/detail.md': ('105是Fixed，主例不执行宝箱算法。用实际宝箱main_super_ball_1作分支对照，说明候选列表可有多件，点击只使用第一件。', '本地main_super_ball_1模式4、初始分值450。假设使用后剩S=10、唯一未完成订单缺204与205、库存均0；默认OrderItemConfig中两者DiffScore为5、10，总缺分15。10+10≥15，候选列表[204,205]、算法内部预算−5；外层本次只取204，扣5，宝箱实际剩5，只落一件204。母体字段与分值来自本地表，剩余状态和订单是演示输入；不能套给食品袋105。'),
'output/chest/index.md': ('105主路径跳过宝箱；实际宝箱main_super_ball_1的对照展示如何先帮接近完成的订单。', 'main_super_ball_1本地初始预算450，演示使用后剩10，订单缺204与205（本地分值5、10）。10分宽限使候选包含两件，但本次只给204、扣5、剩5，具体列表与母体预算差别见底层页。'),
'output/smart/detail.md': ('105主例不是SmartItem。用实际main_smart_pot_a_1作对照，说明按合成缺口补一件，不是修改抽奖权重。', '本地main_smart_pot_a_1模式5、初始次数35、储备上限14；默认订单表204分值5、205分值10，均≤14，进入缓存。假设母体当前预算20、唯一订单缺五级205，已有四级204一件、其它同链库存0：目标16个一级等价、已有8、缺N=8（二进制1000），对应204，SupplyScore=5。发204后resultCount从1到0，预算20−5=15，母体也按5扣到15。母体字段和分值是本地值；订单、当前次数和库存为演示状态。'),
'output/smart/index.md': ('105主例不进入SmartItem；实际智能母体main_smart_pot_a_1的对照展示给一件能帮助合成订单目标的物品。', '本地智能母体允许分值≤14的代码，204分值5。演示订单缺205、已有204一件时，还需要另一件204；当前预算20，本次给204并扣5、剩15。更细的库存分配和二进制计算见底层页。'),
'overrides/boost/detail.md': ('食品袋105不属于生鱼链，主例不执行FishNet；独立生鱼对照展示“补缺降级”而不是再升级。', '假设生鱼最高级6，M=32，已有一级等价T=24，D=32−24=8，对应4级。实际能量指数2时候选等级为3..5；若升级后产物等级5，4在范围内且4<5，改给4级鱼，指数仍2。若当前产物已经4级，严格小于不成立，不改。链级数、库存和指数为对照输入。'),
'lifecycle/count/detail.md': ('食品袋105普通分支扣次数，Lucky分支不进入普通扣次。状态更新与保存先发生，落子后的变换/销毁再判定。', '对照初始次数80、累计0、基础指数0，假设NextEnergyBoostCostIndex(0)返回1：普通A产201，次数79、累计1；随后计时更新、状态通知、保存，之后才扣能量和落子。Lucky B产204直接返回，次数仍80、累计仍0。循环返回值1是演示输入，不代替远端循环配置。'),
'events/side_effects/detail.md': ('食品袋105主例未开启追加Buff，没有第二件。独立Lucky追加对照说明活动监听复制已落下的物品，不重抽Super资格。', '对照假设Source支持GeneratorBoost、ExtraLuckyProduce Buff有效，主事件BoardSpreadType=SuperLucky、New代码205、EnergyBoostRatio=0，还有一个扩散空位Q：复制205到Q，追加类型GeneratorBoostExtraLucky，costEnergy=false。改为TripleLucky1时本监听不进入；改为空位不足时本方法不复制。主分类和Buff是对照输入，没有凭空写活动进度+1。'),
'events/board/detail.md': ('食品袋105普通A产201后，先保存新棋子并写目标格、刷新订单状态，再通知棋盘和全局监听；本例无追加Buff。', 'A输入位置P、代码201、指数0、CostEnergy=true、来源Normal。GenerateItem创建201并保存，_SetItem写P后CountItemsCode/UpdateOrderState；消息Source=105模型、New=201模型、EnergyBoostRatio=0、CostEnergy=true、BoardSpreadType=Normal。局部SpreadItem→全局ItemSpread→本次日志→满盘统计→返回点击链VibrationLight。源码没有案例旧说法中的AddItem失败返回或BoardChanged条件。'),
'events/resource/detail.md': ('A普通产出先扣母体次数再扣能量；B Lucky不扣普通次数，但仍按本例条件扣能量。新的消耗通知推进后续免费Lucky进度。', '初始能量10、母体次数80；A示例次数循环返回1，GenerateItemCode先把次数改79并保存；最终指数0请求1能量，非无限、余额足够时Energy变9，PropertyConsumed数量1、ext.origin=1，再落201。B直接产204，次数仍80，能量同样10→9。无限能量对照请求仍1但真实消耗0、消息数量0；不能当成免费Lucky已累计1。'),
'overrides/boost/index.md': ('食品袋105基础档不升级。独立能量增益对照说明订单可截断升级档，然后FishNet只对生鱼链补缺。', '对照原始代码201（一级）、最大指数2、订单当前缺202（二级）：按i=0检查201无缺口，i=1发现202缺口，实际指数截1，MergedType把201升到202；不会继续给203。它是2^指数的档位，不是把能量5乘1.2变6；主例指数0仍产201。'),
}
