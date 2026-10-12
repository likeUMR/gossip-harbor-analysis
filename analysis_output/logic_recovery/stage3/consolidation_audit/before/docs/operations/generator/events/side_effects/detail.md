# 落子后：追加产出、活动进度与奖励

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

## 4. 同一次产出如何计入其它活动

以下都是独立监听的条件，不是GeneratorBoost结束后必然逐个执行的固定步骤。CostEnergy是事件中的标志，追加棋子通常不携带true，因此不能把“棋盘多了一件”都算作又消耗了一次Energy。

| 消费者 | 进入条件 | 按最终产物/指数计算什么 |
|---|---|---|
| ScoreRush | 比赛未结束、在竞赛中、Source主棋盘且CostEnergy为真；产物链有配置且等级≥配置level | `floor(baseScore×2^(产物等级−level))`，加当前分，派发MyScoreChangedEvent，附Score和New |
| TriggerPlane | 每日状态Activated、活动Started、CostEnergy为真；链配置存在、等级≥Level | `floor(BaseScore×2^(等级−Level)+0.5)`，调用AddScore；它的取整与ScoreRush不同 |
| TriggerBoost | Source主棋盘且CostEnergy为真 | 先累计`2^指数`消耗进度，再在活动Started且CanAddScore时按链Level/BaseScore计分，使用`score // 1`，派发TriggerBoostScoreChange并保存 |
| TriggerProgress | 触发进行中、score_type为chance、Source主棋盘且CostEnergy为真 | 当前点击机会耗尽才重装chance[总数,得分配额]；有配额时抽`1..剩余总数`，命中扣配额，每次总数减1；命中奖励`2^指数` |
| HitBricks | Source主棋盘、CostEnergy为真、ruleType=0、活动Started、当前主场景且IsActivityOpen | 使用chance_new的有限机会/配额，命中给`2^指数`锤子、保存数量、记录获得并派发HammerGeneratedEvent；未命中返回nil |
| Adventure | Source主棋盘、CostEnergy为真、活动Started、genByCostEnergy配置存在且genNum非0 | 用chance/genNum有限配额判资格，再按items权重抽Item；沿MergedType按指数升级，缓存到活动棋盘，派发AddAdventureActivityItem消息，不直接占主棋盘一个格 |
| ItemClickAcquireModule | Source主棋盘、CostEnergy为真；遍历注册model且conditionFunction成立 | 各model自己的DB机会/配额按rewardCount/conditionCount重装；命中返回`2^指数`，未命中返回nil；两者都会传给该model的AddNumFunction，不能假设nil被所有消费者忽略 |

这些字段来自不同活动的加载/注册配置，不能借用Lucky的60/1作为它们的周期参数。多个活动可以针对同一次通知各自成立，资格池、状态和取整规则互不共享。

## 5. CardItem 的能量阈值与满盘积压

CardItem只在CostEnergy严格等于true且m_energyGenerateNum存在时，把`2^指数`交给AddEnergyNum。CanGenerateCardItem要求活动Started，先CheckFinish，再按当前链库存的精确整数倍条件决定是否暂停；stack开启会先将该链标完成，详见第7节。

累积计数缺省0；本轮阈值未建时，在`当前累计+1..m_energyGenerateNum`之间均匀抽一个整数保存。新增累计记为nextNum。主棋盘满时直接保存nextNum并返回：不生成、不做取模、不重置本轮标记。

有空位且nextNum达到阈值、m_generateByRound为false时，先把本轮生成标记设true；GenerateCardItem有未结束旧chain则复用一级卡片，否则TryGenerateNewChain选择新链、保存chain与isFinish=false，再取一级代码。从母体扩散找空位落卡，logSpread=false、来源CardItem，不携带CostEnergy=true；随后派发CardItemGenerate和卡片获得日志。

nextNum达到周期长度时清本轮标记和阈值，累计保存为`nextNum % 周期长度`。一次AddEnergyNum只经过一次生成判断；即使一次跨过多轮，也不能自行改成while循环补发每轮所有卡片。满盘分支可积压到超出周期长度，再次有空间时依当前源码顺序处理。

## 6. Room、教程与活动视图

Room只有Source主棋盘且CostEnergy为真才响应；Started且m_curInfo存在时按roomState分流：0走锁定状态得钥匙/分数，1走解锁状态活动Token。锁定状态在curClickNum≤0时装填chance；失败分支让curClickNum减1并保存，命中分支只让curAddScoreNum减1，给`ceil(2^指数)`并发AddlockStateScore后保存。源码在该命中分支没有相同的总数减1，不能将所有活动统一复刻为同一套有限池。AcquireKey和解锁状态还各有后续条件。

教程监听根据具体教程步进、目标棋子和活动场景响应：可能结束点击步骤、清强制位置、开始下一步，或仅记录产生Bubble/Temp的标记。活动棋盘视图会用New.GetCode更新自身等级，成功后更新进度、滚动、迷雾和解锁提示，附带延时回调、关闭/对象销毁检查与UI锁。它们不是一律增加主棋盘订单进度。

**证据**：GeneratorBoostActivityModel的注册/复制/缓存方法；上述各模型_OnItemSpread（CardItem为OnItemSpread）、相应计分/产物辅助方法。各活动完整配置、动态注册回调和独立下游条件不能仅凭这份入口说明推定为统一生效；远端当前周期参数仍依账号活动配置。

## 7. 卡片：先检查库存，再决定续用旧链还是抽新链 {#card-flow}

这条监听把符合条件的产出视为卡片生成进度。它读取消息的CostEnergy标志和指数，不读取本次实际扣能量的返回数量；OnItemSpread也没有另加Source必须是主棋盘的条件。实际落卡、库存检查仍使用主棋盘。因此不能将前述其它活动的主棋盘过滤条件复制过来。

### 7.1 库存达到什么程度会暂停

CanGenerateCardItem先要求活动Started，再CheckFinish，然后CheckCanMergeMaxCardItem。当前链没有isFinish、或isFinish=true时，库存检查直接返回false；否则取主棋盘、缓存、仓库三处代码数量，排除GetCodePrefixTargetType非nil的包装代码，只统计当前链。

每件L级卡片折成`2^(L−1)`个一级卡片，求总数C；最高等级M所需一级数为`N=2^(M−1)`。条件是 **C非0且C%N=0**。这是精确的整数倍判断，源码没有写C≥N：C=N暂停，C=N+1却不因本条件暂停。复刻时不能把它改成通常理解的“够合成就停”。card_item_stack等于1时，CheckFinish还会将满足该条件的当前链标为isFinish=true并保存；后续检查因已完成返回false，能量进度反而可以继续推进，下一次发卡会换链。

### 7.2 新链的候选、权重与避免连续重复

有chain且isFinish严格为false，直接返回旧链一级卡片，不抽链。否则按玩家等级≥UnlockLevel收集解锁链，先排除旧链；排除后为空才用旧链候选兜底，再用Table.ListWeightSelectOne按Weight抽一条。没有递减Weight或持久机会池，是本次重建候选的加权选择；正常有其它解锁链时相邻换链不会选回旧链。没有任何解锁候选时源码未写默认链；该配置组合不能凭空补一个默认卡片。

