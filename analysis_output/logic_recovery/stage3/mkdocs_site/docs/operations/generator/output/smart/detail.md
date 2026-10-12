# SmartItem 的订单缺口、预算与单件限制

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

---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：105主例不是SmartItem，不会进入此分值算法。独立SmartItem对照说明按二进制缺口补一件，而不是调整抽奖权重。

### 代入本页的值

假设仅一个有效订单缺205（五级），已有同链204一件（八个一级等价），其余库存0；需要16，扣现有8，缺口N=8（二进制1000），对应204。假设缓存分值204=8、205=18，母体预算20，SupplyScore=8；发204后resultCount从1变0，算法预算12，外层也按8扣母体到12。分值、库存及SmartItem母体为对照输入，105本地仍是Fixed。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [产物难度分与解锁配置](../order/detail.md#configuration-order-item)：ItemSpread:GetOrderItemCode 读取 Slot:GetItemCodeConfigMap()[code].DiffScore；ChestCustomItem 与 SmartItem 复用同一个代码配置映射。
- [母体配置与包内变体](../../state/model/detail.md#configuration-item-model)：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。


<!-- generator-configs:end -->
