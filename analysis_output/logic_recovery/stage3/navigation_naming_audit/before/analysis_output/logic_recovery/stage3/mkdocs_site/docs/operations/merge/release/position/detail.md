# 屏幕落点、吸附与教程限制：具体算法与配置

`_OnPointerUp`先清合成灯光，用相机ScreenToWorldPoint和_GetBoardPosition得到落点。最近可合成物存在且`timeSinceLevelLoad-lastTime < 0.15`时，分别检查x差平方≤1、y差平方≤1，成立则用该物位置。这是每轴相差最多1格，包含斜对角，不是曼哈顿距离≤1，也不是0.15秒防抖。

强制教程目标非nil且与落点不同，改为BoardPosition.Create(0,0)。然后计算boardPositionChanged，清最近高亮缓存，结束仓库悬停效果。视图的吸附时间使用Unity运行时间，模型资格使用棋盘状态，两种来源不能混用。

异常指针退出会ResetPressedState；源仍可移动时DragItem到(0,0)，通过模型非法位置路径复位，再清指针、指示器和信息栏。

## 源码依据

- Board.View.MainBoardView：[恢复源码](../../../../assets/merge-evidence/Board.View.MainBoardView.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.View.MainBoardView.disassembly.txt)
- Board.Model.Base.BoardPosition：[恢复源码](../../../../assets/merge-evidence/Board.Model.Base.BoardPosition.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Base.BoardPosition.disassembly.txt)

---

## 演示案例

下面分别改变前提，让各条分支实际发生；互斥结果属于不同场景。

### 场景1：短时间高亮吸附

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。源在(3,3)，高亮目标在(4,4)，松手换算为(3,3)，距高亮0.10秒，无强制教程目标。

**按执行顺序代入：** 0.10<0.15；(3−4)²=1≤1，两轴均通过；传给模型的位置由(3,3)改为(4,4)。

**玩家看到的结果：** 本来松手在原格的201被送到右上方高亮棋子所在格，后续按该格判断合成。

### 场景2：教程指定落点

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。教程指定(4,3)，松手为(5,3)，没有近期高亮。

**按执行顺序代入：** (5,3)≠(4,3)→位置改(0,0)；PositionIsValid=false→SetPosition(原位置)并返回。

**玩家看到的结果：** 201回到原格，目标不改变，没有合成或扣能量。