选中后保存chain、isFinish=false，再返回一级代码。Rarity不参与此抽样；它用于卡片表现与最高级首次弹窗。最高级使用后，非stack模式直接完成旧链；stack模式只在同链库存返回数量为0时完成。完成状态还会受活动清理、配置删除旧链影响，不能只在本次点击后内存里保存。

### 7.3 阈值、落子、保存与教程通知的顺序

阈值取本轮已有累计+1到周期长度的均匀整数。满盘时保存累积并返回；有位置且越过阈值、该轮未发卡时，先设本轮已发→选择/保存链→从母体扩散找空位→SpreadItem落一级卡片→派发CardItemGenerate→获得日志。周期边界随后清阈值与本轮标志，累计取模并保存。

CardItemGenerate还有本模型的OnCardItemGenerate监听：教程键已为字符串“2”时忽略，否则写“1”并发TutorialStartPop。CanPopCardItemTutorial要求活动Started且键为“1”；真正弹过后写“2”。这里是提示状态推进，不能解释成额外发一张卡。

### 7.4 对应配置如何读

| 配置/字段 | 读取及用途 |
|---|---|
| CardItemConfig.ItemChain | 作为链字典键；同键后记录覆盖前记录 |
| UnlockLevel、Weight | 新链候选等级门槛、候选间抽样权重 |
| Rarity | 表现/首次最高级弹窗；不再次抽资格 |
| 服务器misc_conf_new中confType=card_item_energy的首条param_int | 周期长度；未取得则m_energyGenerateNum=nil，点击能量监听不生成 |
| general配置card_item_stack | 严格等于1开启完成链堆叠分支 |
| CardItemProduceConfig.ItemType、LevelMin/LevelMax、Chance | TryGenerateItem另一入口按物品代码取记录，第一条适配等级优先；概率是1..10000比较Chance。本次OnItemSpread能量路径不读取这张概率表 |

本地默认链表26条，more变体26条；下方全量列出。实际require已被启动脚本改写：ConfigModel从模块路径末段取文件名，在服务器FileReplace列表顺序查找第一条file精确匹配记录，将suffix原样追加到路径；没有匹配则用原路径。替换路径加载成功就用该表；加载抛错才记录错误并回退原路径。默认回退也失败时不另造空表。普通Lua模块缓存按最终路径工作，替换服务器值并不等于既有卡片字典自动重建。

例如file=CardItemConfig、suffix=_more会选more链表；CardItemProduceConfig可独立配_zero，不能假设两张表总是同后缀。尚未取得账号FileReplace记录，不能确定当前账号是哪一份，但选用规则本身可从源码确认。产物概率表也提供全部恢复记录，供核对另一入口，不能把其中204的Chance=70写成“母体点击有0.7%额外落卡”。

### 7.5 数值对照：同样多于一张最高卡片，为何结果不同

食品袋105基础档产出且CostEnergy=true，给卡片进度1；以下为独立活动状态演示，替换主例中活动未启用的前提。假设当前卡片链最高三级，则N=4：库存一级等价C=4、stack关闭时暂停，计数不变；C=5时不暂停。再假设周期10、已有累计2、阈值3、未发卡且有空位，本次累计到3，只发一件当前链一级卡片，累计保存3；到10才清本轮标志。stack开启、C=4时先把旧链标完成，本次可继续计数并在发卡时抽新链。周期、库存、阈值和开关是演示输入。

默认表等级25首次无旧链时13条候选总权重24047，energy_b权重600，概率600/24047≈2.50%；假设上条已完成链是energy_b，则剩候选总权重23447，本次不再选energy_b。不是600/10000，亦不使用Rarity=4作权重。

## 8. 密室：同一次落子按当前锁定状态分流 {#room-flow}

入口先筛Source主棋盘且CostEnergy为真；活动Started且m_curInfo存在后，roomState=0走钥匙进度，=1走解锁期工具奖励。它们互斥，本次从锁定状态达到解锁门槛后，不回头再执行解锁期的能量奖励。

### 8.1 锁定：机会命中推进钥匙，满额立即解锁

剩余点击数≤0才重装chance[总数,命中配额]；抽整数1..剩余点击数。失败只减总数、保存并返回；命中只减命中配额，给ceil(2^指数)钥匙，源码没有在命中分支也减总数。AddLockScore累加钥匙，到maxNum就截满并调用SetUnLockState。AddLockScore先保存，之后AcquireKey记获得日志，TryLockStartAddScore再发局部AddlockStateScore（包含是否已解锁、母体、指数），最后再保存。

SetUnLockState的顺序是：标记刚解锁→roomState设1→解锁分数归0→重装工具第一轮（累计能量0）→截止时间设服务器时间+time×3600→写未展示解锁标记→给2个Token→GameStateChanged(isLock=false)→解锁日志→BundleDataRefreshed→保存→设待弹窗标记1。已有其它密室物品/秘密宝物状态并不在此处全部清空。

### 8.2 解锁：累计能量只结算当前一轮

本次加ceil(2^指数)到acuqireTokenInfo（源码字段拼作acuqireTokenInfo）的curEnergy。若累计≥当前energy门槛：只减一次当前门槛→调用RewardApi.AcquireRewardsLogic发当前tools，来源Give、模式Main、缓存Type2→轮数+1→读取新轮energy/tools。随后局部AddUnlockStateScore消息附本次分值、奖励（未达门槛时nil）、母体和指数，再保存。没有while循环；剩余累计即使够下一轮，也留到下一次符合条件的通知。

TryUnlockActivityToken并不调用AcquireToken；奖励是什么取决于tools配置，不能把每次消耗能量固定解释成Token+1。SetTokenNum本身先发TokenNumberChangedEvent差量，再写activityToken，监听收到通知时存档仍可能是旧值。

### 8.3 配表选轮、时限与重锁

roomActivate先按round升序，选择最后一条round≤当前轮的记录，读取token、chance、time。roomGetTool按round建字典；有精确轮就直接取，无精确轮时在isCyclic=1记录中循环：newRound=当前轮−#工具表，序号=(newRound−1)%循环数量+1，再按ipairs的循环记录次序选择。它依赖连续数组索引与至少一个循环记录，源码未为稀疏表/0循环数补默认。

UpdatePerSecond先调用活动父类更新，再检查解锁截止≤服务器时间。到期SetLockState：roomState设0、round+1、钥匙归0、读取该轮token/chance并重装机会数、清解锁展示标记；发GameStateChanged(isLock=true)、下一轮及锁定日志，保存，再发BundleDataRefreshed，待弹窗标记设0。活动状态计算在解锁期用max(活动eTime,解锁截止)决定Started结束点：已解锁时间可能延续到原活动结束之后。

