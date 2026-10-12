# 互斥顺序与落点算法

合成完成且棋盘未满时，先调用 `TempItem:GenerateType`；成功就从合成物周围按 `FindEmptyPositionInSpreadOrder` 生成临时棋子并停止。没有临时棋子才调用 `CardItem:TryGenerateItem`，成功后生成卡牌并派发 `CardItemGenerate`。再没有卡牌才检查 `EnergyBubble:CanSpreadEnergyBubble` 并按其 `GetBubbleInfo().Code` 生成。前三类都通过 `hasCreateItem` 互斥，普通气泡位于其后。

每一步都必须有合法空位；满盘会跳过该副产物，不会把它改成随机落点。金币不受 `hasCreateItem` 互斥限制，独立在之后检查。

---

## 贯穿案例：两个 201 合成 202


拖动 201 到另一个 201：两个输入被消耗，目标格变为 202，源格腾空。本地映射 201.MergedType=202，结果 202.BubbleChance=0，所以本例不会产生普通气泡；特殊棋子分支也未执行。坐标与动画未有运行时回放。
