# 再次刷新、提示与同步消息：具体算法与配置

普通FinishOrder尾部UpdateOrderState→triggerButterfly真派SmileOrderDeliver_1→SyncModel.CheckMoreUpload(nil,nil,requirements)→self.event.Call(FinishOrder,{Order,RemoveItemInfo,Rewards,mapDelayRewards})。OrderFinished{order}已在Slot.FinishOrder补位后派发。两者不同事件与payload不能合并；Sync检查不是服务器确认交付响应。本地主流程没有等待网络成功才发局部消息，网络队列/合并与存档协议另属同步模型。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:FinishOrder（恢复文本行1101）

- Board.Model.Order.SlotOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.SlotOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.SlotOrderModel.disassembly.txt)。对应：SlotOrderModel:FinishOrder（恢复文本行65）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：首轮提示与完成消息

**完整输入（演示设定）：** 普通槽1订单需求按序203、203、204；棋盘(1,1)/(2,1)各裸203，仓库索引1裸204，缓存空；等级10，Gold100、Energy10、TotalDiff100。203价格2/难度2，204价格4/难度5。已完成发奖和扣物，补位返回；本例首个普通微笑资格true，奖励快照Gold8，扣物来自棋盘索引1/2和仓库索引3。

**按执行顺序代入：** OrderFinished→UpdateOrderState→SmileOrderDeliver_1→CheckMoreUpload(nil,nil,[203,203,204])→局部FinishOrder；payload Gold8/RemovedBoard1,2/Inventory3。

**玩家看到的结果：** 金币108、三件物品已扣；玩家看到首轮微笑提示，随后进入交付表现，同步检查不会再发8金币。