以上roomActivate/roomGetTool来自_LoadOtherServerConfig，当前快照没有本次账号远端活动记录，因此这里只给出字段和算法，不能填成原版固定门槛。roomLevel、roomReward、roomScoreReward在同函数装载，但本次上述落子分支不直接读取；它们的密室内玩法不能与母体点击直接获得的钥匙混为一谈。

### 8.4 数值对照：解锁点击与跨轮奖励

独立演示食品袋105指数2、CostEnergy=true。锁定状态总数3、配额1、钥匙8/10、随机点1：配额1→0，总数仍3；加4钥匙后截为10并解锁，给2个Token，工具累计重置0，本次不再加工具进度4。假设time=2、服务器时间1000，截止8200。门槛/状态/随机点是演示输入，2 Token与小时换秒为源码常量。

另设已经解锁、工具累计2、当前门槛3、下一轮门槛2，指数2本次加4：累计6，发当前轮tools一次，减3余3，轮数+1；尽管余3≥新门槛2，本次不补发下一轮。下一次基础档加1后累计4，才再减2并发新轮奖励，余2。不能用while结算替代源码。

## 9. 动态注册：点击还会给连锁礼包代币 {#token-flow}

ItemClickAcquireModule不是活动的最终消费者。ActivityModuleManager把ClickAcquireProperty分派给该模块；TokenChainActivityModel进入Started时注册一个实际回调，机会参数来自服务器tokenChainGiftConfig[1].chance。注册附带的条件同时要求Started且未完成全部礼包，覆盖模块默认的“只检查Started”。不能只清点直接ItemSpread监听就漏掉这个活动。

### 9.1 有限机会池与状态隔离

每个注册model用自己的DB和键。本活动显式提供TotalClickTimes、ValidClickTimes，分别存剩余总机会与命中配额；缺值按0处理，总机会等于0才重装chance[1]/chance[2]。抽1..总机会，先总机会减1保存；随机点大于配额则返回nil，否则配额减1保存，返回能量指数对应的数量。正指数用循环每步乘2；nil/0/负指数返回1，源码未为小数指数另作规范化。资格按点击机会抽，命中件数按指数增益，两者不是把总机会一次扣2^指数。

AddRegister再次针对同一model调用会替换回调与参数，不直接清已有DB机会数。移除注册也只删内存映射，不清计数。多个model通过pairs遍历，源码没有保证它们的回调次序。

### 9.2 真正增加代币的顺序

模块每次把结果（包括nil）和母体交给回调。TokenChain的回调对nil或≤0立即返回，所以这个具体消费者确实忽略未命中；命中时先SetTokenNum（写DB，再发TokenNumChangedEvent），再记cost_energy日志，然后寻找主棋盘视图和母体视图，最后播放代币飞行动画。视图不存在时返回，但代币已入账；动画结束不能再加一遍。此保存/通知顺序与密室Token的先通知后保存相反。

进入Started时如CanGiveStartToken成立，还会标记已领取并先给10个开始代币，日志来源free；这是活动启动奖励，不是母体本次命中奖励。后续离开Started不在本函数显式移除注册，条件回调负责阻止非Started/已完成时继续抽取。

### 9.3 数值对照

独立假设chance=[3,1]、活动Started且未完成、代币余额10。食品袋105指数2的一次有效产出，随机点1命中：总机会3→2、配额1→0，代币10→14；若主棋盘视图为空，只省略动画，余额仍14。接着基础档随机点2未命中：总机会2→1、配额仍0，回调收到nil且余额仍14。若活动已完成，注册条件不成立，总机会也不会扣减。chance、库存与活动状态是演示输入；没有取得账号远端chance时不能将3/1当原版默认值。

## 卡片相关完整本地配表

<details><summary>CardItemConfig：26条完整记录</summary>
<div style="overflow-x:auto;"><table><thead><tr><th>ItemChain</th><th>UnlockLevel</th><th>Weight</th><th>Rarity</th></tr></thead><tbody>
<tr><td>main_card_item_energy_b</td><td>25</td><td>600</td><td>4</td></tr>
<tr><td>main_card_item_energy_m</td><td>25</td><td>1667</td><td>3</td></tr>
<tr><td>main_card_item_energy_s</td><td>25</td><td>3752</td><td>1</td></tr>
<tr><td>main_card_item_gem_b</td><td>25</td><td>600</td><td>4</td></tr>
<tr><td>main_card_item_gem_m</td><td>25</td><td>1667</td><td>3</td></tr>
<tr><td>main_card_item_gem_s</td><td>25</td><td>6669</td><td>1</td></tr>
<tr><td>main_card_item_levelup</td><td>25</td><td>234</td><td>4</td></tr>
<tr><td>main_card_item_plane_b</td><td>25</td><td>938</td><td>3</td></tr>
<tr><td>main_card_item_plane_m</td><td>25</td><td>1667</td><td>2</td></tr>
<tr><td>main_card_item_plane_s</td><td>25</td><td>3752</td><td>1</td></tr>
<tr><td>main_card_item_pot_b</td><td>25</td><td>234</td><td>4</td></tr>
<tr><td>main_card_item_pot_m</td><td>25</td><td>600</td><td>3</td></tr>
<tr><td>main_card_item_pot_s</td><td>25</td><td>1667</td><td>2</td></tr>
<tr><td>main_card_item_superball</td><td>30</td><td>234</td><td>4</td></tr>
<tr><td>main_card_item_raccoon_b</td><td>35</td><td>938</td><td>3</td></tr>
<tr><td>main_card_item_raccoon_m</td><td>35</td><td>1667</td><td>2</td></tr>
<tr><td>main_card_item_raccoon_s</td><td>35</td><td>3752</td><td>1</td></tr>
<tr><td>main_card_item_smart_buff</td><td>45</td><td>938</td><td>3</td></tr>
<tr><td>main_card_item_raccoon_customer</td><td>50</td><td>417</td><td>4</td></tr>
<tr><td>main_card_item_cannon_b</td><td>55</td><td>417</td><td>3</td></tr>
<tr><td>main_card_item_cannon_s</td><td>55</td><td>938</td><td>2</td></tr>
<tr><td>main_card_item_disco_b</td><td>60</td><td>938</td><td>3</td></tr>
<tr><td>main_card_item_disco_m</td><td>60</td><td>1667</td><td>2</td></tr>
<tr><td>main_card_item_disco_s</td><td>60</td><td>3752</td><td>1</td></tr>
<tr><td>main_card_item_infi_e_s</td><td>70</td><td>234</td><td>3</td></tr>
<tr><td>main_card_item_infi_e_b</td><td>80</td><td>59</td><td>4</td></tr>
</tbody></table></div>
<p><a href="../../../../../assets/recovered-source/CardItemConfig.json">完整数据</a> · <a href="../../../../../assets/recovered-source/CardItemConfig.lua">恢复配置</a></p>
</details>

