# 完成日志与多轮补位：具体算法与配置

Slot.FinishOrder：ContainsOrder假returnfalse；SetFinished→_LogOrderAction(finish)→_TryFillOrders→OrderFinished{order}→returntrue。_TryFillOrders repeat：slot=1..m_slotCount(主盘19)，nil/Finished才处理，有旧单_RemoveOrder并置nil，_TryCreateOrder成功则DBAdd→m_orders[slot]=new→加入arrNewOrders，hasFilledOrderOnce=true；until not。至少一次成功才UpdateOrderState并按创建顺序逐条unlock日志；无成功不做这次内部刷新，但主盘尾部仍刷新。MainOrderCreated在_tryCreate返回之前派发，此时新单尚未写入m_orders；不能把它的消费者看到的集合当作DBAdd之后状态。

## 源码依据

- Board.Model.Order.SlotOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.SlotOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.SlotOrderModel.disassembly.txt)。对应：SlotOrderModel:_TryFillOrders（恢复文本行29）；SlotOrderModel:_TryCreateOrder（恢复文本行61）；SlotOrderModel:FinishOrder（恢复文本行65）

- Board.Model.Order.MainOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.disassembly.txt)。对应：MainOrderModel:_TryCreateOrder（恢复文本行527）；MainOrderModel:FinishOrder（恢复文本行560）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：补位成功再扫描一轮

**完整输入（演示设定）：** 假设19槽中只有槽1为Finished、槽2为空，其它槽有有效订单；本次槽1创建失败且无永久可创建分支，槽2创建成功为需求503单。

**按执行顺序代入：** 轮1移除槽1旧单，槽1nil；槽2成功→DBAdd一次；轮2槽1仍失败、其余已占→hasFilled=false停止；更新状态并派OrderFinished。

**玩家看到的结果：** 槽2出现需求503的新顾客，槽1暂时空着；本次没有无限尝试，也没有重复保存槽2订单。
