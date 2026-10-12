# 再次刷新、提示与同步消息：具体算法与配置

普通FinishOrder尾部UpdateOrderState→triggerButterfly真派SmileOrderDeliver_1→SyncModel.CheckMoreUpload(nil,nil,requirements)→self.event.Call(FinishOrder,{Order,RemoveItemInfo,Rewards,mapDelayRewards})。OrderFinished{order}已在Slot.FinishOrder补位后派发。两者不同事件与payload不能合并；Sync检查不是服务器确认交付响应。本地主流程没有等待网络成功才发局部消息，网络队列/合并与存档协议另属同步模型。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:FinishOrder（恢复文本行1101）

- Board.Model.Order.SlotOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.SlotOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.SlotOrderModel.disassembly.txt)。对应：SlotOrderModel:FinishOrder（恢复文本行65）


---

## 贯穿案例：203×2与204×1，使用仓库补交

本例没有首轮微笑提示，完成全局事件、尾部刷新、同步检查后才发棋盘完成消息。

### 代入本页的值

局部payload Rewards=Gold8，RemovedFromBoard键1/2，RemovedFromInventory键3，delay={}；Sync参数需求仍[203,203,204]。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
