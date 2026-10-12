# 棋盘未找到才扣仓库：具体算法与配置

if not itemRemoved：j=1..store.GetItemCount，GetItem(j)非nil且GetCode==requirement→store.RemoveItem(j)→_RemoveItemProperty(item)→itemRemoved=true→RemovedFromInventory[i]=requirement→break。移除造成索引移动，下一需求重新读取数量并从1扫描；结果数组按原需求索引可能有空洞，消费者用pairs。仓库数组保存code而不是对象；棋盘数组保存对象，便于各自动画。不会RetrieveStoredItem先落棋盘，不查Cache。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:RemoveOrderRequirementItems（恢复文本行1164）

- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.BaseBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)


---

## 贯穿案例：203×2与204×1，使用仓库补交

<div class="case-assets"><img src="../../../../../assets/cases/item-204.png" alt="棋子204" width="72" height="72"></div>

第三项204棋盘没有，删除仓库索引1那件；前两项没有动仓库。

### 代入本页的值

RemovedFromInventory[3]="204"，索引1/2为空；storeCount1→0。缓存204不会代替仓库204被扣。

<details><summary>案例共同前提</summary>

本地默认表的演示场景：普通Random1订单、槽1，需求按顺序为203、203、204；棋盘(1,1)、(2,1)各一件裸代码203，仓库索引1是一件204，缓存不计。等级10，Gold余额100，能量10；非基准订单，金币Buff关闭，BakeOut、亲密度及其它奖励活动不生效；TotalDiffScore初值100。本地203的Price=2、DiffScore=2，204的Price=4、DiffScore=5。窗口确认时订单仍属于槽位模型，期间物品未变化。该订单实例是讲解输入，不冒充实际账号存档。

分支对照明确改变输入；未进入的活动不虚构执行。演示随机值和活动档位不代替远端真实配置。

</details>
