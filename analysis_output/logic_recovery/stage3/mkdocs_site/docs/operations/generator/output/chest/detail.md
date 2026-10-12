# ChestCustomItem 的预算、订单选择和降级算法

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

**证据**：ItemSpread `_GenerateItemCode` 的 ChestCustomItem 分支；RandomGenerateCodeHelper `GenerateChestCustomCodeRule` / `_PickItems_old`。下方源码链接对应本页解释的实现；实际配表分组由配置装载决定。配表完整记录保留在本页下方。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-204.png" alt="本页分支对照中实际选中的四级产物204" class="case-icon" style="width:88px;height:88px;object-fit:contain;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：105是Fixed，主例不执行宝箱算法。用实际宝箱main_super_ball_1作分支对照，说明候选列表可有多件，点击只使用第一件。

### 代入本页的值

本地main_super_ball_1模式4、初始分值450。假设使用后剩S=10、唯一未完成订单缺204与205、库存均0；默认OrderItemConfig中两者DiffScore为5、10，总缺分15。10+10≥15，候选列表[204,205]、算法内部预算−5；外层本次只取204，扣5，宝箱实际剩5，只落一件204。母体字段与分值来自本地表，剩余状态和订单是演示输入；不能套给食品袋105。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- source-links:start -->

## 对应源码

[ItemSpread.lua](../../../../assets/recovered-source/ItemSpread.lua) · [RandomGenerateCodeHelper.lua](../../../../assets/recovered-source/RandomGenerateCodeHelper.lua)

<!-- source-links:end -->

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- [产物难度分与解锁配置](../order/detail.md#configuration-order-item)：配表文件/字段：`OrderItemConfig.json；OrderItemConfig_shell/hard/nerf/nerf_more/extracust`；ItemSpread:GetOrderItemCode 读取 Slot:GetItemCodeConfigMap()[code].DiffScore；ChestCustomItem 与 SmartItem 复用同一个代码配置映射。
- [母体配置与包内变体](../../state/model/detail.md#configuration-item-model)：配表文件/字段：`ItemModelConfig.json；ItemModelConfig_shell/carditem2/extracust`；ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。


<!-- generator-configs:end -->

