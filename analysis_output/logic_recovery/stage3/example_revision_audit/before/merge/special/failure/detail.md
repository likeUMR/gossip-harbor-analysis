# 失败提示后继续普通分派：具体算法与配置

CanItemAffect=false且source.SpecialType非nil时_ShowAffectFailTip。LevelUp提示hint_not_upgrade；LevelDown先IsBoardFull，满则hint_board_full，否则hint_not_split；其它SpecialType无这两类提示。

之后仍CanItemMerge→Swallow→目标移动检查→交换。_AffectItem仅LevelUp/LevelDown处理，未知特殊类型即使CanItemAffect=true也可能return false而继续。不能把SpecialType非nil等同于“禁止普通合成”。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)

---

## 贯穿案例：两个201合成202



201没有特殊类型，不显示失败提示。对照：升级物拖到不允许升级的目标，提示后仍可能交换位置。

### 代入本页的值

source.SpecialType=LevelUp，target映射不含LevelUp：CanItemAffect=false，提示hint_not_upgrade；不return，继续CanItemMerge。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
