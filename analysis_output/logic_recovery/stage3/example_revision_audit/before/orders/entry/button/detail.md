# 按钮门控与入口差异：具体算法与配置

BaseOrderCell.OnGoButtonClicked只在m_bGoButtonEnabled恰为false时return；nil不等同false。随后播放sfxOrderServe，取得所在BoardView模型，检查CanDeliver。SpecialOrderCell覆盖入口，门控和音效相同，却直接打开SpecialOrderItemWindow，不做普通入口的数量判断。订单状态控制按钮显示属于点击之前的资格来源，不是模型内部第二次校验。

## 源码依据

- Board.View.Order.BaseOrderCell：[恢复源码](../../../../assets/order-evidence/Board.View.Order.BaseOrderCell.lua) · [原始指令](../../../../assets/order-evidence/Board.View.Order.BaseOrderCell.disassembly.txt)。对应：BaseOrderCell:OnGoButtonClicked（恢复文本行22）

- Board.View.Order.MainOrderCell：[恢复源码](../../../../assets/order-evidence/Board.View.Order.MainOrderCell.lua) · [原始指令](../../../../assets/order-evidence/Board.View.Order.MainOrderCell.disassembly.txt)。对应：SpecialOrderCell:OnGoButtonClicked（恢复文本行536）


---

## 贯穿案例：203×2与204×1，使用仓库补交

本例按钮开启，播放服务音效，进入普通需求检查。

### 代入本页的值

m_bGoButtonEnabled=true；对照false：无音效、无计数、无窗口、无FinishOrder。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
