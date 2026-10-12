# 奖励、价格和活动副作用顺序

普通订单完成时先读取并深拷贝完成瞬间的奖励快照，再依次发放主奖励、亲密度礼物、Buff 奖励；之后处理 OrderBoost 分数/标记，写入订单 Finished 状态，才扣需求棋子。扣除之后再尝试 CookingFrenzy、ChestCustomer 副作用和延迟奖励。

`MainOrder:GetPrice` 按需求顺序读取 `OrderItemConfig.Price` 并累加，重复需求重复计价；基准订单在配置有 `RecommendedPrice` 时使用推荐价。金币数量为 `ceil(price * multiplier)`，BuffGold 将倍率设为 2；特定亲密度订单可能改发其它奖励属性。奖励发放在需求扣除之前，源码没有事务回滚，扣除异常只记录错误。

**源码**：`MainBoardModel:FinishOrder`、`MainOrder:GetPrice`、`MainOrder:GetRewards`、`GetOrderRewardByFinishOrder`。活动实际奖励值标记为 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
