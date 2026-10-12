# 不可移动目标：复位结束：具体算法与配置

目标CanItemMove使用与源同一规则：PaperBox/Cobweb/Locked拒绝；Swallow存在则AllowTap。失败SetPosition(source原位置)并return，不改格、不发ItemMoveEnd、不调用_UpdateAccelerate。该检查在CanItemMerge/CanSwallow之后，所以不能移动的目标仍可能在前面作为合成或吞噬目标成功。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)

---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：锁定目标拒绝交换

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。源201可移动，目标为锁定204；特殊作用、普通合成、吞噬都未接受。

**按执行顺序代入：** CanItemMove(target)=false→source.SetPosition(S)→return；格层写次数0，交换加速刷新0。

**玩家看到的结果：** 201回原格，锁定204保持原位，没有扣能量或合成。
