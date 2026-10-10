# Lucky 判断

Lucky 判断的目的不是直接从 `lucky_items` 抽一个物品，而是先回答“这次点击是否获得 Lucky 资格”，再回答“如果获得，产出哪一个 Lucky 物品”。两问使用不同状态和不同随机语义。

## 实际执行顺序

1. **确认 Lucky 是否可用**：检查 Lucky 活动是否处于 Started，并根据母体类型和玩家等级选择适用配置；没有配置就结束 Lucky 分支。
2. **优先处理已有连续 Lucky**：如果数据库中记录的连续 Lucky 目标类型、次数和有效期仍匹配当前母体，直接沿用连续 Lucky，不重新抽周期机会。
3. **检查 GeneratorBoost 特殊入口**：活动持有额外 Lucky 且空位条件允许时，直接走 Lucky 物品选择；空位不足时保存延迟状态并结束。
4. **读取周期机会池**：读取总机会和 Lucky 配额；总机会为 0 时用配置重新装填。
5. **进行机会判定**：在 `1..total` 中抽一个整数，比较是否落入 Lucky 配额；这一步决定是否有普通 Lucky 资格。
6. **机会未命中时检查免费 Lucky**：只有普通机会未命中，才检查免费阈值队列；命中免费阈值会把本次改为 Lucky，但不消耗普通总机会。
7. **写回机会池计数**：普通 Lucky 消耗 Lucky 配额；非免费 Lucky 消耗总机会。机会池处理完后，才进入产物选择。
8. **尝试触发下一次连续 Lucky**：根据当前能量段配置依次判断三连和二连，并写入连续 Lucky 状态。
9. **选择 Lucky 物品**：按普通或 Smart Produce 权重池累计选择一个物品，再根据是否 Super/Free 设置产出类型。

## 设计含义

机会池控制 Lucky 的“资格”，物品池控制 Lucky 的“内容”；免费 Lucky 是对机会判定失败后的补救入口；连续 Lucky 是对本次 Lucky 结果设置的后续状态。把它们合并成一个概率表会丢失计数扣减、免费机会和连续状态。

左侧四个子节点是第三层机制；继续展开后才进入第四层的读取、判断、写回和抽样细节。

**源码**：[LuckyProduceModel.lua](/C:/Users/TU/Documents/ChatGPT/Gossip_Harbor_Analysis/analysis_output/logic_recovery/stage3/937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua)，主入口 `Try2ProduceLuckyItem`。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"><img src="../../../../assets/cases/item-204.png" alt="Lucky 产物 204" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例有适用的 Lucky 配置。先检查活动、等级和已有连续资格，再抽周期机会；失败才检查免费资格。A 未命中回普通池，B 命中再抽 Lucky 物品。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>
