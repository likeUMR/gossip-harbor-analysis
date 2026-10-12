# 周期、阶段推进与购买记录

`BundleServerConfigData` 提供 weekly day-of-week、chain step、free、skin 和价格描述；`BundleChainModel` 提供 `GetNextBundlePayID`、`BuyBundle`、`GetCurChainStep`、`GetChainTriggerTime`。

周期/链触发后读取当前 step 与已购记录，判断 free 或 purchaseId 价格；成功后推进 step、写记录和过期时间；周期边界重置/关闭。假设三步为免费、¥6、¥30，第二步购买失败不推进。步骤 payload runtime-pending。
