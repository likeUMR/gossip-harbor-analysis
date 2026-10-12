# 合成与订单再分析范围

本批按 `GH_LOGIC_RECOVERY_PLAN.md` 6.8 的环节0至环节9执行，范围锁定为：

1. 合成后 `MergeItem → ItemMerged → OnShock → ItemShocked` 的事件顺序、活动消费者、任务进度、数据库写入、目标截断、联网/离线完成分支。
2. 订单完成后 `OrderFinished → UpdateOrderState → SmileOrderDeliver_1 → CheckMoreUpload → FinishOrder` 的业务与视图边界。
3. `MainOrderCreated` 在新订单写入槽位之前的消费者时序。

页面已同步到 `mkdocs_site/docs/operations/merge` 与 `mkdocs_site/docs/operations/orders`。本批不把动态远端配置、Unity 原生持久化或原版运行差分假设为已知。
