# 选中与释放：具体算法与配置

非仓库棋盘分派后：GetItem(source.GetPosition())==source时m_selectedBoardPosition=source.GetPosition，否则用targetBoardPosition。仓库存入成功不走这段选择分支；局部StoreItem视图回调移除源视图并刷新栏。

selectedItemDisappeared=(selectedItem~=source and GetItem(source.Position)~=source)。为true用MergeItem收集提示；否则not boardPositionChanged用SelectItem；否则None。_UpdateIndicator、infoBar.UpdateInfoBar→全局BoardPointerUp{dragging=m_dragging}→_ClearPointerData→_UpdateItemAffectedEffect。startedPromptStep2为true则清标记，否则_StartPrompt；最后_UpdateCompleteTiles(true)。

普通合成的局部MergeItem视图回调还会先更新指示器/信息栏，调用BaseActionBoardView._OnMergeItem处理动画，再_TryToRemoveSandFills(Target)。它与最后PointerUp收尾是不同触发位置。动画不负责替代模型创建、保存与订单更新。

## 源码依据

- Board.View.MainBoardView：[恢复源码](../../../../assets/merge-evidence/Board.View.MainBoardView.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.View.MainBoardView.disassembly.txt)
- Board.View.BaseActionBoardView：[恢复源码](../../../../assets/merge-evidence/Board.View.BaseActionBoardView.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.View.BaseActionBoardView.disassembly.txt)

---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：合成后的选中收尾

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。201×2已生成T处202；原源对象被删除，m_dragging仍true。

**按执行顺序代入：** 源对象已不在格层→取T处新202并选中；BoardPointerUp消息携dragging=true；随后m_dragging=false并清指针缓存。

**玩家看到的结果：** 202成为当前选中棋子，拖动结束，信息栏显示结果物而非已删除的201。
