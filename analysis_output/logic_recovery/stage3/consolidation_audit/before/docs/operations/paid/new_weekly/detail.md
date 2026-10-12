# 周期窗口与新周模型
同步 BundleData/MetaData 后读取 weekly trigger time，检查当前周窗口和 group duration，过滤购买/过期记录，再建立 purchaseId；成功购买写本周记录，周窗口结束清理。周起始日、窗口长度和奖励属于服务端组数据，当前 runtime-pending。
