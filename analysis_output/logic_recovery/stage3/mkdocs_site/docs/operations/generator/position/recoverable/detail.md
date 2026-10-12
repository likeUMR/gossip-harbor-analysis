# 可恢复落点的具体算法

手动点击仍由 `CheckSpreadPosAndAuto` 调用 `FindEmptyPositionInSpreadOrder`，算法是从母体坐标向外扩大的方形环扫描；“可恢复”只影响 `IsDisposable()`、次数耗尽和恢复计时，不改变手动落点函数。自动产出才走 `FindEmptyPositionInCircleOrder`：按 `dir=1..8` 检查母体八个相邻格，先通过 `PositionIsValid` 再检查为空，返回第一个空位；八邻域全部占用时返回 nil。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页具体说明可恢复母体如何按顺序搜索空位；找到空位就落子，找不到则显示棋盘已满。

### 代入本页的值

假设搜索顺序为 P1、P2，P1 已占用、P2 空闲。`FindEmptyPositionInSpreadOrder` 依次判断 `occupied(P1)=true`、`occupied(P2)=false`，返回 P2；若两者都占用则返回 nil。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- 母体配置与包内变体：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。


<!-- generator-configs:end -->
