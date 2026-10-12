# 初始化计时的具体判定

`Init` 先把 `Spread_InitDuration` 复制到 `m_initDuration`；存在该字段就把 `m_state` 设为 `Initializing`，随后立即调用 `UpdatePerSecond` 写入服务器时间 `m_startTimer`。点击时 `CheckSpreadState` 先排除 Closed/Opening，再因 Initializing 派发 `ItemRecharging`（可恢复母体）并返回 false；因此不会扫描空位，也不会读取能量。计时达到 `GetTimerDuration()` 后 `_UpdateRecoveryState` 清空计时、改为 Opened、派发 `EEventType.ItemOpened` 并刷新棋盘开启列表。

<!-- reconciliation-failure:start -->
## 被初始化或零次数拦截后，界面如何响应

主棋盘的失败提示由 `MainBoardView:_OnSpreadFailed` 接收棋盘事件后处理。提示位置取母体视图位置加 `(0,100,0)`，再转换为屏幕坐标；母体视图已不存在时，用 `V3Zero` 加同一偏移。失败还发送全局 SpreadFailed：Disco 教程若处于 `m_OnTapState`，会清除强制源格和目标格，再执行第三段教程。因此“没有产出”不等于“没有其它响应”；该教程回调不检查失败原因。

只有可恢复母体会送出本分支的 ItemRecharging 原因。视图选择 `hint_item_recharging`，播放 `SfxColdingClick`，取得母体 ItemSpread 组件；组件存在时计算 `恢复时长＋开始时间－服务器当前时间`，剩余时间至少1200秒才尝试微信冷却恢复订阅窗口。随后显示提示并强调跳过按钮。这个微信订阅尝试发生在局部失败事件处理中，与 OnTap 循环结束后的 iOS 通知尝试是两个不同入口。一次性母体在该阻止分支没有失败事件，因此不经这条提示和教程响应链。
<!-- reconciliation-failure:end -->

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/item-105.png" alt="食品袋 105" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页具体说明初始化状态如何拦截点击：系统只推进恢复计时，不扫描空位、不扣能量。

### 代入本页的值

假设 `m_state=4 (Initializing)`、次数 80、`Spread_ItemRecoveryDuration=30`。前两项 Closed/Opening 不成立，`state==Initializing` 为真；恢复时长非空，发送 ItemRecharging 失败通知并停止，次数仍80、能量仍10，不生成棋子。若保持初始化状态但恢复时长为 nil（一次性母体），仍返回 false，却不发送这条失败通知。把状态改为3且次数改为0时，也进入同一阻止分支，是否通知仍由恢复时长是否为 nil 决定。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

## 本逻辑使用的配表在哪里

- 母体配置与包内变体：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。


<!-- generator-configs:end -->
