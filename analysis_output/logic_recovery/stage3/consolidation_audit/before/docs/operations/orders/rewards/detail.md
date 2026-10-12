# 奖励、价格和活动副作用顺序

普通订单完成时先读取并深拷贝完成瞬间的奖励快照，再依次发放主奖励、亲密度礼物、Buff 奖励；之后处理 OrderBoost 分数/标记，写入订单 Finished 状态，才扣需求棋子。扣除之后再尝试 CookingFrenzy、ChestCustomer 副作用和延迟奖励。

`MainOrder:GetPrice` 按需求顺序读取 `OrderItemConfig.Price` 并累加，重复需求重复计价；基准订单在配置有 `RecommendedPrice` 时使用推荐价。金币数量为 `ceil(price * multiplier)`，BuffGold 将倍率设为 2；特定亲密度订单可能改发其它奖励属性。奖励发放在需求扣除之前，源码没有事务回滚，扣除异常只记录错误。

**源码**：`MainBoardModel:FinishOrder`、`MainOrder:GetPrice`、`MainOrder:GetRewards`、`GetOrderRewardByFinishOrder`。活动实际奖励值标记为 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