<details><summary>CardItemConfig_more：26条完整记录</summary>
<div style="overflow-x:auto;"><table><thead><tr><th>ItemChain</th><th>UnlockLevel</th><th>Weight</th><th>Rarity</th></tr></thead><tbody>
<tr><td>main_card_item_energy_b</td><td>25</td><td>515</td><td>4</td></tr>
<tr><td>main_card_item_energy_m</td><td>25</td><td>1431</td><td>3</td></tr>
<tr><td>main_card_item_energy_s</td><td>25</td><td>3221</td><td>1</td></tr>
<tr><td>main_card_item_gem_b</td><td>25</td><td>515</td><td>4</td></tr>
<tr><td>main_card_item_gem_m</td><td>25</td><td>2061</td><td>3</td></tr>
<tr><td>main_card_item_gem_s</td><td>25</td><td>12882</td><td>1</td></tr>
<tr><td>main_card_item_levelup</td><td>25</td><td>201</td><td>4</td></tr>
<tr><td>main_card_item_plane_b</td><td>25</td><td>1431</td><td>3</td></tr>
<tr><td>main_card_item_plane_m</td><td>25</td><td>2061</td><td>2</td></tr>
<tr><td>main_card_item_plane_s</td><td>25</td><td>5725</td><td>1</td></tr>
<tr><td>main_card_item_pot_b</td><td>25</td><td>201</td><td>4</td></tr>
<tr><td>main_card_item_pot_m</td><td>25</td><td>515</td><td>3</td></tr>
<tr><td>main_card_item_pot_s</td><td>25</td><td>1431</td><td>2</td></tr>
<tr><td>main_card_item_superball</td><td>30</td><td>201</td><td>4</td></tr>
<tr><td>main_card_item_raccoon_b</td><td>35</td><td>1431</td><td>3</td></tr>
<tr><td>main_card_item_raccoon_m</td><td>35</td><td>2061</td><td>2</td></tr>
<tr><td>main_card_item_raccoon_s</td><td>35</td><td>5725</td><td>1</td></tr>
<tr><td>main_card_item_smart_buff</td><td>45</td><td>805</td><td>3</td></tr>
<tr><td>main_card_item_raccoon_customer</td><td>50</td><td>358</td><td>4</td></tr>
<tr><td>main_card_item_cannon_b</td><td>55</td><td>515</td><td>3</td></tr>
<tr><td>main_card_item_cannon_s</td><td>55</td><td>1431</td><td>2</td></tr>
<tr><td>main_card_item_disco_b</td><td>60</td><td>1431</td><td>3</td></tr>
<tr><td>main_card_item_disco_m</td><td>60</td><td>2061</td><td>2</td></tr>
<tr><td>main_card_item_disco_s</td><td>60</td><td>5725</td><td>1</td></tr>
<tr><td>main_card_item_infi_e_s</td><td>70</td><td>201</td><td>3</td></tr>
<tr><td>main_card_item_infi_e_b</td><td>80</td><td>50</td><td>4</td></tr>
</tbody></table></div>
<p><a href="../../../../../assets/recovered-source/CardItemConfig_more.json">完整数据</a> · <a href="../../../../../assets/recovered-source/CardItemConfig_more.lua">恢复配置</a></p>
</details>

