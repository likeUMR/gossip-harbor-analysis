# 即时与延迟奖励分离、冻结快照：具体算法与配置

GetOrderRewardByFinishOrder遍历GetRewards，StringUtil.StartWith(type,ChestCustomerModel.RewardKey)为false进targetRewards，为true进otherMapReward[RewardKey]数组；按各组保留原顺序。MainBoardModel随后对rewards与mapDelayRewards分别DeepCopy。完成消息携这两份快照；gift/buff/cooking不是自动写进这份即时快照，而在各自调用位置处理。延迟映射后续以pairs逐组遍历，不能给不同组虚构固定顺序。

## 源码依据

- Board.Model.Order.MainOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrder.disassembly.txt)。对应：MainOrder:GetOrderRewardByFinishOrder（恢复文本行257）

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:FinishOrder（恢复文本行1101）


---

## 贯穿案例：203×2与204×1，使用仓库补交

8金币属于即时数组，延迟映射为空。

### 代入本页的值

rewards=[Gold8]，mapDelayRewards={}；对照chest前缀标记从即时中移出，挂到RewardKey组。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
