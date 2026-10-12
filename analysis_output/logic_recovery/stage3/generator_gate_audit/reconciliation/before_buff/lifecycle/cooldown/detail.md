# CD、恢复计时与 Buff 资格

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

<!-- reconciliation-persistence:start -->
## 冷却起点怎样保存、清除和恢复

每次 SaveItemProperty 都重填该棋子的整组运行字段。ItemManager:SetItem先批量写字段，再检查本次spreadStartTimer是否为nil；若为nil，显式Remove(id,"spreadStartTimer")。Lua的pairs不会遍历nil字段，若只做批量更新，旧计时起点会残留，因此不能省略这条删除。没有计时的母体不是起点0，也不能将原有时间继续保留。

DBTable批量写入会更新内存缓存，并将数据同步标记设false、缓存变化标记设true；非JSON模式另外排队数据库命令。Remove成功后同样标记变化，并在非JSON模式排队删行或单列更新。这里是请求保存与缓存变化，不能解释成此刻已经完成原生磁盘提交或服务器确认。

重载时spreadStartTimer原样回写实例。恢复进度用当前服务器时间减保存的起点，当前配置决定阶段时长；不把重新登录的时间作为新的起点。有起点且加速生效时，先修正起点并保存；到期再恢复并保存。无起点分支新建计时后立即返回，所以第一次调用只开始计时，不在同一次调用里检查它是否已完成。

### 保存与恢复的具体例子

假设食品袋105当前Opened、次数0、储备10、起点1000，存档对应spreadState=3、spreadItemRestNumber=0、spreadStorageRestNumber=10、spreadStartTimer=1000。1030重载后仍是这组值；UpdatePerSecond按30秒单轮恢复补到80次，储备截为0，起点推进到1030。1090储备恢复结束，次数80、储备240，起点nil；SetItem显式移除spreadStartTimer列。再次重载时起点为nil，不会重复执行旧冷却。

<!-- reconciliation-persistence:end -->

---

<!-- reconciliation-reload:start -->
## 邻近加速如何影响母体计时

ItemAccelerateTime初始化m_time=0、m_lastUpdateTime=0。UpdateAccelerateTime扫描母体八个邻格，只取存在且已激活的ItemAccelerate，计算每个邻格的起点加时长，并取最晚结束时间；多枚加速物不会在这一步累加倍率。最晚结束时间不大于当前服务器时间，就改为0。

旧m_time或新时间任一非0时，保存lastUpdateTime=当前时间、m_time=新时间并请求SaveItemProperty；两者都0不写这两个字段。无论是否保存，最后都发组件UpdateView。IsAccelerated仅比较m_time是否非0，不再比较当前时间；过期标记的清理依赖UpdateAccelerateTime调用，不能将这个getter自行改成时间比较。

母体随后推进冷却时，以min(加速结束时间,当前时间)封顶修正计时起点，所以仅结算有效加速区间。例如起点990、当前1000、上次更新时间995、加速结束1005：新起点=990+995-1000=985；本次恢复进度按15秒而非10秒计算。加速结束与上次更新时间保存在accelerateTime、accelerateLastUpdateTime，恢复对象分别用存档值和原样字段覆盖；加速结束缺值时默认0。

<!-- reconciliation-reload:end -->

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：食品袋105未满次数时开始恢复计时；等待到期补次数并扣储备。下面用一次整轮耗尽说明储备恢复如何接续，额外Buff例子只作为条件对照。

### 代入本页的值

本地105次数上限80、储备240、单轮恢复30秒、储备恢复60秒。假设serverTime=1000、次数0、储备10、起点1000：1030单轮到期先补次数到80，储备10-80截到0，起点推进到1030，之后按储备阶段60秒计时。1090储备到期补储备240、次数80并清起点。若CD Buff资格成立且次数为0，另走跳时路径；不是每次点击都无条件清CD。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Sta

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- 母体配置与包内变体：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。


<!-- generator-configs:end -->

<!-- source-links:start -->

## 对应源码

[ItemSpread.lua](../../../../assets/recovered-source/ItemSpread.lua)

<!-- source-links:end -->
