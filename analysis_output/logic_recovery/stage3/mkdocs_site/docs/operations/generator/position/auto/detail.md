# 自动母体为何可能忽略点击，以及棋盘满如何缓存

## 点击与自动更新的关系

手动 CheckSpreadPosAndAuto 对自动母体先查询自动落点：如果能找到，直接返回false，交给 Update 的自动循环处理，不另外因手动点击产出。自动落点为空才继续手动的方形环落点检查；因此“自动母体点击无反应”可能是主动避免重复产出，不是棋盘满错误。

Update 只有 Spread_Auto==1 才反复调用 _TryAutoSpread，直到返回false。这里严格比较数值1；布尔true不等于1，不能用“字段非空”代替。每轮要求次数不为0且状态Opened；一次性自动母体走全盘随机空格，可恢复自动母体只扫描固定八邻域。

## 无空位的特殊缓存

只有一次性、Decremental、棋盘提供CacheItemFromSpread、AutoSpreadToCache开关开启，四项同时成立才允许缓存。没有空位时GetAutoSpreadDecrementalRemainTypes把剩余权重逐份展开成列表，缓存后m_spreadCount加列表长度，EmptySpreadCount清次数、储备与实例权重，更新计时、通知并保存。不是所有自动母体都会转缓存。

## 自动路径与手动的区别

有位置时自动路径调用GenerateItemCode并落子，但只取其第一个返回值，落子参数默认增益0；存在ItemDig时标记Dig且costEnergy=false。此处不调用手动SpreadCostEnergy，也不调用手动TryRemoveSelf；无ItemDig且到变换点击数时执行Transform并停止。次数0后下一轮停止。不能把手动点击的销毁、事件类型、费用顺序直接套给自动路径。

**来源**：Update、IsAutoSpread、_TryAutoSpread、_GetAutoSpreadPosition、CheckSpreadPosAndAuto、GetAutoSpreadDecrementalRemainTypes、EmptySpreadCount、MainBoardModel.FindSpreadPosition。动态缓存开关与棋盘实现需运行验证。

---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：食品袋105的主案例不是自动母体，自动路径不执行。下面对照说明自动Decremental母体在棋盘满时如何缓存剩余配额，而非无限重试点击。

### 代入本页的值

独立对照假设自动、一次性、Decremental母体余池[201×2,202×1]，没有空格；棋盘实现缓存且开关开启时缓存[201,201,202]，点击累计加3，次数与储备及权重归零。四条件任一不成立则停止，不生成、不缓存。这些自动母体字段是演示输入，不能套给105。

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
