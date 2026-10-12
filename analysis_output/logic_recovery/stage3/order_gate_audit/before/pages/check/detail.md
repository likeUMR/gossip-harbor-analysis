# 重复需求与计数来源

普通订单按钮先要求 `m_bGoButtonEnabled`，再调用 `GetCodeCountMap(true,false,false)`；这三个参数的含义是只计棋盘，不计缓存和仓库。`BaseOrder:CanDeliver` 按需求原始顺序逐项检查：第 i 项先统计它在前 i 项中出现了几次，再要求代码数量至少达到这个序号。因此 `[203,203,204]` 要求 203 两个、204 一个，不能转成去重集合。

棋盘不足时入口打开仓库确认窗口；普通成功路径才进入 `FinishOrder`。显示层的 `CanDeliver` 状态只来自订单状态刷新，不能当作扣除已经完成的证明。

**源码**：`BaseOrderCell:OnGoButtonClicked`、`BaseOrder:CanDeliver`、`BaseBoardModel:GetCodeCountMap`。重复需求和入口计数口径为 `source-confirmed`。

---

## 贯穿案例：提交单需求订单


讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
