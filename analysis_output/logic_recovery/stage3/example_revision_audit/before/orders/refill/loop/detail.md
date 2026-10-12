# 完成日志与多轮补位：具体算法与配置

Slot.FinishOrder：ContainsOrder假returnfalse；SetFinished→_LogOrderAction(finish)→_TryFillOrders→OrderFinished{order}→returntrue。_TryFillOrders repeat：slot=1..m_slotCount(主盘19)，nil/Finished才处理，有旧单_RemoveOrder并置nil，_TryCreateOrder成功则DBAdd→m_orders[slot]=new→加入arrNewOrders，hasFilledOrderOnce=true；until not。至少一次成功才UpdateOrderState并按创建顺序逐条unlock日志；无成功不做这次内部刷新，但主盘尾部仍刷新。MainOrderCreated在_tryCreate返回之前派发，此时新单尚未写入m_orders；不能把它的消费者看到的集合当作DBAdd之后状态。

## 源码依据

- Board.Model.Order.SlotOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.SlotOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.SlotOrderModel.disassembly.txt)。对应：SlotOrderModel:_TryFillOrders（恢复文本行29）；SlotOrderModel:_TryCreateOrder（恢复文本行61）；SlotOrderModel:FinishOrder（恢复文本行65）

- Board.Model.Order.MainOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.disassembly.txt)。对应：MainOrderModel:_TryCreateOrder（恢复文本行527）；MainOrderModel:FinishOrder（恢复文本行560）


---

## 贯穿案例：203×2与204×1，使用仓库补交

旧槽1移除；演示补位若槽2先成功、槽1暂失败，下一轮槽1还会尝试。

### 代入本页的值

两轮示例：轮1槽1=nil、槽2=新单；轮2槽1=新单；轮3无新单停止。每成功新单仅DBAdd一次。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
