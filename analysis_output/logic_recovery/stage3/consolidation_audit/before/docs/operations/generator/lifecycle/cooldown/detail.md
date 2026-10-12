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

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：食品袋105未满次数时开始恢复计时；等待到期补次数并扣储备。下面用一次整轮耗尽说明储备恢复如何接续，额外Buff例子只作为条件对照。

### 代入本页的值

本地105次数上限80、储备240、单轮恢复30秒、储备恢复60秒。假设serverTime=1000、次数0、储备10、起点1000：1030单轮到期先补次数到80，储备10-80截到0，起点推进到1030，之后按储备阶段60秒计时。1090储备到期补储备240、次数80并清起点。若CD Buff资格成立且次数为0，另走跳时路径；不是每次点击都无条件清CD。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- source-links:start -->

## 对应源码

[ItemSpread.lua](../../../../assets/recovered-source/ItemSpread.lua)

<!-- source-links:end -->

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [母体配置与包内变体](../../state/model/detail.md#configuration-item-model)：配表文件/字段：`ItemModelConfig.json；ItemModelConfig_shell/carditem2/extracust`；ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。


<!-- generator-configs:end -->

