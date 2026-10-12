# 仓库扣物：具体算法与配置

if not itemRemoved：j=1..store.GetItemCount，GetItem(j)非nil且GetCode==requirement→store.RemoveItem(j)→_RemoveItemProperty(item)→itemRemoved=true→RemovedFromInventory[i]=requirement→break。移除造成索引移动，下一需求重新读取数量并从1扫描；结果数组按原需求索引可能有空洞，消费者用pairs。仓库数组保存code而不是对象；棋盘数组保存对象，便于各自动画。不会RetrieveStoredItem先落棋盘，不查Cache。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:RemoveOrderRequirementItems（恢复文本行1164）

- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.BaseBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)


---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

<div class="case-assets"><img src="../../../../../assets/cases/item-204.png" alt="棋子204" width="72" height="72"></div>

### 场景1：缺物才动仓库

**完整输入（演示设定）：** 普通槽1订单需求按序203、203、204；棋盘(1,1)/(2,1)各裸203，仓库索引1裸204，缓存空；等级10，Gold100、Energy10、TotalDiff100。203价格2/难度2，204价格4/难度5。前两项203已在棋盘扣到，第三项204棋盘无。

**按执行顺序代入：** 第三项扫描store j1=204→RemoveItem(1)及属性删除；RemovedInventory[3]=204；storeCount1→0；缓存不扫描。

**玩家看到的结果：** 仓库的204被消耗，前两项不会再额外扣仓库203；三件需求合计只扣三件。
