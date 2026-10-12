# 不可移动目标：复位结束：具体算法与配置

目标CanItemMove使用与源同一规则：PaperBox/Cobweb/Locked拒绝；Swallow存在则AllowTap。失败SetPosition(source原位置)并return，不改格、不发ItemMoveEnd、不调用_UpdateAccelerate。该检查在CanItemMerge/CanSwallow之后，所以不能移动的目标仍可能在前面作为合成或吞噬目标成功。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)

---

## 贯穿案例：两个201合成202



主例在合成已返回。对照201拖到内含不同类型的蜘蛛网，既不匹配合成又不可交换，所以201复位。

### 代入本页的值

CanItemMerge=false、CanSwallow=false、target.Cobweb存在→CanItemMove=false；仅source.SetPosition(S)。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
