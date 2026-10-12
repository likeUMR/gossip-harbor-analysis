# 升级确认与目标替换：具体算法与配置

SpecialType=LevelUp打开UseSpecialItemConfirmWindow，参数源Type、目标Type、目标MergedType、nil、场景rainbow_item_use_confirm。外层立即SetPosition(原位置)并return true，截断普通分派。

确认回调CanItemAffect仍true时RemoveItem(source)，ReplaceItem(target,target.MergedType)，局部MergeItem→全局ItemMerged→ShockNeighborItems(T)→ItemShocked→BI LogMerge(ext.levelup=1)，最后window.Close。message仅Source/Target/New，不带普通合成的itemType/isFirstUnlock。不是调用MainBoardModel:_DoMergeItem，故没有它追加的ScoreRace直接计分、临时/卡片/气泡/金币检查；全局监听仍可运行。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Board.Model.Item.ItemModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Item.ItemModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Item.ItemModel.disassembly.txt)

---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：升级202到203

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。level_up_piece_1在S，202在T且LevelUpPiece=1、MergedType=203；确认时资格仍有效。

**按执行顺序代入：** RemoveItem(source)→ReplaceItem(T,203)→MergeItem/ItemMerged→四邻震动；日志ext.levelup=1；不调用普通_DoMergeItem。

**玩家看到的结果：** 升级道具消失，202变成203；不执行普通合成直接计分和副产物抽取，能量不变。
