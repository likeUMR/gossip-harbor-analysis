# 次数与储备上限修正

`SafeSpreadItem` 在 `_GenerateItemCode` 前执行。若 `m_itemRestNumber > m_itemMaxNumber`，记录 `{rest,max}` 的 `ItemRestNumberOverflowError` 后截回最大值；若储备存在且 `m_storageRestNumber > m_storageMaxNumber`，同样记录 `StorageRestNumberOverflowError` 并截回。它不改变 `m_spreadCount` 或权重。自动缓存的另一条路径随后调用 `EmptySpreadCount`：次数、储备都置零，Decremental 的 `m_codeWeightPairs` 置为空表，更新计时、派发 `StateChanged` 并保存属性。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
---

<!-- reconciliation-reload:start -->
## 活动替换配置与当前母体实例的区别

GeneratorBoost的GetItemModelConfig依次判断MoreLuckyProduce、ExtraLuckyProduce、ExtraProduce，返回第一个生效Buff的对应本地表；都未生效则返回nil。ReloadItemModelConfig在非nil配置时重建变化类型集合，然后交给ItemDataModel:ReloadFileConfig；传nil时没有在这里清空变化类型集合。

ItemDataModel重载要求GeneratorBoost模型存在。传入替代表时只遍历该表，将记录按Type写入配置映射；传nil时遍历默认ItemModel，变化集合不存在就全恢复，否则只恢复集合中的类型。记录ChainId为nil时才解析链号和等级，并把Spread_Weight字符串转为Code/Weight数组、保存其字符串形式；已经有ChainId则跳过这些预处理。

这段重载修改配置映射，没有直接遍历现有棋子重新Init，也没有在这里改已有实例的次数、CD起点或权重池。SafeSpreadItem比较的是实例保存的上限；不能认为替换配置后，它会自动用新表上限裁剪旧实例。新对象和重建对象取得哪份配置，由实际创建路径决定。

<!-- reconciliation-reload:end -->

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：当前可用次数或储备超过母体允许的上限时，先修正回上限，再继续普通产出；这里不是能量余额检查，也不会因为发生上限修正就直接拒绝产出。

### 代入本页的值

假设食品袋105的可用次数上限80、储备上限240，但当前次数90、储备250、累计产出7，剩余权重池为201×35、202×2、301×5。先比较90>80，记录次数溢出并改为80；再比较250>240，记录储备溢出并改为240。累计产出仍7、权重池仍原值，随后继续普通产出计算。玩家不会获得超出上限的额外10次或10份储备；本步骤本身不扣能量，也没有返回“安全检查失败”。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- 母体配置与包内变体：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。


<!-- generator-configs:end -->

<!-- source-links:start -->

## 对应源码

[ItemSpread.lua](../../../../assets/recovered-source/ItemSpread.lua)

<!-- source-links:end -->
