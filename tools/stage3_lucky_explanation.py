"""Add reviewed causal explanations without rebuilding user-edited examples/tables."""
from pathlib import Path

START = '<!-- lucky-classification-explanation:start -->'
END = '<!-- lucky-classification-explanation:end -->'

EXPLANATIONS = {
    'output/index.md': '''## 产出内部修正如何配合

候选选择并不等于最终产物。各个修正仍在上述顺序中执行，[产出改写与数值边界](../overrides/index.md)集中说明它们分别嵌入哪个位置；这个说明页不增加新的点击阶段。
''',
    'lucky/index.md': '''## Super Lucky 是否多给一次机会？

不会。机会判定回答“本次是否 Lucky”，物品抽取回答“得到哪个物品”；[Super Lucky 分类](items/type.md)发生在物品抽取之后，用来识别抽中的物品应采用普通还是 Super 表现。这里没有第三次“是否超级”的随机判定，也没有再送一次 Lucky 机会。

连续 Lucky 会使后续点击直接取得资格；GeneratorBoost 的额外 Lucky Buff 可以在另一个空格追加物品。这两种机制有各自的状态和条件，不能与 Super Lucky 的分类混为一谈。

| 机制 | 它实际改变什么 | 是否因此增加本次物品数 |
|---|---|---|
| 普通 Lucky 机会池 | 决定本次是否取得资格，并消费周期计数 | 本分支选择一个产物，不等于普通产物之外再加一个 |
| 免费 Lucky | 普通机会失败后，用能量阈值队列提供资格；不消费普通总机会 | 本分支仍选择一个产物；“免费”指资格路径，不能据名称推断本次免扣能量 |
| 连续 Lucky | 保存后续同类型母体点击的次数与有效期；后续点击不再抽普通机会 | 二连/三连不等于一次点击同时生成两件/三件 |
| Super Lucky | 已抽物品的分类与表现 | 分类本身不追加物品 |
| Lucky Smart Produce | 根据订单等状态修正选择物品的权重 | 本身不增加物品数 |
| GeneratorBoost 额外 Lucky | Buff 与空位条件成立后，在另外空格复制本次最终产物 | 会追加一件；与 Super 分类独立 |
''',
    'lucky/items/index.md': '''## 物品抽取与 Super 分类的顺序

1. 先按普通权重或 Smart Produce 修正后的权重，从同一个 `lucky_items` 池选择物品。
2. 若连续 Lucky 已指定 Double/Triple 类型，保留该类型；否则检查选中物品是否属于 `super_items`，并结合免费资格选择 Lucky、SuperLucky、FreeLucky 或 FreeSuperLucky。
3. 类型和物品一同返回。Super 名称影响后续表现，不会要求另抽一个物品或另扣一份机会。

因此 `super_items` 是对物品的分类名单，不是另一个奖池。细节见[Super Lucky：奖励分类与表现](type.md)。
''',
    'lucky/items/type.md': '''## 这一步做什么，不会增加什么

Super Lucky 是对**已经抽出的物品**进行分类，并选择对应表现。`super_items` 列出哪些物品采用 Super 分类；系统不从这份名单再次抽奖。分类本身不新增随机数，不重新消耗机会池、不另生成一件奖励，也不提升已经选中的物品等级。

### 按实际执行顺序分类

1. `_GetGenerateLuckyItem` 先从 `config.lucky_items` 抽取 `luckyItems`。Smart Produce 开启时使用临时 `Weight_Smart`，否则使用普通 `Weight`。
2. 先读取 `customSpreadType`。连续 Lucky 已传入 DoubleLucky / TripleLucky1 / TripleLucky2 时，直接保留，跳过下面的普通/Super分类。
3. 没有自定义类型时，检查 `luckyItems.Item` 是否在 `config.super_items` 中，再结合 `isFree` 设置类型。
4. 返回同一个 `luckyItems.Item` 与分类结果。该函数没有在物品池中扣除选中物品的权重；Super 分类也不修改之前的机会池计数。

| 已有连续自定义类型 | 免费资格 | 属于 super_items | 返回类型 |
|---|---|---|---|
| 有 | 任意 | 不再检查 | 原有 DoubleLucky / TripleLucky 类型 |
| 无 | 否 | 否 | Lucky |
| 无 | 否 | 是 | SuperLucky |
| 无 | 是 | 否 | FreeLucky |
| 无 | 是 | 是 | FreeSuperLucky |

```python
item = weighted_select(lucky_items, smart_weight_if_enabled)
if custom_type is not None:
    spread_type = custom_type
elif is_free:
    spread_type = "FreeSuperLucky" if item in super_items else "FreeLucky"
else:
    spread_type = "SuperLucky" if item in super_items else "Lucky"
return item, spread_type
```

### 为什么玩家会感觉它是一种更大的奖励？

已恢复视图代码给 SuperLucky / FreeSuperLucky 选择专用的上下层 Super 特效；棋盘视图选择 `sfxLuckyProduce2` 音效和 `ItemSpreadPromptLuckySuper` 提示。普通 Lucky 使用另一组表现。因此相同的一次产物生成会以不同方式强调给玩家。

分类依据是**抽中的原始物品**。之后 `ItemSpread:TryGenerateLuckyItem` 还可能按活动调整后的能量增益档沿 `MergedType` 升级物品，但不会在该函数内重新进行 Super 分类。复刻时应分别保存原始抽取结果、分类类型和最终落子代码。

### 活动追加奖励应怎样理解？

GeneratorBoost 监听 `ItemSpread` 事件。母体支持 GeneratorBoost 时，Lucky、SuperLucky、FreeLucky、FreeSuperLucky 都可进入 `TryExtraLuckyProduceItem`；该函数还要求 ExtraLuckyProduce Buff 生效并找到空格，才在该空格生成与本次最终产物同类型的物品，参数为 `costEnergy=false`、`spreadType=GeneratorBoostExtraLucky`。

这份追加奖励来自独立活动 Buff，不是 Super 分类独有的奖励，也不是又抽了一次 Super 奖池。新生成的物品仍进入棋盘事件链；该链全部消费者及实际账号活动状态需要进一步验证。

### 如何计算 Super 物品的占比？

没有连续自定义类型时，在“已经取得 Lucky 资格”的条件下，Super 分类占比为：`super_items 中候选物品的有效权重之和 / lucky_items 全部有效权重之和`。Smart 开启时使用修正后的有效权重，不能仍套原始权重。这个占比是已有物品抽样的结果分类，不是额外机会概率；若要算一次点击的最终概率，还需考虑资格路径、等级/活动配置与连续类型。

**底层证据**：LuckyProduceModel `_GetGenerateLuckyItem`（215–234）、`IsSuperLuckyProduce`（250–255）；ItemSpread `TryGenerateLuckyItem`；GeneratorBoostActivityModel `_OnItemSpread`、`TryExtraLuckyProduceItem`；MainBoardView 的产出音效分派与 `_PlayItemSpreadPrompt`；Super 特效分派。分类与上述消费者分支为 `source-confirmed`，实际活动配置、消费者完整闭包和原版表现回放为 `runtime-pending`。
''',
}


