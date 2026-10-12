# 额外顾客：创建空需求入口并保存活动标记：具体算法与配置

仅槽19，活动Started且eTime−now≥3600；HasActiveOrder真拒绝，主盘槽19已有任何订单对象拒绝。有冷却值时仅now>coolDown允许，等于时拒绝；无冷却值允许。Create再检查槽19，依次SaveHasActiveOrder(true)、SaveNeedBanner(true)、SaveNeedAutoPopTip(true)、SaveFirstAppear(true)，删CoolDownTime与LimitTime，创建EmptyReqOrder槽19、Idnil、需求{}、内部21、头像3001、Luckyfalse。后续外层给Random大类生成Id并添加礼物，派创建事件，再由Slot保存对象。四个保存函数与EmptyReqOrder活动奖励/入口覆盖是活动独立状态链，不可用普通空需求CanDeliver=true推断最终活动交付奖励。

EmptyReqOrder明确覆盖空需求：Init标Dormant；Dormant时CanDeliver=false、GetRewards为空、GetBuffRewards/GetCookingFrenzyConfig=nil、GetScore/GetDiffScore为0，所以不会用BaseOrder空数组通过来直接交付。TryRefreshMyRequirements先调用普通随机构造；有对象且需求非空才UpdateRequirements并记refresh日志；对象非nil但空需求时无兜底。只有构造nil才用传入defaultReq或Flour12=212，更新需求、日志并记错误。它只更新旧对象需求，不把临时随机对象整个保存替换。

## 源码依据

- ExtraCustomerActivity.Model.ExtraCustomerActivityModel：[恢复源码](../../../../assets/order-evidence/ExtraCustomerActivity.Model.ExtraCustomerActivityModel.lua) · [原始指令](../../../../assets/order-evidence/ExtraCustomerActivity.Model.ExtraCustomerActivityModel.disassembly.txt)。对应：ExtraCustomerActivityModel:CanCreateOrder（恢复文本行70）；ExtraCustomerActivityModel:CreateOrder（恢复文本行107）；ExtraCustomerActivityModel:SaveNeedAutoPopTip（恢复文本行212）；ExtraCustomerActivityModel:SaveHasActiveOrder（恢复文本行220）；ExtraCustomerActivityModel:SaveFirstAppear（恢复文本行247）；ExtraCustomerActivityModel:SaveNeedBanner（恢复文本行259）

- Board.Model.Order.EmptyReqOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.EmptyReqOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.EmptyReqOrder.disassembly.txt)

- Board.Model.Order.MainOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.disassembly.txt)


---

## 贯穿案例：203×2与204×1，使用仓库补交

主例槽1普通交付跳过这条专用创建；全槽扫描时槽19仅符合活动资格才创建空需求入口。

### 代入本页的值

对照剩余3600秒允许，3599秒拒绝；coolDown=1000、now1000拒绝、1001允许。这些边界来自比较运算，不是猜测。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
