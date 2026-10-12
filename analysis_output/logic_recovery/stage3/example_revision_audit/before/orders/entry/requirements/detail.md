# 重复需求按件数检查：具体算法与配置

BaseOrder.Init跳过空字符串并保留需求顺序。CanDeliver对第i项从i−1向1数同code项，count从1开始；map不存在或count>map[code]就把canDeliver置false，缺口写count−(map[code] or 0)。同code后面的失败项覆盖前值，最终得到总缺口；不中途return。空数组返回true,{}。UpdateState使用同一逐项计数更新fillStates；0需求Dormant=0，0项满足Init=1，部分PartiallyFinished=2，全部CanDeliver=3，Finished=4则不再更新。_SetState仅状态变化才写升降方向与服务器时间；SetFinished直接写Finished。

## 源码依据

- Board.Model.Order.BaseOrder：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.BaseOrder.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.BaseOrder.disassembly.txt)。对应：BaseOrder:Init（恢复文本行23）；BaseOrder:_SetState（恢复文本行69）；BaseOrder:UpdateState（恢复文本行82）；BaseOrder:CanDeliver（恢复文本行112）


---

## 贯穿案例：203×2与204×1，使用仓库补交

两个203逐项通过，204缺1件；不是把重复203去重后判断。

### 代入本页的值

需求[203,203,204]，各count=1,2,1；map[203]=2均通过，204为nil失败；lacked={204:1}。对照203只有1件，缺口还包含203:1。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
