# 首次计数只看棋盘：具体算法与配置

入口GetCodeCountMap(true,false,false)：BaseBoardModel复制棋盘m_codeCountMap；BaseActionBoardModel仅includeCache~=false才加入缓存；MainBoardModel仅includeStore~=false才加入仓库。这三个布尔值分别是棋盘、缓存、仓库。需求以GetCode精确匹配；气泡/网/临时包装代码不自动等于内含203。用于日常UpdateOrderState的计数路径与此次按钮传参应分别追踪，不能用UI状态替代入口真实计数。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:GetCodeCountMap（恢复文本行187）

- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.BaseBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)。对应：BaseBoardModel:GetCodeCountMap（恢复文本行507）

- Board.Model.Board.BaseActionBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.BaseActionBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.BaseActionBoardModel.disassembly.txt)。对应：BaseActionBoardModel:GetCodeCountMap（恢复文本行136）


---

## 贯穿案例：203×2与204×1，使用仓库补交

<div class="case-assets"><img src="../../../../../assets/cases/item-203.png" alt="棋子203" width="72" height="72"><img src="../../../../../assets/cases/item-204.png" alt="棋子204" width="72" height="72"></div>

读到203有2件、204不存在；仓库那件204此时不计。

### 代入本页的值

入口map={203:2}；合并仓库才是{203:2,204:1}；缓存即使有204也不进入后续扣除兜底。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
