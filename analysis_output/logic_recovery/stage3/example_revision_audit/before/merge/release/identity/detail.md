# 坐标与源身份的最后核对：具体算法与配置

主棋盘HorizontalTiles=7、VerticalTiles=9。PositionIsValid要求`1≤x≤7 and 1≤y≤9`；失败执行item:SetPosition(item:GetPosition())并return。

其次GetItem(item:GetPosition())必须与item对象相等，不能仅比较Type或ID字符串。不同对象即复位并return。SetPosition即使传原位置，也派ItemEventType.SetPosition，供视图播放回位；不是写一次新的格层记录。

DragItem模型入口本身没有再次调用CanItemMove(source)，依赖正常视图入口；直接测试调用模型不能假定它自动拒绝所有不可移动源。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)
- Board.Model.Item.ItemModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Item.ItemModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Item.ItemModel.disassembly.txt)

---

## 贯穿案例：两个201合成202



目标格在棋盘内，源格仍是被拖动的201，因此进入目标格分派。

### 代入本页的值

S=(3,3)、T=(4,3)，两坐标合法；GetItem(S)==source。对照旧source被新201替换时，即使Type同为201也返回；(0,0)越界也返回。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
