# 普通气泡

```text
功能关闭 -> 结束
p = newItem.BubbleChance
已有相同 inner bubble -> 取消
购买加成或订单加成 -> p = 100
否则依次乘高等级衰减、订单缺口衰减、BubbleDecrease 全局衰减
p = max(p,1); 测试开关 -> p=100
r = Random(100); p >= r -> 生成 Bubble + newItem.Type
```

**配表**：`ItemModelConfig.BubbleChance`，当前 138 行大于 0；服务端 BubbleDecrease 和购买/订单修正。**源码**：`_TrySpreadBubbleByMerge`。基础顺序 `source-confirmed`，服务端值 `runtime-pending`。

---

## 贯穿案例：两个 201 合成 202


拖动 201 到另一个 201：两个输入被消耗，目标格变为 202，源格腾空。本地映射 201.MergedType=202，结果 202.BubbleChance=0，所以本例不会产生普通气泡；特殊棋子分支也未执行。坐标与动画未有运行时回放。