def supplement_lucky_explanation(docs: Path) -> None:
    for rel, body in EXPLANATIONS.items():
        p = docs / 'operations/generator' / rel
        text = p.read_text(encoding='utf-8')
        if START in text:
            before, rest = text.split(START, 1)
            _, after = rest.split(END, 1)
            text = before.rstrip() + '\n\n' + after.lstrip()
        marker = '\n---\n'
        if marker not in text:
            marker = '\n\n---\n'
        head, separator, tail = text.partition(marker)
        text = head.rstrip() + '\n\n' + START + '\n\n' + body.strip() + '\n\n' + END + '\n' + separator + tail
        text = text.replace('Super/Free 产出类型', 'Super Lucky：奖励分类与表现')
        if rel == 'lucky/items/type.md':
            text = text.replace('并进入 SuperLucky 后续池', '，物品仍来自前面已经完成的同一次抽取，并采用 Super 专用表现；没有进入独立奖池')
            old = '假设 `super_items={205}`，候选先抽到 205'
            if old in text and '下面保留两个独立对照场景' not in text:
                text = text.replace(old, '主案例沿用前文：抽到 204、`isFree=false`，204 不在 Super 名单内，因此返回普通 `Lucky`，不发生第二次抽样。下面保留两个独立对照场景，用来解释其它类型；它们不是主案例的后续步骤。\n\n' + old)
        p.write_text(text, encoding='utf-8')