<details><summary>CardItemProduceConfig：177条完整记录</summary>
<div style="overflow-x:auto;"><table><thead><tr><th>ItemType</th><th>LevelMin</th><th>LevelMax</th><th>Chance</th></tr></thead><tbody>
<tr><td>203</td><td>1</td><td>60</td><td>35</td></tr>
<tr><td>204</td><td>1</td><td>60</td><td>70</td></tr>
<tr><td>205</td><td>1</td><td>60</td><td>105</td></tr>
<tr><td>206</td><td>1</td><td>60</td><td>140</td></tr>
<tr><td>207</td><td>1</td><td>60</td><td>175</td></tr>
<tr><td>208</td><td>1</td><td>60</td><td>210</td></tr>
<tr><td>209</td><td>1</td><td>60</td><td>245</td></tr>
<tr><td>210</td><td>1</td><td>60</td><td>280</td></tr>
<tr><td>211</td><td>1</td><td>60</td><td>315</td></tr>
<tr><td>212</td><td>1</td><td>60</td><td>350</td></tr>
<tr><td>213</td><td>1</td><td>60</td><td>385</td></tr>
<tr><td>214</td><td>1</td><td>60</td><td>420</td></tr>
<tr><td>303</td><td>1</td><td>60</td><td>35</td></tr>
<tr><td>304</td><td>1</td><td>60</td><td>70</td></tr>
<tr><td>305</td><td>1</td><td>60</td><td>105</td></tr>
<tr><td>306</td><td>1</td><td>60</td><td>140</td></tr>
<tr><td>503</td><td>1</td><td>60</td><td>35</td></tr>
<tr><td>504</td><td>1</td><td>60</td><td>70</td></tr>
<tr><td>505</td><td>1</td><td>60</td><td>105</td></tr>
<tr><td>506</td><td>1</td><td>60</td><td>140</td></tr>
<tr><td>507</td><td>1</td><td>60</td><td>175</td></tr>
<tr><td>508</td><td>1</td><td>60</td><td>210</td></tr>
<tr><td>509</td><td>1</td><td>60</td><td>245</td></tr>
<tr><td>510</td><td>1</td><td>60</td><td>280</td></tr>
<tr><td>511</td><td>1</td><td>60</td><td>315</td></tr>
<tr><td>512</td><td>1</td><td>60</td><td>350</td></tr>
<tr><td>513</td><td>1</td><td>60</td><td>385</td></tr>
<tr><td>603</td><td>1</td><td>60</td><td>35</td></tr>
<tr><td>604</td><td>1</td><td>60</td><td>70</td></tr>
<tr><td>605</td><td>1</td><td>60</td><td>105</td></tr>
<tr><td>606</td><td>1</td><td>60</td><td>140</td></tr>
<tr><td>903</td><td>1</td><td>60</td><td>35</td></tr>
<tr><td>904</td><td>1</td><td>60</td><td>70</td></tr>
<tr><td>905</td><td>1</td><td>60</td><td>105</td></tr>
<tr><td>906</td><td>1</td><td>60</td><td>140</td></tr>
<tr><td>907</td><td>1</td><td>60</td><td>175</td></tr>
<tr><td>908</td><td>1</td><td>60</td><td>210</td></tr>
<tr><td>909</td><td>1</td><td>60</td><td>245</td></tr>
<tr><td>1303</td><td>1</td><td>60</td><td>35</td></tr>
<tr><td>1304</td><td>1</td><td>60</td><td>70</td></tr>
<tr><td>1305</td><td>1</td><td>60</td><td>105</td></tr>
<tr><td>1306</td><td>1</td><td>60</td><td>140</td></tr>
<tr><td>1307</td><td>1</td><td>60</td><td>175</td></tr>
<tr><td>1308</td><td>1</td><td>60</td><td>210</td></tr>
<tr><td>1309</td><td>1</td><td>60</td><td>245</td></tr>
<tr><td>1310</td><td>1</td><td>60</td><td>280</td></tr>
<tr><td>1403</td><td>1</td><td>60</td><td>35</td></tr>
<tr><td>1404</td><td>1</td><td>60</td><td>70</td></tr>
<tr><td>1405</td><td>1</td><td>60</td><td>105</td></tr>
<tr><td>1406</td><td>1</td><td>60</td><td>140</td></tr>
<tr><td>1803</td><td>1</td><td>60</td><td>35</td></tr>
<tr><td>1804</td><td>1</td><td>60</td><td>70</td></tr>
<tr><td>1805</td><td>1</td><td>60</td><td>105</td></tr>
<tr><td>1806</td><td>1</td><td>60</td><td>140</td></tr>
<tr><td>1807</td><td>1</td><td>60</td><td>175</td></tr>
<tr><td>1808</td><td>1</td><td>60</td><td>210</td></tr>
<tr><td>1809</td><td>1</td><td>60</td><td>245</td></tr>
<tr><td>1810</td><td>1</td><td>60</td><td>280</td></tr>
<tr><td>1811</td><td>1</td><td>60</td><td>315</td></tr>
<tr><td>203</td><td>61</td><td>120</td><td>28</td></tr>
<tr><td>204</td><td>61</td><td>120</td><td>56</td></tr>
<tr><td>205</td><td>61</td><td>120</td><td>84</td></tr>
<tr><td>206</td><td>61</td><td>120</td><td>112</td></tr>
<tr><td>207</td><td>61</td><td>120</td><td>140</td></tr>
<tr><td>208</td><td>61</td><td>120</td><td>168</td></tr>
<tr><td>209</td><td>61</td><td>120</td><td>196</td></tr>
<tr><td>210</td><td>61</td><td>120</td><td>224</td></tr>
<tr><td>211</td><td>61</td><td>120</td><td>252</td></tr>
<tr><td>212</td><td>61</td><td>120</td><td>280</td></tr>
<tr><td>213</td><td>61</td><td>120</td><td>308</td></tr>
<tr><td>214</td><td>61</td><td>120</td><td>336</td></tr>
<tr><td>303</td><td>61</td><td>120</td><td>28</td></tr>
<tr><td>304</td><td>61</td><td>120</td><td>56</td></tr>
<tr><td>305</td><td>61</td><td>120</td><td>84</td></tr>
<tr><td>306</td><td>61</td><td>120</td><td>112</td></tr>
<tr><td>503</td><td>61</td><td>120</td><td>28</td></tr>
<tr><td>504</td><td>61</td><td>120</td><td>56</td></tr>
<tr><td>505</td><td>61</td><td>120</td><td>84</td></tr>
<tr><td>506</td><td>61</td><td>120</td><td>112</td></tr>
<tr><td>507</td><td>61</td><td>120</td><td>140</td></tr>
<tr><td>508</td><td>61</td><td>120</td><td>168</td></tr>
<tr><td>509</td><td>61</td><td>120</td><td>196</td></tr>
<tr><td>510</td><td>61</td><td>120</td><td>224</td></tr>
<tr><td>511</td><td>61</td><td>120</td><td>252</td></tr>
<tr><td>512</td><td>61</td><td>120</td><td>280</td></tr>
<tr><td>513</td><td>61</td><td>120</td><td>308</td></tr>
<tr><td>603</td><td>61</td><td>120</td><td>28</td></tr>
<tr><td>604</td><td>61</td><td>120</td><td>56</td></tr>
<tr><td>605</td><td>61</td><td>120</td><td>84</td></tr>
<tr><td>606</td><td>61</td><td>120</td><td>112</td></tr>
<tr><td>903</td><td>61</td><td>120</td><td>28</td></tr>
<tr><td>904</td><td>61</td><td>120</td><td>56</td></tr>
<tr><td>905</td><td>61</td><td>120</td><td>84</td></tr>
<tr><td>906</td><td>61</td><td>120</td><td>112</td></tr>
<tr><td>907</td><td>61</td><td>120</td><td>140</td></tr>
<tr><td>908</td><td>61</td><td>120</td><td>168</td></tr>
<tr><td>909</td><td>61</td><td>120</td><td>196</td></tr>
<tr><td>1303</td><td>61</td><td>120</td><td>28</td></tr>
<tr><td>1304</td><td>61</td><td>120</td><td>56</td></tr>
<tr><td>1305</td><td>61</td><td>120</td><td>84</td></tr>
<tr><td>1306</td><td>61</td><td>120</td><td>112</td></tr>
<tr><td>1307</td><td>61</td><td>120</td><td>140</td></tr>
<tr><td>1308</td><td>61</td><td>120</td><td>168</td></tr>
<tr><td>1309</td><td>61</td><td>120</td><td>196</td></tr>
<tr><td>1310</td><td>61</td><td>120</td><td>224</td></tr>
<tr><td>1403</td><td>61</td><td>120</td><td>28</td></tr>
<tr><td>1404</td><td>61</td><td>120</td><td>56</td></tr>
<tr><td>1405</td><td>61</td><td>120</td><td>84</td></tr>
<tr><td>1406</td><td>61</td><td>120</td><td>112</td></tr>
<tr><td>1803</td><td>61</td><td>120</td><td>28</td></tr>
<tr><td>1804</td><td>61</td><td>120</td><td>56</td></tr>
<tr><td>1805</td><td>61</td><td>120</td><td>84</td></tr>
<tr><td>1806</td><td>61</td><td>120</td><td>112</td></tr>
<tr><td>1807</td><td>61</td><td>120</td><td>140</td></tr>
<tr><td>1808</td><td>61</td><td>120</td><td>168</td></tr>
<tr><td>1809</td><td>61</td><td>120</td><td>196</td></tr>
<tr><td>1810</td><td>61</td><td>120</td><td>224</td></tr>
<tr><td>1811</td><td>61</td><td>120</td><td>252</td></tr>
<tr><td>203</td><td>121</td><td>999</td><td>19</td></tr>
<tr><td>204</td><td>121</td><td>999</td><td>38</td></tr>
<tr><td>205</td><td>121</td><td>999</td><td>57</td></tr>
<tr><td>206</td><td>121</td><td>999</td><td>76</td></tr>
<tr><td>207</td><td>121</td><td>999</td><td>95</td></tr>
<tr><td>208</td><td>121</td><td>999</td><td>114</td></tr>
<tr><td>209</td><td>121</td><td>999</td><td>133</td></tr>
<tr><td>210</td><td>121</td><td>999</td><td>152</td></tr>
<tr><td>211</td><td>121</td><td>999</td><td>171</td></tr>
<tr><td>212</td><td>121</td><td>999</td><td>190</td></tr>
<tr><td>213</td><td>121</td><td>999</td><td>208</td></tr>
<tr><td>214</td><td>121</td><td>999</td><td>228</td></tr>
<tr><td>303</td><td>121</td><td>999</td><td>19</td></tr>
<tr><td>304</td><td>121</td><td>999</td><td>38</td></tr>
<tr><td>305</td><td>121</td><td>999</td><td>57</td></tr>
<tr><td>306</td><td>121</td><td>999</td><td>76</td></tr>
<tr><td>503</td><td>121</td><td>999</td><td>19</td></tr>
<tr><td>504</td><td>121</td><td>999</td><td>38</td></tr>
<tr><td>505</td><td>121</td><td>999</td><td>57</td></tr>
<tr><td>506</td><td>121</td><td>999</td><td>76</td></tr>
<tr><td>507</td><td>121</td><td>999</td><td>95</td></tr>
<tr><td>508</td><td>121</td><td>999</td><td>114</td></tr>
<tr><td>509</td><td>121</td><td>999</td><td>133</td></tr>
<tr><td>510</td><td>121</td><td>999</td><td>152</td></tr>
<tr><td>511</td><td>121</td><td>999</td><td>171</td></tr>
<tr><td>512</td><td>121</td><td>999</td><td>190</td></tr>
<tr><td>513</td><td>121</td><td>999</td><td>208</td></tr>
<tr><td>603</td><td>121</td><td>999</td><td>19</td></tr>
<tr><td>604</td><td>121</td><td>999</td><td>38</td></tr>
<tr><td>605</td><td>121</td><td>999</td><td>57</td></tr>
<tr><td>606</td><td>121</td><td>999</td><td>76</td></tr>
<tr><td>903</td><td>121</td><td>999</td><td>19</td></tr>
<tr><td>904</td><td>121</td><td>999</td><td>38</td></tr>
<tr><td>905</td><td>121</td><td>999</td><td>57</td></tr>
<tr><td>906</td><td>121</td><td>999</td><td>76</td></tr>
<tr><td>907</td><td>121</td><td>999</td><td>95</td></tr>
<tr><td>908</td><td>121</td><td>999</td><td>114</td></tr>
<tr><td>909</td><td>121</td><td>999</td><td>133</td></tr>
<tr><td>1303</td><td>121</td><td>999</td><td>19</td></tr>
<tr><td>1304</td><td>121</td><td>999</td><td>38</td></tr>
<tr><td>1305</td><td>121</td><td>999</td><td>57</td></tr>
<tr><td>1306</td><td>121</td><td>999</td><td>76</td></tr>
<tr><td>1307</td><td>121</td><td>999</td><td>95</td></tr>
<tr><td>1308</td><td>121</td><td>999</td><td>114</td></tr>
<tr><td>1309</td><td>121</td><td>999</td><td>133</td></tr>
<tr><td>1310</td><td>121</td><td>999</td><td>152</td></tr>
<tr><td>1403</td><td>121</td><td>999</td><td>19</td></tr>
<tr><td>1404</td><td>121</td><td>999</td><td>38</td></tr>
<tr><td>1405</td><td>121</td><td>999</td><td>57</td></tr>
<tr><td>1406</td><td>121</td><td>999</td><td>76</td></tr>
<tr><td>1803</td><td>121</td><td>999</td><td>19</td></tr>
<tr><td>1804</td><td>121</td><td>999</td><td>38</td></tr>
<tr><td>1805</td><td>121</td><td>999</td><td>57</td></tr>
<tr><td>1806</td><td>121</td><td>999</td><td>76</td></tr>
<tr><td>1807</td><td>121</td><td>999</td><td>95</td></tr>
<tr><td>1808</td><td>121</td><td>999</td><td>114</td></tr>
<tr><td>1809</td><td>121</td><td>999</td><td>133</td></tr>
<tr><td>1810</td><td>121</td><td>999</td><td>152</td></tr>
<tr><td>1811</td><td>121</td><td>999</td><td>171</td></tr>
</tbody></table></div>
<p><a href="../../../../../assets/recovered-source/CardItemProduceConfig.json">完整数据</a> · <a href="../../../../../assets/recovered-source/CardItemProduceConfig.lua">恢复配置</a></p>
</details>

