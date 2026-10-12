# 移动后的加速刷新与通知：具体算法与配置

_UpdateAccelerate对源/目标依次检查：Spread存在且CanAccelerate；或Transform存在且CanAccelerate；或Accelerate存在且IsActivated。任一对象满足就连续调用UpdatePerSecond两次，不是按移动距离增加秒数。Transform.CanAccelerate要求duration与startTimer都非nil。

之后全局ItemMoveEnd消息为`{item=item}`，再return。原格复位也会走这段；交换分支调用同一加速更新却没有此处的ItemMoveEnd。通知的监听可产生后续行为，不能据模型函数return断言全局监听无副作用。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Board.Model.Item.ItemTransform：[恢复源码](../../../../assets/merge-evidence/Board.Model.Item.ItemTransform.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Item.ItemTransform.disassembly.txt)

---

## 贯穿案例：两个201合成202



本例合成目标非空，移动收尾不执行。空格对照的201无计时/加速组件，只发移动结束。

### 代入本页的值

对照201：checkFunc(source)=false、target=nil，所以UpdatePerSecond次数0，ItemMoveEnd一次。换成正在计时的母体，则调用两次UpdatePerSecond，类型与计时结果由组件更新决定。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
