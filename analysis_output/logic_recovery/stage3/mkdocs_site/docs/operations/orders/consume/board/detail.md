# 棋盘扣物：具体算法与配置

RemoveOrderRequirementItems以ipairs需求原序遍历，每项itemRemoved=false，GetValidPositionIterator从头扫描，item非nil且GetCode==requirement→RemoveItem(item,false)，removedItemsFromBoard[i]=对象并break。RemoveItem先清格，再ItemManager.RemoveItem/_RemoveItemProperty删除保存属性；false禁当次_SetItem自动刷新，外层随后Count/Update。BaseBoardModel._ValidPositionIterator从(1,1)开始，x每次加1；到HorizontalTiles后x重置1、y加1，超过VerticalTiles结束。主盘7×9依次(1,1)…(7,1)、(1,2)…(7,9)，因此本例先扣(1,1)再扣(2,1)。每件需求都重新从(1,1)开始，不沿用上次扫描游标。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:RemoveOrderRequirementItems（恢复文本行1164）

- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.BaseBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)。对应：BaseBoardModel:GetValidPositionIterator（恢复文本行54）；BaseBoardModel:RemoveItem（恢复文本行160）

- Board.Model.Board.BaseItemLayerModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.BaseItemLayerModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.BaseItemLayerModel.disassembly.txt)


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

<div class="case-assets"><img src="../../../../../assets/cases/item-203.png" alt="棋子203" width="72" height="72"></div>

### 场景1：按格序消耗两件食物

**完整输入（演示设定）：** 普通槽1订单需求按序203、203、204；棋盘(1,1)/(2,1)各裸203，仓库索引1裸204，缓存空；等级10，Gold100、Energy10、TotalDiff100。203价格2/难度2，204价格4/难度5。订单已标完成，奖励已发。

**按执行顺序代入：** 第1项扫描首命中(1,1)203→删；第2项重从(1,1)起首命中(2,1)203→删；第3项204棋盘无→交仓库；RemovedBoard键1=A、2=B。

**玩家看到的结果：** 棋盘两件203都消失，两个格空出；重复需求不会误用同一件棋子，Gold仍108。
