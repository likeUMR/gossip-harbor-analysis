# 奖励来源与配置字段

`MainOrder:GetRewards` 按固定代码顺序追加奖励：主装饰活动代币、FloatRace 分数、TimedOrder 专属奖励/相册跳过标记、Album 奖励（相册 Buff 可翻倍）、Avenue、Upward、Road、HitBricks、Ring、Combo、`ActivityModuleManager:GetRewardsByOrder`、ChestCustomer 延迟奖励标记，最后才追加 Gold 或 BakeOutToken。

价格逐条读取 `OrderItemConfig.Price`；基准订单若存在 `RecommendedPrice` 则使用该字段。涉及的配置字段包括 `Code`、`Price`、`RecommendedPrice`、`DiffScore`、`RecommendedNumber`、活动 token property type，以及各活动模型自己的 `GetAddScoreByOrder` 配置。缺失 Code 配置时记录 `cfg_err` 并把价格返回为 0。

`GetOrderRewardByFinishOrder` 将 `ChestCustomerModel.RewardKey` 前缀奖励移到延迟映射；它们在需求扣除后另行发放。奖励快照在完成前深拷贝，订单完成后从 `m_cacheRewards` 读取。

**源码**：`Board_Model_Order_MainOrder.lua:106-271`、`Board_Model_Board_MainBoardModel.lua:1109-1144`。奖励具体数值受活动状态影响，标为 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
