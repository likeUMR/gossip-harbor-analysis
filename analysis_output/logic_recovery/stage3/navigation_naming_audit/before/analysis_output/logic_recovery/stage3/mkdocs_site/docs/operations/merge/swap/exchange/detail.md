# 交换写格、订单刷新与计时：具体算法与配置

记itemPosition=S。顺序_SetItem(S,nil,false)→_SetItem(T,source,false)→_SetItem(S,target)；第三次未传false，会CountItemsCode/UpdateOrderState。旧说明“两次对象写回都禁订单刷新”错误，当前实现只前两次禁用。

随后_LogMove(source,source.GetPosition(),T)，_LogMove(target,T,S)，再source.SetPosition(T)、target.SetPosition(S)，最后_UpdateAccelerate(source,target)。因此订单刷新通知发生在两对象SetPosition之前，但格层已经交换；同步消费者读取格层与对象位置时须按该时点理解。

交换没有空位移动分支的ItemMoveEnd，也没有普通合成/吞噬事件。存在计时或激活加速组件时UpdatePerSecond调用两次；不是两件新物，不SaveItemProperty重建状态。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Board.Model.Board.MainBoardItemLayerModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardItemLayerModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardItemLayerModel.disassembly.txt)

---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：不同类型棋子互换

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。S普通201、T普通204，双方可移动，无特殊或吞噬关系，普通合成不成立，能量10。

**按执行顺序代入：** 清S(false)→T写source(false)→S写target(默认刷新)；分别SetPosition(T/S)并记移动日志2次；双方无加速组件→计时刷新0。

**玩家看到的结果：** 201和204互换位置，物品总数不变、能量仍10；不生成新物，也不发空格移动专用的结束通知。
