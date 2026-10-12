# 额外顾客入口：具体算法与配置

仅槽19，活动Started且eTime−now≥3600；HasActiveOrder真拒绝，主盘槽19已有任何订单对象拒绝。有冷却值时仅now>coolDown允许，等于时拒绝；无冷却值允许。Create再检查槽19，依次SaveHasActiveOrder(true)、SaveNeedBanner(true)、SaveNeedAutoPopTip(true)、SaveFirstAppear(true)，删CoolDownTime与LimitTime，创建EmptyReqOrder槽19、Idnil、需求{}、内部21、头像3001、Luckyfalse。后续外层给Random大类生成Id并添加礼物，派创建事件，再由Slot保存对象。四个保存函数与EmptyReqOrder活动奖励/入口覆盖是活动独立状态链，不可用普通空需求CanDeliver=true推断最终活动交付奖励。

EmptyReqOrder明确覆盖空需求：Init标Dormant；Dormant时CanDeliver=false、GetRewards为空、GetBuffRewards/GetCookingFrenzyConfig=nil、GetScore/GetDiffScore为0，所以不会用BaseOrder空数组通过来直接交付。TryRefreshMyRequirements先调用普通随机构造；有对象且需求非空才UpdateRequirements并记refresh日志；对象非nil但空需求时无兜底。只有构造nil才用传入defaultReq或Flour12=212，更新需求、日志并记错误。它只更新旧对象需求，不把临时随机对象整个保存替换。

## 源码依据

- ExtraCustomerActivity.Model.ExtraCustomerActivityModel：[恢复源码](../../../../assets/order-evidence/ExtraCustomerActivity.Model.ExtraCustomerActivityModel.lua) · [原始指令](../../../../assets/order-evidence/ExtraCustomerActivity.Model.ExtraCustomerActivityModel.disassembly.txt)。对应：ExtraCustomerActivityModel:CanCreateOrder（恢复文本行70）；ExtraCustomerActivityModel:CreateOrder（恢复文本行107）；ExtraCustomerActivityModel:SaveNeedAutoPopTip（恢复文本行212）；ExtraCustomerActivityModel:SaveHasActiveOrder（恢复文本行220）；ExtraCustomerActivityModel:SaveFirstAppear（恢复文本行247）；ExtraCustomerActivityModel:SaveNeedBanner（恢复文本行259）

- Board.Model.Order.EmptyReqOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.EmptyReqOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.EmptyReqOrder.disassembly.txt)

- Board.Model.Order.MainOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.disassembly.txt)


---

## 演示案例

下面分别改变前提，让各条分支实际发生；互斥结果属于不同场景。

### 场景1：创建额外顾客入口

**完整输入（演示设定）：** 槽19空，活动Started，now1001、eTime5000、coolDown1000，HasActiveOrder=false；其它创建器在本槽未创建。

**按执行顺序代入：** 5000−1001=3999≥3600、1001>1000；Active/Banner/AutoPop/FirstAppear均设true，删冷却和LimitTime；EmptyReqOrder19/inner21/avatar3001；Dormant且CanDeliver=false。

**玩家看到的结果：** 出现额外顾客入口和提示，当前没有可交付需求；不会因需求为空而立即发奖。

### 场景2：入口刷新无候选的兜底

**完整输入（演示设定）：** 沿用上个入口，假设TryRefreshMyRequirements调用普通构造返回nil，调用者未传defaultReq。

**按执行顺序代入：** newOrder=nil→defaultReq or Flour12=212；UpdateRequirements([212])并记refresh日志和错误；保留原入口对象。

**玩家看到的结果：** 该顾客改为要求一件212；当前只刷新需求，没有凭刷新发奖励。
