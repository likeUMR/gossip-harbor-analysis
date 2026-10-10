# 合成副产物

顺序是 `TempItem.GenerateType` → `CardItem.TryGenerateItem` → `EnergyBubble.CanSpreadEnergyBubble` → `_TrySpreadBubbleByMerge` → 独立金币检查。前四类用 `hasCreateItem` 互斥，金币检查在之后单独执行，均需有效空位。

- [普通气泡](bubble.md)
- [卡牌、能量气泡和临时棋子](activity.md)
- [金币](coin.md)

---

## 贯穿案例：两个 201 合成 202


拖动 201 到另一个 201：两个输入被消耗，目标格变为 202，源格腾空。本地映射 201.MergedType=202，结果 202.BubbleChance=0，所以本例不会产生普通气泡；特殊棋子分支也未执行。坐标与动画未有运行时回放。
