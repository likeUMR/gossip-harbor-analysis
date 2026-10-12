# 加速刷新：具体算法与配置

_UpdateAccelerate对源/目标依次检查：Spread存在且CanAccelerate；或Transform存在且CanAccelerate；或Accelerate存在且IsActivated。任一对象满足就连续调用UpdatePerSecond两次，不是按移动距离增加秒数。Transform.CanAccelerate要求duration与startTimer都非nil。

之后全局ItemMoveEnd消息为`{item=item}`，再return。原格复位也会走这段；交换分支调用同一加速更新却没有此处的ItemMoveEnd。通知的监听可产生后续行为，不能据模型函数return断言全局监听无副作用。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Board.Model.Item.ItemTransform：[恢复源码](../../../../assets/merge-evidence/Board.Model.Item.ItemTransform.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Item.ItemTransform.disassembly.txt)

---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：移动正在计时的母体

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。源为可移动计时母体，Spread.CanAccelerate=true，T为空；假设两次计时刷新都尚未达到完成时间。

**按执行顺序代入：** source检查=true→UpdatePerSecond()两次；派ItemMoveEnd{item=source}一次→return；本例计时刷新未完成，类型不变。

**玩家看到的结果：** 母体到达新格，计时显示按新位置重新核对；本次不合成，也不额外生成物品。