<details><summary>CardItemProduceConfig_more：177条完整记录</summary>
<div style="overflow-x:auto;"><table><thead><tr><th>ItemType</th><th>LevelMin</th><th>LevelMax</th><th>Chance</th></tr></thead><tbody>
<tr><td>203</td><td>1</td><td>60</td><td>65</td></tr>
<tr><td>204</td><td>1</td><td>60</td><td>130</td></tr>
<tr><td>205</td><td>1</td><td>60</td><td>195</td></tr>
<tr><td>206</td><td>1</td><td>60</td><td>260</td></tr>
<tr><td>207</td><td>1</td><td>60</td><td>325</td></tr>
<tr><td>208</td><td>1</td><td>60</td><td>390</td></tr>
<tr><td>209</td><td>1</td><td>60</td><td>455</td></tr>
<tr><td>210</td><td>1</td><td>60</td><td>520</td></tr>
<tr><td>211</td><td>1</td><td>60</td><td>585</td></tr>
<tr><td>212</td><td>1</td><td>60</td><td>650</td></tr>
<tr><td>213</td><td>1</td><td>60</td><td>714</td></tr>
<tr><td>214</td><td>1</td><td>60</td><td>780</td></tr>
<tr><td>303</td><td>1</td><td>60</td><td>65</td></tr>
<tr><td>304</td><td>1</td><td>60</td><td>130</td></tr>
<tr><td>305</td><td>1</td><td>60</td><td>195</td></tr>
<tr><td>306</td><td>1</td><td>60</td><td>260</td></tr>
<tr><td>503</td><td>1</td><td>60</td><td>65</td></tr>
<tr><td>504</td><td>1</td><td>60</td><td>130</td></tr>
<tr><td>505</td><td>1</td><td>60</td><td>195</td></tr>
<tr><td>506</td><td>1</td><td>60</td><td>260</td></tr>
<tr><td>507</td><td>1</td><td>60</td><td>325</td></tr>
<tr><td>508</td><td>1</td><td>60</td><td>390</td></tr>
<tr><td>509</td><td>1</td><td>60</td><td>455</td></tr>
<tr><td>510</td><td>1</td><td>60</td><td>520</td></tr>
<tr><td>511</td><td>1</td><td>60</td><td>585</td></tr>
<tr><td>512</td><td>1</td><td>60</td><td>650</td></tr>
<tr><td>513</td><td>1</td><td>60</td><td>714</td></tr>
<tr><td>603</td><td>1</td><td>60</td><td>65</td></tr>
<tr><td>604</td><td>1</td><td>60</td><td>130</td></tr>
<tr><td>605</td><td>1</td><td>60</td><td>195</td></tr>
<tr><td>606</td><td>1</td><td>60</td><td>260</td></tr>
<tr><td>903</td><td>1</td><td>60</td><td>65</td></tr>
<tr><td>904</td><td>1</td><td>60</td><td>130</td></tr>
<tr><td>905</td><td>1</td><td>60</td><td>195</td></tr>
<tr><td>906</td><td>1</td><td>60</td><td>260</td></tr>
<tr><td>907</td><td>1</td><td>60</td><td>325</td></tr>
<tr><td>908</td><td>1</td><td>60</td><td>390</td></tr>
<tr><td>909</td><td>1</td><td>60</td><td>455</td></tr>
<tr><td>1303</td><td>1</td><td>60</td><td>65</td></tr>
<tr><td>1304</td><td>1</td><td>60</td><td>130</td></tr>
<tr><td>1305</td><td>1</td><td>60</td><td>195</td></tr>
<tr><td>1306</td><td>1</td><td>60</td><td>260</td></tr>
<tr><td>1307</td><td>1</td><td>60</td><td>325</td></tr>
<tr><td>1308</td><td>1</td><td>60</td><td>390</td></tr>
<tr><td>1309</td><td>1</td><td>60</td><td>455</td></tr>
<tr><td>1310</td><td>1</td><td>60</td><td>520</td></tr>
<tr><td>1403</td><td>1</td><td>60</td><td>65</td></tr>
<tr><td>1404</td><td>1</td><td>60</td><td>130</td></tr>
<tr><td>1405</td><td>1</td><td>60</td><td>195</td></tr>
<tr><td>1406</td><td>1</td><td>60</td><td>260</td></tr>
<tr><td>1803</td><td>1</td><td>60</td><td>65</td></tr>
<tr><td>1804</td><td>1</td><td>60</td><td>130</td></tr>
<tr><td>1805</td><td>1</td><td>60</td><td>195</td></tr>
<tr><td>1806</td><td>1</td><td>60</td><td>260</td></tr>
<tr><td>1807</td><td>1</td><td>60</td><td>325</td></tr>
<tr><td>1808</td><td>1</td><td>60</td><td>390</td></tr>
<tr><td>1809</td><td>1</td><td>60</td><td>455</td></tr>
<tr><td>1810</td><td>1</td><td>60</td><td>520</td></tr>
<tr><td>1811</td><td>1</td><td>60</td><td>585</td></tr>
<tr><td>203</td><td>61</td><td>120</td><td>53</td></tr>
<tr><td>204</td><td>61</td><td>120</td><td>106</td></tr>
<tr><td>205</td><td>61</td><td>120</td><td>159</td></tr>
<tr><td>206</td><td>61</td><td>120</td><td>212</td></tr>
<tr><td>207</td><td>61</td><td>120</td><td>265</td></tr>
<tr><td>208</td><td>61</td><td>120</td><td>318</td></tr>
<tr><td>209</td><td>61</td><td>120</td><td>371</td></tr>
<tr><td>210</td><td>61</td><td>120</td><td>424</td></tr>
<tr><td>211</td><td>61</td><td>120</td><td>477</td></tr>
<tr><td>212</td><td>61</td><td>120</td><td>530</td></tr>
<tr><td>213</td><td>61</td><td>120</td><td>583</td></tr>
<tr><td>214</td><td>61</td><td>120</td><td>636</td></tr>
<tr><td>303</td><td>61</td><td>120</td><td>53</td></tr>
<tr><td>304</td><td>61</td><td>120</td><td>106</td></tr>
<tr><td>305</td><td>61</td><td>120</td><td>159</td></tr>
<tr><td>306</td><td>61</td><td>120</td><td>212</td></tr>
<tr><td>503</td><td>61</td><td>120</td><td>53</td></tr>
<tr><td>504</td><td>61</td><td>120</td><td>106</td></tr>
<tr><td>505</td><td>61</td><td>120</td><td>159</td></tr>
<tr><td>506</td><td>61</td><td>120</td><td>212</td></tr>
<tr><td>507</td><td>61</td><td>120</td><td>265</td></tr>
<tr><td>508</td><td>61</td><td>120</td><td>318</td></tr>
<tr><td>509</td><td>61</td><td>120</td><td>371</td></tr>
<tr><td>510</td><td>61</td><td>120</td><td>424</td></tr>
<tr><td>511</td><td>61</td><td>120</td><td>477</td></tr>
<tr><td>512</td><td>61</td><td>120</td><td>530</td></tr>
<tr><td>513</td><td>61</td><td>120</td><td>583</td></tr>
<tr><td>603</td><td>61</td><td>120</td><td>53</td></tr>
<tr><td>604</td><td>61</td><td>120</td><td>106</td></tr>
<tr><td>605</td><td>61</td><td>120</td><td>159</td></tr>
<tr><td>606</td><td>61</td><td>120</td><td>212</td></tr>
<tr><td>903</td><td>61</td><td>120</td><td>53</td></tr>
<tr><td>904</td><td>61</td><td>120</td><td>106</td></tr>
<tr><td>905</td><td>61</td><td>120</td><td>159</td></tr>
<tr><td>906</td><td>61</td><td>120</td><td>212</td></tr>
<tr><td>907</td><td>61</td><td>120</td><td>265</td></tr>
<tr><td>908</td><td>61</td><td>120</td><td>318</td></tr>
<tr><td>909</td><td>61</td><td>120</td><td>371</td></tr>
<tr><td>1303</td><td>61</td><td>120</td><td>53</td></tr>
<tr><td>1304</td><td>61</td><td>120</td><td>106</td></tr>
<tr><td>1305</td><td>61</td><td>120</td><td>159</td></tr>
<tr><td>1306</td><td>61</td><td>120</td><td>212</td></tr>
<tr><td>1307</td><td>61</td><td>120</td><td>265</td></tr>
<tr><td>1308</td><td>61</td><td>120</td><td>318</td></tr>
<tr><td>1309</td><td>61</td><td>120</td><td>371</td></tr>
<tr><td>1310</td><td>61</td><td>120</td><td>424</td></tr>
<tr><td>1403</td><td>61</td><td>120</td><td>53</td></tr>
<tr><td>1404</td><td>61</td><td>120</td><td>106</td></tr>
<tr><td>1405</td><td>61</td><td>120</td><td>159</td></tr>
<tr><td>1406</td><td>61</td><td>120</td><td>212</td></tr>
<tr><td>1803</td><td>61</td><td>120</td><td>53</td></tr>
<tr><td>1804</td><td>61</td><td>120</td><td>106</td></tr>
<tr><td>1805</td><td>61</td><td>120</td><td>159</td></tr>
<tr><td>1806</td><td>61</td><td>120</td><td>212</td></tr>
<tr><td>1807</td><td>61</td><td>120</td><td>265</td></tr>
<tr><td>1808</td><td>61</td><td>120</td><td>318</td></tr>
<tr><td>1809</td><td>61</td><td>120</td><td>371</td></tr>
<tr><td>1810</td><td>61</td><td>120</td><td>424</td></tr>
<tr><td>1811</td><td>61</td><td>120</td><td>477</td></tr>
<tr><td>203</td><td>121</td><td>999</td><td>35</td></tr>
<tr><td>204</td><td>121</td><td>999</td><td>70</td></tr>
<tr><td>205</td><td>121</td><td>999</td><td>105</td></tr>
<tr><td>206</td><td>121</td><td>999</td><td>140</td></tr>
<tr><td>207</td><td>121</td><td>999</td><td>175</td></tr>
<tr><td>208</td><td>121</td><td>999</td><td>210</td></tr>
<tr><td>209</td><td>121</td><td>999</td><td>245</td></tr>
<tr><td>210</td><td>121</td><td>999</td><td>280</td></tr>
<tr><td>211</td><td>121</td><td>999</td><td>315</td></tr>
<tr><td>212</td><td>121</td><td>999</td><td>350</td></tr>
<tr><td>213</td><td>121</td><td>999</td><td>385</td></tr>
<tr><td>214</td><td>121</td><td>999</td><td>420</td></tr>
<tr><td>303</td><td>121</td><td>999</td><td>35</td></tr>
<tr><td>304</td><td>121</td><td>999</td><td>70</td></tr>
<tr><td>305</td><td>121</td><td>999</td><td>105</td></tr>
<tr><td>306</td><td>121</td><td>999</td><td>140</td></tr>
<tr><td>503</td><td>121</td><td>999</td><td>35</td></tr>
<tr><td>504</td><td>121</td><td>999</td><td>70</td></tr>
<tr><td>505</td><td>121</td><td>999</td><td>105</td></tr>
<tr><td>506</td><td>121</td><td>999</td><td>140</td></tr>
<tr><td>507</td><td>121</td><td>999</td><td>175</td></tr>
<tr><td>508</td><td>121</td><td>999</td><td>210</td></tr>
<tr><td>509</td><td>121</td><td>999</td><td>245</td></tr>
<tr><td>510</td><td>121</td><td>999</td><td>280</td></tr>
<tr><td>511</td><td>121</td><td>999</td><td>315</td></tr>
<tr><td>512</td><td>121</td><td>999</td><td>350</td></tr>
<tr><td>513</td><td>121</td><td>999</td><td>385</td></tr>
<tr><td>603</td><td>121</td><td>999</td><td>35</td></tr>
<tr><td>604</td><td>121</td><td>999</td><td>70</td></tr>
<tr><td>605</td><td>121</td><td>999</td><td>105</td></tr>
<tr><td>606</td><td>121</td><td>999</td><td>140</td></tr>
<tr><td>903</td><td>121</td><td>999</td><td>35</td></tr>
<tr><td>904</td><td>121</td><td>999</td><td>70</td></tr>
<tr><td>905</td><td>121</td><td>999</td><td>105</td></tr>
<tr><td>906</td><td>121</td><td>999</td><td>140</td></tr>
<tr><td>907</td><td>121</td><td>999</td><td>175</td></tr>
<tr><td>908</td><td>121</td><td>999</td><td>210</td></tr>
<tr><td>909</td><td>121</td><td>999</td><td>245</td></tr>
<tr><td>1303</td><td>121</td><td>999</td><td>35</td></tr>
<tr><td>1304</td><td>121</td><td>999</td><td>70</td></tr>
<tr><td>1305</td><td>121</td><td>999</td><td>105</td></tr>
<tr><td>1306</td><td>121</td><td>999</td><td>140</td></tr>
<tr><td>1307</td><td>121</td><td>999</td><td>175</td></tr>
<tr><td>1308</td><td>121</td><td>999</td><td>210</td></tr>
<tr><td>1309</td><td>121</td><td>999</td><td>245</td></tr>
<tr><td>1310</td><td>121</td><td>999</td><td>280</td></tr>
<tr><td>1403</td><td>121</td><td>999</td><td>35</td></tr>
<tr><td>1404</td><td>121</td><td>999</td><td>70</td></tr>
<tr><td>1405</td><td>121</td><td>999</td><td>105</td></tr>
<tr><td>1406</td><td>121</td><td>999</td><td>140</td></tr>
<tr><td>1803</td><td>121</td><td>999</td><td>35</td></tr>
<tr><td>1804</td><td>121</td><td>999</td><td>70</td></tr>
<tr><td>1805</td><td>121</td><td>999</td><td>105</td></tr>
<tr><td>1806</td><td>121</td><td>999</td><td>140</td></tr>
<tr><td>1807</td><td>121</td><td>999</td><td>175</td></tr>
<tr><td>1808</td><td>121</td><td>999</td><td>210</td></tr>
<tr><td>1809</td><td>121</td><td>999</td><td>245</td></tr>
<tr><td>1810</td><td>121</td><td>999</td><td>280</td></tr>
<tr><td>1811</td><td>121</td><td>999</td><td>315</td></tr>
</tbody></table></div>
<p><a href="../../../../../assets/recovered-source/CardItemProduceConfig_more.json">完整数据</a> · <a href="../../../../../assets/recovered-source/CardItemProduceConfig_more.lua">恢复配置</a></p>
</details>

