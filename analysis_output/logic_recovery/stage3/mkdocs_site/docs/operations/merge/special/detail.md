# 升级、降级和吞噬的具体算法

特殊棋子在普通合成前处理。LevelUp 确认窗口通过二次 `CanItemAffect` 校验后，删除升级棋、用目标的 `MergedType` 替换目标并发送合成/邻格震动事件；确认等待期间拖入物先复位。LevelDown 对普通目标读取目标链的前一级，消耗剪刀次数，删除目标并在目标位置和扩散扫描得到的第二空位各生成一个前一级；两把剪刀相遇时删除两者，生成一把新剪刀，并把两者剩余使用次数相加。

吞噬资格要求两个配置槽中存在相同 code 且该槽 `Swallowed < Count`。成功后先增加对应槽进度并保存目标属性，再移除拖入物、发送 `SwallowItem` 事件和 BI；两个槽都达到 Count 才 `ItemTransform:Transform`。目标 code 的选择不是每次独立随机：`ItemFixedSwallowModel` 把每槽权重展开为 `[1..W]`，用从 W 到 1 的 Fisher-Yates 洗牌持久化序列，取出序列头并按累计权重映射 code，消费后立即写回剩余序列；序列耗尽才重建。因此同一 code 可按 Weight 出现多次，但在一轮序列内属于无放回抽样。

**源码**：`MainBoardModel:_AffectItem`、`ItemSwallow:CanSwallow`、`ItemSwallow:Swallow`、`ItemFixedSwallowModel` 反汇编。权重数值以当前配置快照为准。

---

## 贯穿案例：两个 201 合成 202


拖动 201 到另一个 201：两个输入被消耗，目标格变为 202，源格腾空。本地映射 201.MergedType=202，结果 202.BubbleChance=0，所以本例不会产生普通气泡；特殊棋子分支也未执行。坐标与动画未有运行时回放。
