# 订单提交

UI 入口 `BaseOrderCell:OnGoButtonClicked` 先获取代码数量并调用 `BaseOrder:CanDeliver`；不足时进入确认流程，足够时调用 `MainBoardModel:FinishOrder`。

- [可交付判断](check.md)
- [奖励结算](rewards.md)
- [需求扣除](remove.md)
- [订单完成、补位与同步](finish.md)

---

## 贯穿案例：提交单需求订单

<div class="case-assets"><img src="../../../assets/cases/order.png" alt="提交单需求订单" class="case-composite" style="display:block;max-width:560px;width:100%;height:auto;"></div>

讲解输入：订单需求 201 × 1，棋盘恰好一件 201。需求检查通过，匹配这件棋子并扣除；实际奖励、订单编号、补位和活动条件必须来自订单实例，当前没有实例快照，不能填假数值。本例用于认识交付链，尚不是完整复刻验收案例。
