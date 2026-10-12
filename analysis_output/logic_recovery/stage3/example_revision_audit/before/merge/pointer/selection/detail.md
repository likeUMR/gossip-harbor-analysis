# 选择结果、提示与释放通知：具体算法与配置

非仓库棋盘分派后：GetItem(source.GetPosition())==source时m_selectedBoardPosition=source.GetPosition，否则用targetBoardPosition。仓库存入成功不走这段选择分支；局部StoreItem视图回调移除源视图并刷新栏。

selectedItemDisappeared=(selectedItem~=source and GetItem(source.Position)~=source)。为true用MergeItem收集提示；否则not boardPositionChanged用SelectItem；否则None。_UpdateIndicator、infoBar.UpdateInfoBar→全局BoardPointerUp{dragging=m_dragging}→_ClearPointerData→_UpdateItemAffectedEffect。startedPromptStep2为true则清标记，否则_StartPrompt；最后_UpdateCompleteTiles(true)。

普通合成的局部MergeItem视图回调还会先更新指示器/信息栏，调用BaseActionBoardView._OnMergeItem处理动画，再_TryToRemoveSandFills(Target)。它与最后PointerUp收尾是不同触发位置。动画不负责替代模型创建、保存与订单更新。

## 源码依据

- Board.View.MainBoardView：[恢复源码](../../../../assets/merge-evidence/Board.View.MainBoardView.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.View.MainBoardView.disassembly.txt)
- Board.View.BaseActionBoardView：[恢复源码](../../../../assets/merge-evidence/Board.View.BaseActionBoardView.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.View.BaseActionBoardView.disassembly.txt)

---

## 贯穿案例：两个201合成202



视图看到源201已不在S，选T上的202；信息栏改为202，释放事件标记本次确实拖动。

### 代入本页的值

source仍引用旧201但GetItem(S)≠source，selectedPosition=T。BoardPointerUp.dragging=true在_ClearPointerData之前发出；不是清理后false。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
