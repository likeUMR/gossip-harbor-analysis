# 棋子拖拽与合成

入口 `MainBoardModel:DragItem` 的优先级是：非法目标、源身份、空位移动、特殊影响、普通合成、吞噬、不可移动目标、交换。

- [拖拽分派与移动](dispatch.md)
- [普通合成](normal.md)
- [特殊棋子与吞噬](special.md)
- [合成副产物](effects/index.md)

---

## 贯穿案例：两个 201 合成 202

<div class="case-assets"><img src="../../../assets/cases/merge.png" alt="两个 201 合成 202" class="case-composite" style="display:block;max-width:560px;width:100%;height:auto;"></div>

拖动 201 到另一个 201：两个输入被消耗，目标格变为 202，源格腾空。本地映射 201.MergedType=202，结果 202.BubbleChance=0，所以本例不会产生普通气泡；特殊棋子分支也未执行。坐标与动画未有运行时回放。
