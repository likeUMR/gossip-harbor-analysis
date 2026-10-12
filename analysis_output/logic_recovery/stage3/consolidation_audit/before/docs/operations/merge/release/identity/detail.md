# 坐标与对象校验：具体算法与配置

主棋盘HorizontalTiles=7、VerticalTiles=9。PositionIsValid要求`1≤x≤7 and 1≤y≤9`；失败执行item:SetPosition(item:GetPosition())并return。

其次GetItem(item:GetPosition())必须与item对象相等，不能仅比较Type或ID字符串。不同对象即复位并return。SetPosition即使传原位置，也派ItemEventType.SetPosition，供视图播放回位；不是写一次新的格层记录。

DragItem模型入口本身没有再次调用CanItemMove(source)，依赖正常视图入口；直接测试调用模型不能假定它自动拒绝所有不可移动源。

## 源码依据

- Board.Model.Board.MainBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.MainBoardModel.disassembly.txt)
- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)
- Board.Model.Item.ItemModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Item.ItemModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Item.ItemModel.disassembly.txt)

---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：拒绝过期拖动对象

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。松手格(4,3)合法，但源格原201对象A已被另一201对象B替换。

**按执行顺序代入：** 1≤4≤7且1≤3≤9；GetItem(S)=B≠A，即使两者Type=201，仍SetPosition(A原坐标)→return。

**玩家看到的结果：** 旧拖动被撤回，棋盘上的新201和目标棋子都保留，不消耗物品。
