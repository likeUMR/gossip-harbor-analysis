# 状态字段与计时模型

`ItemSpread:Init` 把 `ItemModelConfig` 的 Spread 字段复制到实例，建立运行时状态：自动标记、初始化/开启/恢复时长、各阶段加速费用、能量开关、次数上限、储备上限、变换次数和权重池。次数和储备从各自最大值开始，`m_spreadCount` 从 0 开始。

初始状态由配置决定：有 `Spread_InitDuration` 就是 `Initializing`；否则有 `Spread_OpenDuration` 就是 `Closed`；两者都没有就是 `Opened`。教程强制时长只替换非空字段，不会凭空给母体增加一个计时阶段。`IsDisposable()` 的定义是 `Spread_ItemRecoveryDuration` 为 nil；恢复时长为0不满足这个条件，不能按一次性母体处理。它决定耗尽后的删除和恢复分支。

**源码**：`ItemSpread:Create`、`Init`、`IsDisposable`、`GetState`、`GetItemRestNumber`、`GetStorageRestNumber`、`GetWeightType`、`GetTransformNumber`。字段来源为 `ItemModelConfig`；教程覆盖为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例服务端状态被解释为“已打开”，所以进入正常点击流程；若状态表示“开启中”，玩家会看到开启中的状态反馈并等待，而不会得到产物。

### 代入本页的值

假设模型状态值为 3，映射为 Opened，状态检查通过并进入产出；若值为 2，映射为 Opening，发送 ItemOpening 后返回 false，产出函数不会被调用。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Sta

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>
