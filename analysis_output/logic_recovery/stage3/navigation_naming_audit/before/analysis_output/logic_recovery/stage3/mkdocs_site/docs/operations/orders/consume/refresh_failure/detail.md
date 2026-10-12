# 逐件刷新与部分失败边界：具体算法与配置

每项扫描结束无论itemRemoved真假都CountItemsCode→UpdateOrderState；失败额外LogErrorInfo(FinishOrderRemoveItemError,requirement)，不抛显式异常、不终止循环、不还奖、不恢复已删物。返回RemovedFromBoard/Inventory稀疏映射。MainBoardModel普通入口未再次CanDeliver；窗口只ContainsOrder。这些事实可产生缺物时部分完成的代码路径，但原版用户是否能通过并发输入到达还需运行观察。UpdateOrderState调用刷新各订单填充与代码需求；Finished订单UpdateState直接跳过，其它订单可能从可交付降级。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:UpdateOrderState（恢复文本行975）；MainBoardModel:RemoveOrderRequirementItems（恢复文本行1164）

- Board.Model.Order.BaseOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.BaseOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.BaseOrder.disassembly.txt)。对应：BaseOrder:UpdateState（恢复文本行82）

- Board.Model.Order.BaseOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.BaseOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.BaseOrderModel.disassembly.txt)。对应：BaseOrderModel:UpdateState（恢复文本行30）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：确认后第三件丢失

**完整输入（演示设定）：** 普通槽1订单需求按序203、203、204；棋盘(1,1)/(2,1)各裸203，仓库索引1裸204，缓存空；等级10，Gold100、Energy10、TotalDiff100。203价格2/难度2，204价格4/难度5。玩家确认后、实际扣除前，仓库204已经不在；代码仍进入普通提交，金币已发。

**按执行顺序代入：** 第1/2项删203成功；第3项棋盘/仓库均无→LogError(FinishOrderRemoveItemError,204)；Count/Update各3次；RemovedInventory[3]缺省。

**玩家看到的结果：** 两件203消耗、订单仍完成、金币仍108；204缺失被记录，没有自动补物或退回奖励。
