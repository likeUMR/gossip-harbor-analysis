# 触发窗口、过期与展示资格

`BundleServerConfigData` 暴露 groupId、purchaseId、trigger item、priority、trigger interval、duration、last duration 和 daily popup count；本地配置保存 refreshType、condition、buyCount。

事件/计时触发后先做 condition/trigger item，再检查同组、购买、冷却和弹窗次数，最后按 priority 展示。假设同组优先级 10 和 5 同时满足，只展示 10；其过期后 5 才有机会展示。实际同组数据 runtime-pending。
