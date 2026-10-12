# 屏幕落点、吸附与教程限制：具体算法与配置

`_OnPointerUp`先清合成灯光，用相机ScreenToWorldPoint和_GetBoardPosition得到落点。最近可合成物存在且`timeSinceLevelLoad-lastTime < 0.15`时，分别检查x差平方≤1、y差平方≤1，成立则用该物位置。这是每轴相差最多1格，包含斜对角，不是曼哈顿距离≤1，也不是0.15秒防抖。

强制教程目标非nil且与落点不同，改为BoardPosition.Create(0,0)。然后计算boardPositionChanged，清最近高亮缓存，结束仓库悬停效果。视图的吸附时间使用Unity运行时间，模型资格使用棋盘状态，两种来源不能混用。

异常指针退出会ResetPressedState；源仍可移动时DragItem到(0,0)，通过模型非法位置路径复位，再清指针、指示器和信息栏。

## 源码依据

- Board.View.MainBoardView：[恢复源码](../../../../assets/merge-evidence/Board.View.MainBoardView.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.View.MainBoardView.disassembly.txt)
- Board.Model.Base.BoardPosition：[恢复源码](../../../../assets/merge-evidence/Board.Model.Base.BoardPosition.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Base.BoardPosition.disassembly.txt)

---

## 贯穿案例：两个201合成202



松手对准目标201；没有最近高亮吸附或强制教程改写，目标格保持不变。

### 代入本页的值

演示源S=(3,3)、目标T=(4,3)，无强制目标。对照：高亮在(4,4)，经过0.10秒且松手(3,3)，每轴差都为1，会吸附(4,4)；恰好0.15秒不吸附。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
