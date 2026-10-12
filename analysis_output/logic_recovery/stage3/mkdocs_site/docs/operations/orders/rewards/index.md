# 奖励结算

顺序是特殊/分支订单处理 → 主奖励 → 亲密度礼物 → Buff 奖励 → OrderBoost/CookingFrenzy/ChestCustomer 副作用 → 需求移除 → 延迟奖励。

**配表**：订单奖励、亲密度、Buff、OrderBoost、CookingFrenzy。**源码**：`MainBoardModel:FinishOrder`、`GetOrderRewardByFinishOrder`。服务端奖励覆盖和失败回滚 `runtime-pending`。

---

## 贯穿案例：提交单需求订单


演示假设：订单编号为 order_demo_01，需求为201×1，棋盘恰好有一件201，奖励配置为8金币和5点能量，且有一个空位。流程先匹配并扣除201，再按本页机制结算奖励：金币余额从100变108，能量从10变15；订单标记完成并生成下一订单。以上订单、奖励和库存均为案例输入，用于完整展示判断与结果。
