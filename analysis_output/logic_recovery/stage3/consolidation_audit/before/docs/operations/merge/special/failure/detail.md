# 道具作用失败：具体算法与配置

CanItemAffect=false且source.SpecialType非nil时_ShowAffectFailTip。LevelUp提示hint_not_upgrade；LevelDown先IsBoardFull，满则hint_board_full，否则hint_not_split；其它SpecialType无这两类提示。

之后仍CanItemMerge→Swallow→目标移动检查→交换。_AffectItem仅LevelUp/LevelDown处理，未知特殊类型即使CanItemAffect=true也可能return false而继续。不能把SpecialType非nil等同于“禁止普通合成”。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)

---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：升级被拒后交换

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。升级道具在S，目标为可移动、不可升级的普通物，类型不同且无吞噬组件；目标LevelUpPiece缺省。

**按执行顺序代入：** CanItemAffect=false→hint_not_upgrade；CanItemMerge=false；Swallow=nil；CanItemMove(target)=true→交换两格。

**玩家看到的结果：** 没有消耗升级道具，两件物品互换位置；玩家先看到不可升级提示。
