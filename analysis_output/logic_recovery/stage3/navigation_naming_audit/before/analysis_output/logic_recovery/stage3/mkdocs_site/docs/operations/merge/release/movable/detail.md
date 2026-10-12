# 开始拖动与移动资格：具体算法与配置

`CanItemMove`按顺序检查ItemPaperBox/ItemCobweb、ItemLocked，再读取ItemSwallow。前三类存在时返回false；没有吞噬组件返回true；有则返回AllowTap。AllowTap来自`Swallow_AllowTap ~= 0`，缺省nil也会得到true，不能擅自当false。

`_OnDrag`要求m_lastTouchedItem及其模型非nil。首次`not m_dragging and canItemMove`时派发StartDraggingItem，刷新指示器、完成格与作用效果；随后设m_dragging=true，即使不可移动也设置此标记，但立即返回不移动图像。可移动时用ScreenToWorldPoint投影，图像z设0；Inventory悬停进/出播放按钮效果；最后尝试合成高亮。移动许可不等于合成许可：蜘蛛网不能拖动，但可以作为合成目标。

## 源码依据

- Board.View.MainBoardView：[恢复源码](../../../../assets/merge-evidence/Board.View.MainBoardView.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.View.MainBoardView.disassembly.txt)
- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)
- Board.Model.Item.ItemSwallow：[恢复源码](../../../../assets/merge-evidence/Board.Model.Item.ItemSwallow.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Item.ItemSwallow.disassembly.txt)

---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：可以拖动的普通食物

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。棋盘源格(3,3)放普通201，无纸箱、网、锁或吞噬组件，首次按住后拖动。

**按执行顺序代入：** PaperBox=nil→Cobweb=nil→Locked=nil→Swallow=nil，CanItemMove=true；首次拖动派StartDraggingItem，m_dragging=false→true。格层仍是S→原对象。

**玩家看到的结果：** 201跟随手指，源格的实际棋子尚未移动；没有扣能量。
