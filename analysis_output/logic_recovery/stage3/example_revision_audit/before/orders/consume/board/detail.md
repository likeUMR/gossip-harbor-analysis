# 按棋盘遍历序扣第一件匹配物：具体算法与配置

RemoveOrderRequirementItems以ipairs需求原序遍历，每项itemRemoved=false，GetValidPositionIterator从头扫描，item非nil且GetCode==requirement→RemoveItem(item,false)，removedItemsFromBoard[i]=对象并break。RemoveItem先清格，再ItemManager.RemoveItem/_RemoveItemProperty删除保存属性；false禁当次_SetItem自动刷新，外层随后Count/Update。BaseBoardModel._ValidPositionIterator从(1,1)开始，x每次加1；到HorizontalTiles后x重置1、y加1，超过VerticalTiles结束。主盘7×9依次(1,1)…(7,1)、(1,2)…(7,9)，因此本例先扣(1,1)再扣(2,1)。每件需求都重新从(1,1)开始，不沿用上次扫描游标。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:RemoveOrderRequirementItems（恢复文本行1164）

- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.BaseBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)。对应：BaseBoardModel:GetValidPositionIterator（恢复文本行54）；BaseBoardModel:RemoveItem（恢复文本行160）

- Board.Model.Board.BaseItemLayerModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.BaseItemLayerModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.BaseItemLayerModel.disassembly.txt)


---

## 贯穿案例：203×2与204×1，使用仓库补交

<div class="case-assets"><img src="../../../../../assets/cases/item-203.png" alt="棋子203" width="72" height="72"></div>

第一项203删除第一匹配对象，第二项扫描剩余棋盘删除另一203。

### 代入本页的值

RemovedFromBoard[1]=203对象A，[2]=203对象B，[3]=nil；对象身份不同，需求顺序未去重。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
