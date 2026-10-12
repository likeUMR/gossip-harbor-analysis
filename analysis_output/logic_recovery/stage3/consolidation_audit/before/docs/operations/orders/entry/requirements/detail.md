# 需求数量核对：具体算法与配置

BaseOrder.Init跳过空字符串并保留需求顺序。CanDeliver对第i项从i−1向1数同code项，count从1开始；map不存在或count>map[code]就把canDeliver置false，缺口写count−(map[code] or 0)。同code后面的失败项覆盖前值，最终得到总缺口；不中途return。空数组返回true,{}。UpdateState使用同一逐项计数更新fillStates；0需求Dormant=0，0项满足Init=1，部分PartiallyFinished=2，全部CanDeliver=3，Finished=4则不再更新。_SetState仅状态变化才写升降方向与服务器时间；SetFinished直接写Finished。

## 源码依据

- Board.Model.Order.BaseOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.BaseOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.BaseOrder.disassembly.txt)。对应：BaseOrder:Init（恢复文本行23）；BaseOrder:_SetState（恢复文本行69）；BaseOrder:UpdateState（恢复文本行82）；BaseOrder:CanDeliver（恢复文本行112）


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：重复需求缺口

**完整输入（演示设定）：** 普通槽1订单需求按序203、203、204；棋盘(1,1)/(2,1)各裸203，仓库索引1裸204，缓存空；等级10，Gold100、Energy10、TotalDiff100。203价格2/难度2，204价格4/难度5。改为棋盘只有203×1，仓库再有203×1。

**按执行顺序代入：** i1需203×1、持有1通过；i2累计需2、持有1→缺203=1；i3需204×1、持有0→缺204=1；返回false及{203:1,204:1}。

**玩家看到的结果：** 窗口要求从仓库补一件203和一件204，不能用一件203满足两个需求；此时未扣物。
