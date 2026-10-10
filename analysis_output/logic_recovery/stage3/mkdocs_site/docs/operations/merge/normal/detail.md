# 合成原子操作与事件顺序

基础合成先 `RemoveItem(item,false)` 删除拖入物，再决定输出代码：普通物品取拖入物的 `MergedType`，临时物品取目标物的 `MergedType`。生成前查询是否首次解锁，然后 `ReplaceItem` 删除目标并在原目标位置创建新棋子、写入 ItemManager 和棋盘。之后构造包含 Source、Target、New、原始 code 和首次解锁标记的 `MergeItem` 消息，依次发送 `BoardEventType.MergeItem` 与 `EEventType.ItemMerged`，最后震动四个正交邻格并发送 `ItemShocked`。

MainBoardModel 后处理再按 `TempItem` → `CardItem` → `EnergyBubble` → 普通气泡的顺序寻找一种主副产物；任何一种成功都会阻止后续三种。金币检查独立于这个互斥标记，仍可能在同一次合成后生成。最后调用 `CheckMoreUpload`。

**证据**：`BaseBoardModel:_DoMergeItem`、`MainBoardModel:_DoMergeItem`。`MergedType` 是实例初始化时从 `ItemModelConfig` 复制的直接字段，不是运行时按等级推导。

---

## 贯穿案例：两个 201 合成 202


拖动 201 到另一个 201：两个输入被消耗，目标格变为 202，源格腾空。本地映射 201.MergedType=202，结果 202.BubbleChance=0，所以本例不会产生普通气泡；特殊棋子分支也未执行。坐标与动画未有运行时回放。
