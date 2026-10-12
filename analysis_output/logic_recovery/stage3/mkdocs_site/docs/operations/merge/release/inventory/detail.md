# 棋子入库：具体算法与配置

视图要求raycast对象名恰为Inventory。功能开启才StoreItem；关闭时显示锁定提示。stored默认false，成功才设true并播放入库效果；没有成功则DragItem(item,target,false)。当前DragItem定义只有两个形参，额外false不会被使用，不能推断其关闭订单刷新。

CanItemStore先CanItemMove，再拒绝Bubble/Temp/PropertyBubble、带Duration的Transform、Opening状态Spread及当前工厂专用物（返回GeneratorFactory原因）。StoreItem先资格再容量：失败派StoreFailed，Reason用具体原因或CannotStore；满仓为InventoryFull。

成功先_SetItem(原格,nil,false)，再m_itemStoreModel:AddItem；CountItemsCode、UpdateOrderState；写StoreItem日志；局部StoreItem；全局InventoryStoryItem。仓库仍纳入订单计数，但不能把移入误写成消耗物品。

## 源码依据

- Board.View.MainBoardView：[恢复源码](../../../../assets/merge-evidence/Board.View.MainBoardView.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.View.MainBoardView.disassembly.txt)
- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)

---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：成功存入仓库

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。仓库功能已开启，普通201可移动，无气泡、临时物、计时变换、开启中母体或工厂限制；仓库占2格、容量3，松手命中Inventory。

**按执行顺序代入：** 资格=true，2<3；_SetItem(S,nil,false)→AddItem→Count/Update；stored=true，DragItem不执行。

**玩家看到的结果：** 棋盘少一件201，仓库从2件变3件；仍持有这件物品，本次不合成。
