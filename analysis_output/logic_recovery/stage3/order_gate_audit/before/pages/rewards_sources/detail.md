# 奖励来源的底层追加顺序

复刻时应保持 `MainOrder:GetRewards` 的追加顺序，因为 `GetOrderRewardByFinishOrder` 会按奖励属性前缀再拆成即时和延迟两组。主装饰、FloatRace、Album、Avenue、Upward、Road、HitBricks、Ring、Combo 等活动都通过当前活动模型查询订单；返回 `nil` 或非正值时不追加。`ActivityModuleManager:GetRewardsByOrder` 的数组则整体追加，不应当按普通货币合并。

金币分支最后执行：`_HasGoldReward` 过滤亲密度随机订单，`GetFirstRewardPropertyType` 在 BakeOut 可领取代币时返回 BakeOutToken，否则返回 Gold，数量为 `ceil(GetPrice() * (BuffGold and 2 or 1))`，并写入 `Crypt.CryptCurrency`。缺少 `OrderItemConfig` 代码时 `GetPrice` 记录 `cfg_err` 并返回 0。

**源码**：`Board_Model_Order_MainOrder.lua:136-254`、`257-271`、`337-342`；**证据**：追加顺序和公式 `source-confirmed`，活动模型具体数值 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
