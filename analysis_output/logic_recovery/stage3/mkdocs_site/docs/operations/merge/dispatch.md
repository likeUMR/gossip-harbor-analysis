# 拖拽分派与移动

```text
目标非法 -> 恢复原位
源身份不符 -> 恢复原位
目标为空 -> 移动并发送 ItemMoveEnd
CanItemAffect -> LevelUp / LevelDown
CanItemMerge -> 普通合成
ItemSwallow -> 吞噬
目标不可移动 -> 恢复原位
否则 -> 交换
```

**源码**：`MainBoardModel:DragItem`、`CanItemMerge`。每个恢复路径需要独立回放验证。

---

## 贯穿案例：两个 201 合成 202

<div class="case-assets"><img src="../../../assets/cases/item-201.png" alt="棋子 201" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin-right:12px;"></div>

拖动 201 到另一个 201：两个输入被消耗，目标格变为 202，源格腾空。本地映射 201.MergedType=202，结果 202.BubbleChance=0，所以本例不会产生普通气泡；特殊棋子分支也未执行。坐标与动画未有运行时回放。
