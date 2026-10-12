# 普通合成

`CanItemMerge` 要求类型相同、至少一方有 `MergedType`，且已使用的一次性箱子不能合成。`_DoMergeItem` 将目标替换为 `MergedType`，移除源棋子，保存新属性，发送 `BoardEventType.MergeItem` 和 `EEventType.ItemMerged`。

**配表**：`ItemModelConfig.MergedType`，当前 370 行。**源码**：`BaseBoardModel:_DoMergeItem`、`MainBoardModel:_DoMergeItem`。活动监听器静态已定位，动态对象身份 `runtime-pending`。

---

## 贯穿案例：两个 201 合成 202


拖动 201 到另一个 201：两个输入被消耗，目标格变为 202，源格腾空。本地映射 201.MergedType=202，结果 202.BubbleChance=0，所以本例不会产生普通气泡；特殊棋子分支也未执行。坐标与动画未有运行时回放。
