# 升级确认与目标替换：具体算法与配置

SpecialType=LevelUp打开UseSpecialItemConfirmWindow，参数源Type、目标Type、目标MergedType、nil、场景rainbow_item_use_confirm。外层立即SetPosition(原位置)并return true，截断普通分派。

确认回调CanItemAffect仍true时RemoveItem(source)，ReplaceItem(target,target.MergedType)，局部MergeItem→全局ItemMerged→ShockNeighborItems(T)→ItemShocked→BI LogMerge(ext.levelup=1)，最后window.Close。message仅Source/Target/New，不带普通合成的itemType/isFirstUnlock。不是调用MainBoardModel:_DoMergeItem，故没有它追加的ScoreRace直接计分、临时/卡片/气泡/金币检查；全局监听仍可运行。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Board.Model.Item.ItemModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Item.ItemModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Item.ItemModel.disassembly.txt)

---

## 贯穿案例：两个201合成202

<img src="../../../../../assets/cases/item-level_up_piece_1.png" alt="棋子level_up_piece_1" style="width:72px;height:72px;object-fit:contain;margin-right:12px;"><img src="../../../../../assets/cases/item-202.png" alt="棋子202" style="width:72px;height:72px;object-fit:contain;margin-right:12px;">

主例无升级道具。升级对照：把level_up_piece_1拖到202并确认，目标变203，道具消失；这次不走普通合成副产物。

### 代入本页的值

本地202.MergedType=203、LevelUpPiece=1。确认前棋盘不变；确认后源移除、T生成203，ext.levelup=1；若资格变false只关闭窗口。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
