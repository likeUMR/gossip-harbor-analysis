# 奖励分组与快照：具体算法与配置

GetOrderRewardByFinishOrder遍历GetRewards，StringUtil.StartWith(type,ChestCustomerModel.RewardKey)为false进targetRewards，为true进otherMapReward[RewardKey]数组；按各组保留原顺序。MainBoardModel随后对rewards与mapDelayRewards分别DeepCopy。完成消息携这两份快照；gift/buff/cooking不是自动写进这份即时快照，而在各自调用位置处理。延迟映射后续以pairs逐组遍历，不能给不同组虚构固定顺序。

## 源码依据

- Board.Model.Order.MainOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrder.disassembly.txt)。对应：MainOrder:GetOrderRewardByFinishOrder（恢复文本行257）

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:FinishOrder（恢复文本行1101）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：即时奖励和宝箱标记分离

**完整输入（演示设定）：** 假设有效奖励顺序为Gold8、合法宝箱顾客标记K×1，K按RewardKey+innerType+"_"+slot构造；本页只演示分组，提交时余额100。

**按执行顺序代入：** 即时=[Gold8]；delay={RewardKey:[K×1]}；对两者DeepCopy；修改原奖励数组不改变两份副本。

**玩家看到的结果：** 先领取8金币；宝箱标记暂留在延迟结算中，不被当成金币或直接一件棋子。
