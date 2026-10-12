# 缺口触发、优先级与礼包内容

`BundleOrderItemConfigDataGroup` 提供 `GetPriority`、`GetTriggerItem`、`GetLastDuration`、`GetGroupTriggerInterval`、`GetModelTriggerInterval`，并读取 item level 和 bundle title key。

读取订单/触发棋子后做等级与缺口筛选，再过滤已购、过期和同组，按 priority 选中并由 purchaseId 关联 goods 与价格。假设订单缺少 2 个 3601，等级 3 优先级 8 高于等级 4 优先级 5；礼包到账不直接完成订单，仍须经过库存和提交链路。奖励 payload runtime-pending。
