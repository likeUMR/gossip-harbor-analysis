# 固定与回归订单：具体算法与配置

Fixed：CurrentFixedOrderId默认0，next=id+1；nextConfig存在、Slots包含当前槽、level≥UnlockLevel才meta设nextId，再按Requirement1..3构造。ReturnFree仅槽1/2/3，ReturnUser.IsOpen且IsInReturnRewardTime；timer==0先写serverTime返false，timer=nil或now−timer≥28800写0返true，其他false。Create从GetItemsOnBoard(true).levelList倒序，首个level≤7的itemList内Random(1,#list)等权选一件code，无code返nil；若该槽随机timer==0还将其改now，再单需求ReturnUserFree创建。每次重建候选，未从全局无放回池扣物；这里只创建需求，不删除现有棋子。

## 对应本地配表

各后缀为可选变体，不是同时叠加。require受FileReplace精确文件名首匹配替换，失败才回退默认；实际账号选择及远端档位未取得。缺字段记“—”，不能当0。下方保留全记录与全部字段；嵌套Filters/Rewards可横向滚动查看。

**OrderFixedConfig字段含义：** Id是进度顺序，Slots是允许槽位集合，UnlockLevel含端点门槛，Requirement1..3保留重复与顺序；缺需求不凭空补0。

<details><summary>OrderFixedConfig：16条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Id</th><th>Requirement1</th><th>Requirement2</th><th>Requirement3</th><th>Slots</th><th>UnlockLevel</th></tr></thead><tbody>
<tr><td>1</td><td>203</td><td>—</td><td>—</td><td>[1]</td><td>1</td></tr>
<tr><td>2</td><td>208</td><td>—</td><td>—</td><td>[1]</td><td>1</td></tr>
<tr><td>3</td><td>204</td><td>—</td><td>—</td><td>[1]</td><td>1</td></tr>
<tr><td>4</td><td>206</td><td>—</td><td>—</td><td>[1]</td><td>1</td></tr>
<tr><td>5</td><td>304</td><td>—</td><td>—</td><td>[1, 2]</td><td>2</td></tr>
<tr><td>6</td><td>303</td><td>—</td><td>—</td><td>[1, 2]</td><td>2</td></tr>
<tr><td>7</td><td>303</td><td>206</td><td>—</td><td>[1, 2]</td><td>2</td></tr>
<tr><td>8</td><td>305</td><td>—</td><td>—</td><td>[1, 2]</td><td>2</td></tr>
<tr><td>9</td><td>208</td><td>—</td><td>—</td><td>[1, 2]</td><td>2</td></tr>
<tr><td>10</td><td>205</td><td>303</td><td>—</td><td>[1, 2]</td><td>2</td></tr>
<tr><td>11</td><td>504</td><td>504</td><td>—</td><td>[1, 2]</td><td>3</td></tr>
<tr><td>12</td><td>205</td><td>505</td><td>—</td><td>[1, 2]</td><td>3</td></tr>
<tr><td>13</td><td>505</td><td>503</td><td>—</td><td>[1, 2]</td><td>3</td></tr>
<tr><td>14</td><td>603</td><td>—</td><td>—</td><td>[1, 2]</td><td>4</td></tr>
<tr><td>15</td><td>507</td><td>204</td><td>303</td><td>[3]</td><td>4</td></tr>
<tr><td>16</td><td>206</td><td>604</td><td>—</td><td>[1, 2]</td><td>4</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderFixedConfig.json">完整原记录</a></p></details>

## 源码依据

- Board.Model.Order.MainOrderCreator：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderCreator.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderCreator.disassembly.txt)。对应：MainOrderCreatorFixed.Create（恢复文本行8）；MainOrderCreatorReturnFreeOrder.CanCreate（恢复文本行90）；MainOrderCreatorReturnFreeOrder.Create（恢复文本行114）

- Board.Model.Order.MainOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.disassembly.txt)

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)。对应：MainBoardModel:GetItemsOnBoard（恢复文本行1699）


---

## 演示案例

下面分别改变前提，让各条分支实际发生；互斥结果属于不同场景。

### 场景1：预设需求创建固定单

**完整输入（演示设定）：** 假设固定进度0、玩家10、空槽1；下一记录Id1、Slots[1]、UnlockLevel1、Requirement1=203，后两项nil。

**按执行顺序代入：** next=0+1=1；slot1∈[1]、10≥1→写CurrentFixedOrderId1；需求数组[203]，创建Fixed。

**玩家看到的结果：** 新顾客只要一件203，固定进度推进到1；没有随机挑需求。

### 场景2：回归八小时后免费单

**完整输入（演示设定）：** 固定未创建；槽1空，回归开放且在奖励期，旧timer1000、now29800；棋盘最高不超过7级的物品为同级207/507各1，另有8级208，记录候选序207/507。

**按执行顺序代入：** 29800−1000=28800≥28800→timer写0允许；跳过8级，取7级list[207,507]；R=2→507；假设随机槽timer0，则置29800；创建单需求[507]。

**玩家看到的结果：** 出现只要一件507的回归免费订单；507仍在棋盘，本步只是创建需求，尚未扣物。
