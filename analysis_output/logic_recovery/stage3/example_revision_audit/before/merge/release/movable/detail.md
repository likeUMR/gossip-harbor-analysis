# 开始拖动与移动资格：具体算法与配置

`CanItemMove`按顺序检查ItemPaperBox/ItemCobweb、ItemLocked，再读取ItemSwallow。前三类存在时返回false；没有吞噬组件返回true；有则返回AllowTap。AllowTap来自`Swallow_AllowTap ~= 0`，缺省nil也会得到true，不能擅自当false。

`_OnDrag`要求m_lastTouchedItem及其模型非nil。首次`not m_dragging and canItemMove`时派发StartDraggingItem，刷新指示器、完成格与作用效果；随后设m_dragging=true，即使不可移动也设置此标记，但立即返回不移动图像。可移动时用ScreenToWorldPoint投影，图像z设0；Inventory悬停进/出播放按钮效果；最后尝试合成高亮。移动许可不等于合成许可：蜘蛛网不能拖动，但可以作为合成目标。

## 源码依据

- Board.View.MainBoardView：[恢复源码](../../../../assets/merge-evidence/Board.View.MainBoardView.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.View.MainBoardView.disassembly.txt)
- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)
- Board.Model.Item.ItemSwallow：[恢复源码](../../../../assets/merge-evidence/Board.Model.Item.ItemSwallow.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Item.ItemSwallow.disassembly.txt)

---

## 贯穿案例：两个201合成202

<img src="../../../../../assets/cases/item-201.png" alt="棋子201" style="width:72px;height:72px;object-fit:contain;margin-right:12px;">

201是普通食物，可以被拖动；源格内容此时没有改变。

### 代入本页的值

201没有PaperBox/Cobweb/Locked/Swallow组件，CanItemMove=true。首次拖动发StartDraggingItem；m_dragging变true，格层仍保存源物ID。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
