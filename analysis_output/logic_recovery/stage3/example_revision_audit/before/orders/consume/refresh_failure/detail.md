# 逐件刷新与部分失败边界：具体算法与配置

每项扫描结束无论itemRemoved真假都CountItemsCode→UpdateOrderState；失败额外LogErrorInfo(FinishOrderRemoveItemError,requirement)，不抛显式异常、不终止循环、不还奖、不恢复已删物。返回RemovedFromBoard/Inventory稀疏映射。MainBoardModel普通入口未再次CanDeliver；窗口只ContainsOrder。这些事实可产生缺物时部分完成的代码路径，但原版用户是否能通过并发输入到达还需运行观察。UpdateOrderState调用刷新各订单填充与代码需求；Finished订单UpdateState直接跳过，其它订单可能从可交付降级。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:UpdateOrderState（恢复文本行975）；MainBoardModel:RemoveOrderRequirementItems（恢复文本行1164）

- Board.Model.Order.BaseOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.BaseOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.BaseOrder.disassembly.txt)。对应：BaseOrder:UpdateState（恢复文本行82）

- Board.Model.Order.BaseOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.BaseOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.BaseOrderModel.disassembly.txt)。对应：BaseOrderModel:UpdateState（恢复文本行30）


---

## 贯穿案例：203×2与204×1，使用仓库补交

本例三项都扣到，刷新3次，删除清单完整。对照确认后仓库204消失，会记录第三项错误但Gold8不会自动撤回。

### 代入本页的值

Count/Update各3次；对照第三项失败：Finished仍4，Gold108，RemovedFromInventory[3]缺省。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