<details><summary>CardItemProduceConfig_zero：1条完整记录</summary>
<div style="overflow-x:auto;"><table><thead><tr><th>ItemType</th><th>LevelMin</th><th>LevelMax</th><th>Chance</th></tr></thead><tbody>
<tr><td>203</td><td>1</td><td>999</td><td>0</td></tr>
</tbody></table></div>
<p><a href="../../../../../assets/recovered-source/CardItemProduceConfig_zero.json">完整数据</a> · <a href="../../../../../assets/recovered-source/CardItemProduceConfig_zero.lua">恢复配置</a></p>
</details>

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

<!-- source-links:start -->

## 对应源码

[GeneratorBoostActivityModel.lua](../../../../assets/recovered-source/GeneratorBoostActivityModel.lua) · [MainBoardModel.lua](../../../../assets/recovered-source/MainBoardModel.lua) · [ScoreRushModel.lua](../../../../assets/recovered-source/ScoreRushModel.lua) · [TriggerPlaneModel.lua](../../../../assets/recovered-source/TriggerPlaneModel.lua) · [TriggerBoostModel.lua](../../../../assets/recovered-source/TriggerBoostModel.lua) · [TriggerProgressActivityModel.lua](../../../../assets/recovered-source/TriggerProgressActivityModel.lua) · [HitBricksActivityModel.lua](../../../../assets/recovered-source/HitBricksActivityModel.lua) · [AdventureActivityModel.lua](../../../../assets/recovered-source/AdventureActivityModel.lua) · [ItemClickAcquireModule.lua](../../../../assets/recovered-source/ItemClickAcquireModule.lua) · [CardItemModel.lua](../../../../assets/recovered-source/CardItemModel.lua) · [RoomModel.lua](../../../../assets/recovered-source/RoomModel.lua) · [TokenChainActivityModel.lua](../../../../assets/recovered-source/TokenChainActivityModel.lua) · [ActivityModuleManager.lua](../../../../assets/recovered-source/ActivityModuleManager.lua) · [ConfigModel.lua](../../../../assets/recovered-source/ConfigModel.lua) · [BootRequire.lua](../../../../assets/recovered-source/BootRequire.lua)

<!-- source-links:end -->
