# 仓库落点的优先分流：具体算法与配置

视图要求raycast对象名恰为Inventory。功能开启才StoreItem；关闭时显示锁定提示。stored默认false，成功才设true并播放入库效果；没有成功则DragItem(item,target,false)。当前DragItem定义只有两个形参，额外false不会被使用，不能推断其关闭订单刷新。

CanItemStore先CanItemMove，再拒绝Bubble/Temp/PropertyBubble、带Duration的Transform、Opening状态Spread及当前工厂专用物（返回GeneratorFactory原因）。StoreItem先资格再容量：失败派StoreFailed，Reason用具体原因或CannotStore；满仓为InventoryFull。

成功先_SetItem(原格,nil,false)，再m_itemStoreModel:AddItem；CountItemsCode、UpdateOrderState；写StoreItem日志；局部StoreItem；全局InventoryStoryItem。仓库仍纳入订单计数，但不能把移入误写成消耗物品。

## 源码依据

- Board.View.MainBoardView：[恢复源码](../../../../assets/merge-evidence/Board.View.MainBoardView.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.View.MainBoardView.disassembly.txt)
- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)

---

## 贯穿案例：两个201合成202



本例落在棋盘目标201，没有尝试存入。对照：把松手位置改为仓库，201可存且仓库有空位时进入仓库，取消这次合成。

### 代入本页的值

本例raycast.name≠Inventory。对照stored=true时不会调用DragItem；stored=false时保留已计算棋盘坐标，包括教程可能改写的(0,0)。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
