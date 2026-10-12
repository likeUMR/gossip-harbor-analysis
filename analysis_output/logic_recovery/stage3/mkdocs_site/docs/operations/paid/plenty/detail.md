# 礼包集合与批量奖励
`PlentyBundle` 映射到 BundlePlentyModel。奖励数组顺序、重复资源和每个 goods 类型必须保留，不能压缩成总数；读取 group config、解析 goods、关联 purchaseId、资格检查后逐项发放并写恢复记录。payload runtime-pending。
