# 分支顺序与移动交换算法

`DragItem` 先用 `PositionIsValid` 检查目标格，再从源坐标重新读取棋子并确认仍是拖动对象；这是防止视图过期或重复拖动覆盖棋盘的身份门禁。随后按以下顺序短路：目标为空则移动；有目标时先尝试 `CanItemAffect`（升级/降级），再尝试 `CanItemMerge`，再尝试 `ItemSwallow:CanSwallow`，目标不可移动则复位，否则交换。

空位移动的原子写入是 `_SetItem(source,nil,false)` → `_SetItem(target,item,false)` → `_LogMove` → `SetPosition` → `_UpdateAccelerate` → `ItemMoveEnd`。交换则清空源格、写入拖入物、写回原目标物，分别记录两条 Move 日志，再更新两个位置；所有 `_SetItem` 都传 `false`，所以移动/交换不在中间刷新订单状态。

**源码**：`MainBoardModel:DragItem`、`BaseBoardModel:_SetItem`、`MainBoardModel:_UpdateAccelerate`。`CanItemMove` 会拒绝纸箱、蜘蛛网、锁定组件，吞噬棋子还必须允许点击；这些资格检查不能简化成“目标为空/不为空”。

---

## 贯穿案例：两个 201 合成 202


拖动 201 到另一个 201：两个输入被消耗，目标格变为 202，源格腾空。本地映射 201.MergedType=202，结果 202.BubbleChance=0，所以本例不会产生普通气泡；特殊棋子分支也未执行。坐标与动画未有运行时回放。
