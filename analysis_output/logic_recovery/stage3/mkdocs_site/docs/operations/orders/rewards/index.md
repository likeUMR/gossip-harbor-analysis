# 奖励结算

顺序是特殊/分支订单处理 → 主奖励 → 亲密度礼物 → Buff 奖励 → OrderBoost/CookingFrenzy/ChestCustomer 副作用 → 需求移除 → 延迟奖励。

**配表**：订单奖励、亲密度、Buff、OrderBoost、CookingFrenzy。**源码**：`MainBoardModel:FinishOrder`、`GetOrderRewardByFinishOrder`。服务端奖励覆盖和失败回滚 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
