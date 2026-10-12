# 奖励来源与配置字段

`MainOrder:GetRewards` 按固定代码顺序追加奖励：主装饰活动代币、FloatRace 分数、TimedOrder 专属奖励/相册跳过标记、Album 奖励（相册 Buff 可翻倍）、Avenue、Upward、Road、HitBricks、Ring、Combo、`ActivityModuleManager:GetRewardsByOrder`、ChestCustomer 延迟奖励标记，最后才追加 Gold 或 BakeOutToken。

价格逐条读取 `OrderItemConfig.Price`；基准订单若存在 `RecommendedPrice` 则使用该字段。涉及的配置字段包括 `Code`、`Price`、`RecommendedPrice`、`DiffScore`、`RecommendedNumber`、活动 token property type，以及各活动模型自己的 `GetAddScoreByOrder` 配置。缺失 Code 配置时记录 `cfg_err` 并把价格返回为 0。

`GetOrderRewardByFinishOrder` 将 `ChestCustomerModel.RewardKey` 前缀奖励移到延迟映射；它们在需求扣除后另行发放。奖励快照在完成前深拷贝，订单完成后从 `m_cacheRewards` 读取。

**源码**：`Board_Model_Order_MainOrder.lua:106-271`、`Board_Model_Board_MainBoardModel.lua:1109-1144`。奖励具体数值受活动状态影响，标为 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
