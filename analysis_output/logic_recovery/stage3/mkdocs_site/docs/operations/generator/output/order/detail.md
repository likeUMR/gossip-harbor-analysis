# OrderItem 的具体选择

`GetOrderItemCode` 先调用 `CalculateOrderCodeLackNumMap(false,true,false)`，只以当前订单缺口作为第一层候选。每个缺口代码的候选权重为 `min(OrderItemConfig[code].DiffScore,300)`；如果代码出现在 `GetOrderBoostOrderCodeLackMap()`，再乘 1000。循环内用 `Table.ListWeightSelectOne` 选一个目标并立即 `Table.ListRemove`，然后 `_TryGenerateItemCodeByOrderItem` 在 `m_codeWeightPairs` 中筛同链且等级低于目标的代码，用 `Table.ListRandomSelectOne` 均匀选具体产物；没有可选产物就继续尝试其它目标。全部缺口失败后 `_TryGenerateItemCodeAll` 只保留配置存在且其链的生成器已解锁的代码，再随机选一个；仍无候选时回退到原权重池。`CosetRestNumber` 对 OrderItem 查选中代码的 `Weight` 作为 `costCount`，不是固定扣 1。

**证据状态**：主判断和字段为 `source-confirmed`；服务器开关、动态活动对象、实际回放时序为 `runtime-pending`。
---

## 贯穿案例：点击食品袋 105

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本页具体说明订单专用母体如何把订单条件转成候选，并生成玩家需要的物品。

### 代入本页的值

假设 `m_weightType=3`、`OrderItem=3`，条件成立，先读取订单难度 2，再把难度修正应用到候选权重；若类型为 1，`1==3` 为假，订单难度不参与。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- generator-configs:start -->

<a id="configuration-order-item"></a>

## 本页涉及的配表：产物难度分与解锁配置

**实际读取链**：`ItemSpread:GetOrderItemCode 读取 Slot:GetItemCodeConfigMap()[code].DiffScore；ChestCustomItem 与 SmartItem 复用同一个代码配置映射。`

本组配表集中展示在本页；其它使用同一份已加载配置的页面提供查阅链接。包内值与服务器生效值分开标注。


### 产物评分与解锁配置（74 条）

来源：`analysis_data/json/OrderItemConfig.json`。列出全部可配置候选；本次候选仍受订单缺口、库存和解锁条件筛选。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 74 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>产物 ID<small style="display:block">Code</small></th><th>产物难度分<small style="display:block">DiffScore</small></th><th>解锁等级<small style="display:block">UnlockLevel</small></th><th>订单权重<small style="display:block">Weight</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/203.png" alt="203"><span><b>203</b><small>初学者的面包</small></span></span></td><td>2</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;203&quot;,
  &quot;DiffScore&quot;: 2,
  &quot;Price&quot;: 2,
  &quot;UnlockLevel&quot;: 1,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/204.png" alt="204"><span><b>204</b><small>长条面包</small></span></span></td><td>5</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;204&quot;,
  &quot;DiffScore&quot;: 5,
  &quot;Price&quot;: 4,
  &quot;UnlockLevel&quot;: 1,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/205.png" alt="205"><span><b>205</b><small>切片面包</small></span></span></td><td>10</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;205&quot;,
  &quot;DiffScore&quot;: 10,
  &quot;Price&quot;: 8,
  &quot;UnlockLevel&quot;: 1,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/206.png" alt="206"><span><b>206</b><small>黄油果酱吐司</small></span></span></td><td>19</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;206&quot;,
  &quot;DiffScore&quot;: 19,
  &quot;Price&quot;: 12,
  &quot;UnlockLevel&quot;: 1,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/207.png" alt="207"><span><b>207</b><small>果酱三明治</small></span></span></td><td>39</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;207&quot;,
  &quot;DiffScore&quot;: 39,
  &quot;Price&quot;: 20,
  &quot;UnlockLevel&quot;: 1,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/208.png" alt="208"><span><b>208</b><small>半个火腿三明治</small></span></span></td><td>78</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;208&quot;,
  &quot;DiffScore&quot;: 78,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 32,
  &quot;UnlockLevel&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/209.png" alt="209"><span><b>209</b><small>火腿奶酪三明治</small></span></span></td><td>146</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;209&quot;,
  &quot;DiffScore&quot;: 146,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 50,
  &quot;RepeatWeightDecrease&quot;: 10,
  &quot;UnlockLevel&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/210.png" alt="210"><span><b>210</b><small>厚切三明治</small></span></span></td><td>293</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;210&quot;,
  &quot;DiffScore&quot;: 293,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 78,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 50,
  &quot;UnlockLevel&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/211.png" alt="211"><span><b>211</b><small>百吉饼三明治</small></span></span></td><td>585</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;211&quot;,
  &quot;DiffScore&quot;: 585,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 118,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 100,
  &quot;UnlockLevel&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/212.png" alt="212"><span><b>212</b><small>火腿奶酪羊角面包</small></span></span></td><td>1170</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;212&quot;,
  &quot;DiffScore&quot;: 1170,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 178,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RecommendedNumber&quot;: 1,
  &quot;RecommendedPrice&quot;: 178,
  &quot;UnlockLevel&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/213.png" alt="213"><span><b>213</b><small>粘稠的芝士汉堡</small></span></span></td><td>2000</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;213&quot;,
  &quot;DiffScore&quot;: 2000,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 270,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RecommendedNumber&quot;: 1,
  &quot;RecommendedPrice&quot;: 270,
  &quot;UnlockLevel&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/214.png" alt="214"><span><b>214</b><small>芝士汉堡和薯条</small></span></span></td><td>2500</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;214&quot;,
  &quot;DiffScore&quot;: 2500,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 406,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RecommendedNumber&quot;: 1,
  &quot;RecommendedPrice&quot;: 406,
  &quot;UnlockLevel&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/215.png" alt="215"><span><b>215</b><small>豪华芝士汉堡餐</small></span></span></td><td>3000</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;215&quot;,
  &quot;DiffScore&quot;: 3000,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 612,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RecommendedNumber&quot;: 1,
  &quot;RecommendedPrice&quot;: 612,
  &quot;UnlockLevel&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/303.png" alt="303"><span><b>303</b><small>经典炸薯条</small></span></span></td><td>11</td><td>2</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;303&quot;,
  &quot;DiffScore&quot;: 11,
  &quot;Price&quot;: 8,
  &quot;UnlockLevel&quot;: 2,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/304.png" alt="304"><span><b>304</b><small>番茄酱薯条</small></span></span></td><td>23</td><td>2</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;304&quot;,
  &quot;DiffScore&quot;: 23,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 14,
  &quot;UnlockLevel&quot;: 2,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/305.png" alt="305"><span><b>305</b><small>一盘华夫饼薯条</small></span></span></td><td>46</td><td>5</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;305&quot;,
  &quot;DiffScore&quot;: 46,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 24,
  &quot;RepeatWeightDecrease&quot;: 10,
  &quot;UnlockLevel&quot;: 5,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/306.png" alt="306"><span><b>306</b><small>薯条鸡块组合</small></span></span></td><td>92</td><td>15</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;306&quot;,
  &quot;DiffScore&quot;: 92,
  &quot;DifficultyLevel&quot;: 7,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 38,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 50,
  &quot;UnlockLevel&quot;: 15,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/307.png" alt="307"><span><b>307</b><small>全家桶</small></span></span></td><td>184</td><td>20</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;307&quot;,
  &quot;DiffScore&quot;: 184,
  &quot;DifficultyLevel&quot;: 8,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 58,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RecommendedNumber&quot;: 2,
  &quot;RecommendedPrice&quot;: 58,
  &quot;RepeatWeightDecrease&quot;: 100,
  &quot;UnlockLevel&quot;: 20,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/503.png" alt="503"><span><b>503</b><small>即食咖啡杯</small></span></span></td><td>3</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;503&quot;,
  &quot;DiffScore&quot;: 3,
  &quot;Price&quot;: 2,
  &quot;UnlockLevel&quot;: 3,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/504.png" alt="504"><span><b>504</b><small>无咖啡因咖啡</small></span></span></td><td>5</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;504&quot;,
  &quot;DiffScore&quot;: 5,
  &quot;Price&quot;: 4,
  &quot;UnlockLevel&quot;: 3,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/505.png" alt="505"><span><b>505</b><small>普通咖啡</small></span></span></td><td>10</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;505&quot;,
  &quot;DiffScore&quot;: 10,
  &quot;Price&quot;: 8,
  &quot;UnlockLevel&quot;: 3,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/506.png" alt="506"><span><b>506</b><small>特调咖啡</small></span></span></td><td>21</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;506&quot;,
  &quot;DiffScore&quot;: 21,
  &quot;Price&quot;: 14,
  &quot;UnlockLevel&quot;: 3,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/507.png" alt="507"><span><b>507</b><small>加糖咖啡</small></span></span></td><td>42</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;507&quot;,
  &quot;DiffScore&quot;: 42,
  &quot;Price&quot;: 24,
  &quot;UnlockLevel&quot;: 3,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/508.png" alt="508"><span><b>508</b><small>拉花咖啡</small></span></span></td><td>84</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;508&quot;,
  &quot;DiffScore&quot;: 84,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 36,
  &quot;UnlockLevel&quot;: 3,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/509.png" alt="509"><span><b>509</b><small>焦糖玛奇朵</small></span></span></td><td>154</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;509&quot;,
  &quot;DiffScore&quot;: 154,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 56,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 10,
  &quot;UnlockLevel&quot;: 3,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/510.png" alt="510"><span><b>510</b><small>热巧克力</small></span></span></td><td>307</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;510&quot;,
  &quot;DiffScore&quot;: 307,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 88,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 50,
  &quot;UnlockLevel&quot;: 3,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/511.png" alt="511"><span><b>511</b><small>冰淇淋咖啡</small></span></span></td><td>617</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;511&quot;,
  &quot;DiffScore&quot;: 617,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 132,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 100,
  &quot;UnlockLevel&quot;: 3,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/512.png" alt="512"><span><b>512</b><small>蜜饯浆果咖啡</small></span></span></td><td>1229</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;512&quot;,
  &quot;DiffScore&quot;: 1229,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 202,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RecommendedNumber&quot;: 1,
  &quot;RecommendedPrice&quot;: 202,
  &quot;UnlockLevel&quot;: 3,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/513.png" alt="513"><span><b>513</b><small>咖啡甜点</small></span></span></td><td>2000</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;513&quot;,
  &quot;DiffScore&quot;: 2000,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 304,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RecommendedNumber&quot;: 1,
  &quot;RecommendedPrice&quot;: 304,
  &quot;UnlockLevel&quot;: 3,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/514.png" alt="514"><span><b>514</b><small>甜茶派对</small></span></span></td><td>2500</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;514&quot;,
  &quot;DiffScore&quot;: 2500,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 458,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RecommendedNumber&quot;: 1,
  &quot;RecommendedPrice&quot;: 458,
  &quot;UnlockLevel&quot;: 3,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/603.png" alt="603"><span><b>603</b><small>冰柠檬茶</small></span></span></td><td>14</td><td>4</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;603&quot;,
  &quot;DiffScore&quot;: 14,
  &quot;Price&quot;: 8,
  &quot;UnlockLevel&quot;: 4,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/604.png" alt="604"><span><b>604</b><small>乡村冰茶</small></span></span></td><td>27</td><td>4</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;604&quot;,
  &quot;DiffScore&quot;: 27,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 14,
  &quot;UnlockLevel&quot;: 4,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/605.png" alt="605"><span><b>605</b><small>冰茶罐</small></span></span></td><td>55</td><td>6</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;605&quot;,
  &quot;DiffScore&quot;: 55,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 24,
  &quot;RepeatWeightDecrease&quot;: 10,
  &quot;UnlockLevel&quot;: 6,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/606.png" alt="606"><span><b>606</b><small>高雅茶壶</small></span></span></td><td>110</td><td>15</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;606&quot;,
  &quot;DiffScore&quot;: 110,
  &quot;DifficultyLevel&quot;: 7,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 41,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 50,
  &quot;UnlockLevel&quot;: 15,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/607.png" alt="607"><span><b>607</b><small>精致茶饮</small></span></span></td><td>220</td><td>20</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;607&quot;,
  &quot;DiffScore&quot;: 220,
  &quot;DifficultyLevel&quot;: 8,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 62,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RecommendedNumber&quot;: 2,
  &quot;RecommendedPrice&quot;: 62,
  &quot;RepeatWeightDecrease&quot;: 100,
  &quot;UnlockLevel&quot;: 20,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/902.png" alt="902"><span><b>902</b><small>蜂蜜釉面鲑鱼</small></span></span></td><td>3</td><td>6</td><td>0</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;902&quot;,
  &quot;DiffScore&quot;: 3,
  &quot;DifficultyLevel&quot;: 3,
  &quot;Price&quot;: 4,
  &quot;UnlockLevel&quot;: 6,
  &quot;Weight&quot;: 0
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/903.png" alt="903"><span><b>903</b><small>整条烤鱼</small></span></span></td><td>7</td><td>6</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;903&quot;,
  &quot;DiffScore&quot;: 7,
  &quot;DifficultyLevel&quot;: 4,
  &quot;Price&quot;: 8,
  &quot;UnlockLevel&quot;: 6,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/904.png" alt="904"><span><b>904</b><small>双人份烤鱼</small></span></span></td><td>15</td><td>6</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;904&quot;,
  &quot;DiffScore&quot;: 15,
  &quot;DifficultyLevel&quot;: 5,
  &quot;Price&quot;: 14,
  &quot;UnlockLevel&quot;: 6,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/905.png" alt="905"><span><b>905</b><small>虾仁</small></span></span></td><td>30</td><td>7</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;905&quot;,
  &quot;DiffScore&quot;: 30,
  &quot;DifficultyLevel&quot;: 6,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 24,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 7,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/906.png" alt="906"><span><b>906</b><small>海鲜意面</small></span></span></td><td>60</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;906&quot;,
  &quot;DiffScore&quot;: 60,
  &quot;DifficultyLevel&quot;: 7,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 36,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 10,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/907.png" alt="907"><span><b>907</b><small>新鲜牡蛎</small></span></span></td><td>120</td><td>15</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;907&quot;,
  &quot;DiffScore&quot;: 120,
  &quot;DifficultyLevel&quot;: 8,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 56,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 15,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/908.png" alt="908"><span><b>908</b><small>水煮全蟹</small></span></span></td><td>239</td><td>21</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;908&quot;,
  &quot;DiffScore&quot;: 239,
  &quot;DifficultyLevel&quot;: 9,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 88,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 10,
  &quot;UnlockLevel&quot;: 21,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/909.png" alt="909"><span><b>909</b><small>龙虾大餐</small></span></span></td><td>479</td><td>26</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;909&quot;,
  &quot;DiffScore&quot;: 479,
  &quot;DifficultyLevel&quot;: 10,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 132,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 50,
  &quot;UnlockLevel&quot;: 26,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/910.png" alt="910"><span><b>910</b><small>大海鲜塔</small></span></span></td><td>957</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;910&quot;,
  &quot;DiffScore&quot;: 957,
  &quot;DifficultyLevel&quot;: 11,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 202,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RecommendedNumber&quot;: 1,
  &quot;RecommendedPrice&quot;: 202,
  &quot;RepeatWeightDecrease&quot;: 100,
  &quot;UnlockLevel&quot;: 31,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1102.png" alt="1102"><span><b>1102</b><small>橙子片</small></span></span></td><td>4</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1102&quot;,
  &quot;DiffScore&quot;: 4,
  &quot;ForbiddenSlot&quot;: [
    11,
    18
  ],
  &quot;Price&quot;: 4,
  &quot;UnlockLevel&quot;: 9,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1103.png" alt="1103"><span><b>1103</b><small>橘子味饼干</small></span></span></td><td>9</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1103&quot;,
  &quot;DiffScore&quot;: 9,
  &quot;ForbiddenSlot&quot;: [
    11,
    18
  ],
  &quot;Price&quot;: 8,
  &quot;UnlockLevel&quot;: 9,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1104.png" alt="1104"><span><b>1104</b><small>橙色纸杯蛋糕</small></span></span></td><td>18</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1104&quot;,
  &quot;DiffScore&quot;: 18,
  &quot;ForbiddenSlot&quot;: [
    11,
    18
  ],
  &quot;Price&quot;: 14,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 9,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1105.png" alt="1105"><span><b>1105</b><small>令人惬意的橘子蛋糕</small></span></span></td><td>35</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1105&quot;,
  &quot;DiffScore&quot;: 35,
  &quot;ForbiddenSlot&quot;: [
    10,
    11,
    18
  ],
  &quot;Price&quot;: 24,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 10,
  &quot;UnlockLevel&quot;: 9,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1106.png" alt="1106"><span><b>1106</b><small>橙色梦幻蛋糕</small></span></span></td><td>70</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1106&quot;,
  &quot;DiffScore&quot;: 70,
  &quot;ForbiddenSlot&quot;: [
    10,
    11,
    18
  ],
  &quot;Price&quot;: 36,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 50,
  &quot;UnlockLevel&quot;: 9,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1107.png" alt="1107"><span><b>1107</b><small>豪华梦幻蛋糕</small></span></span></td><td>140</td><td>25</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1107&quot;,
  &quot;DiffScore&quot;: 140,
  &quot;ForbiddenSlot&quot;: [
    10,
    11,
    18
  ],
  &quot;Price&quot;: 54,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RecommendedNumber&quot;: 2,
  &quot;RecommendedPrice&quot;: 42,
  &quot;RepeatWeightDecrease&quot;: 100,
  &quot;UnlockLevel&quot;: 25,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span></td><td>3</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1303&quot;,
  &quot;DiffScore&quot;: 3,
  &quot;Price&quot;: 8,
  &quot;UnlockLevel&quot;: 9,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span></td><td>6</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1304&quot;,
  &quot;DiffScore&quot;: 6,
  &quot;Price&quot;: 14,
  &quot;UnlockLevel&quot;: 9,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span></td><td>13</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1305&quot;,
  &quot;DiffScore&quot;: 13,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 24,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 9,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span></td><td>26</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1306&quot;,
  &quot;DiffScore&quot;: 26,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 36,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 9,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1307.png" alt="1307"><span><b>1307</b><small>鸭子漂浮圈</small></span></span></td><td>52</td><td>18</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1307&quot;,
  &quot;DiffScore&quot;: 52,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 56,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 18,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1308.png" alt="1308"><span><b>1308</b><small>独角兽漂浮圈</small></span></span></td><td>88</td><td>21</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1308&quot;,
  &quot;DiffScore&quot;: 88,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 88,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 21,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1309.png" alt="1309"><span><b>1309</b><small>火烈鸟漂浮圈</small></span></span></td><td>176</td><td>26</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1309&quot;,
  &quot;DiffScore&quot;: 176,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 132,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 10,
  &quot;UnlockLevel&quot;: 26,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1310.png" alt="1310"><span><b>1310</b><small>皇家孔雀漂浮圈</small></span></span></td><td>352</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1310&quot;,
  &quot;DiffScore&quot;: 352,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 202,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 50,
  &quot;UnlockLevel&quot;: 31,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1311.png" alt="1311"><span><b>1311</b><small>恐龙漂浮圈</small></span></span></td><td>704</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1311&quot;,
  &quot;DiffScore&quot;: 704,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 318,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RecommendedNumber&quot;: 1,
  &quot;RecommendedPrice&quot;: 318,
  &quot;RepeatWeightDecrease&quot;: 100,
  &quot;UnlockLevel&quot;: 31,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span></td><td>12</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1403&quot;,
  &quot;DiffScore&quot;: 12,
  &quot;DifficultyLevel&quot;: 4,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 12,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 9,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span></td><td>24</td><td>15</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1404&quot;,
  &quot;DiffScore&quot;: 24,
  &quot;DifficultyLevel&quot;: 5,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 22,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 15,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td>48</td><td>21</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1405&quot;,
  &quot;DiffScore&quot;: 48,
  &quot;DifficultyLevel&quot;: 6,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 34,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 10,
  &quot;UnlockLevel&quot;: 21,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1406.png" alt="1406"><span><b>1406</b><small>微型氧气罐</small></span></span></td><td>97</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1406&quot;,
  &quot;DiffScore&quot;: 97,
  &quot;DifficultyLevel&quot;: 7,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 54,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 50,
  &quot;UnlockLevel&quot;: 31,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1407.png" alt="1407"><span><b>1407</b><small>潜水探险舱</small></span></span></td><td>194</td><td>41</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1407&quot;,
  &quot;DiffScore&quot;: 194,
  &quot;DifficultyLevel&quot;: 8,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 86,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RecommendedNumber&quot;: 1,
  &quot;RecommendedPrice&quot;: 86,
  &quot;RepeatWeightDecrease&quot;: 100,
  &quot;UnlockLevel&quot;: 41,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span></td><td>3</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1803&quot;,
  &quot;DiffScore&quot;: 3,
  &quot;Price&quot;: 8,
  &quot;UnlockLevel&quot;: 10,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span></td><td>7</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1804&quot;,
  &quot;DiffScore&quot;: 7,
  &quot;Price&quot;: 14,
  &quot;UnlockLevel&quot;: 10,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span></td><td>13</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1805&quot;,
  &quot;DiffScore&quot;: 13,
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;Price&quot;: 24,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 10,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span></td><td>27</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1806&quot;,
  &quot;DiffScore&quot;: 27,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 36,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 10,
  &quot;Weight&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1807.png" alt="1807"><span><b>1807</b><small>喇叭海螺</small></span></span></td><td>58</td><td>21</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1807&quot;,
  &quot;DiffScore&quot;: 58,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 56,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 21,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1808.png" alt="1808"><span><b>1808</b><small>神奇海螺</small></span></span></td><td>91</td><td>26</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1808&quot;,
  &quot;DiffScore&quot;: 91,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 88,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 26,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1809.png" alt="1809"><span><b>1809</b><small>装甲外壳</small></span></span></td><td>183</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1809&quot;,
  &quot;DiffScore&quot;: 183,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 132,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 10,
  &quot;UnlockLevel&quot;: 31,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1810.png" alt="1810"><span><b>1810</b><small>伪装海螺</small></span></span></td><td>366</td><td>36</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1810&quot;,
  &quot;DiffScore&quot;: 366,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 202,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 50,
  &quot;UnlockLevel&quot;: 36,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1811.png" alt="1811"><span><b>1811</b><small>封闭式蛤蜊</small></span></span></td><td>731</td><td>41</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1811&quot;,
  &quot;DiffScore&quot;: 731,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 304,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RepeatWeightDecrease&quot;: 100,
  &quot;UnlockLevel&quot;: 41,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1812.png" alt="1812"><span><b>1812</b><small>珍珠贝</small></span></span></td><td>1463</td><td>41</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;Code&quot;: &quot;1812&quot;,
  &quot;DiffScore&quot;: 1463,
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;Price&quot;: 458,
  &quot;ProgressUnlock&quot;: 1,
  &quot;RecommendedNumber&quot;: 1,
  &quot;RecommendedPrice&quot;: 458,
  &quot;UnlockLevel&quot;: 41,
  &quot;Weight&quot;: 100,
  &quot;WeightMultiple&quot;: 1
}</pre></details></td></tr></tbody></table></div></div>


`OrderItemConfig_shell`：共 80 条，新增/不同记录 16 条；相同记录见默认表。移除代码：无。


### OrderItemConfig_shell 的新增/不同记录（16 条）

来源：`Data.Config.OrderItemConfig_shell`。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 16 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>产物 ID<small style="display:block">Code</small></th><th>产物难度分<small style="display:block">DiffScore</small></th><th>解锁等级<small style="display:block">UnlockLevel</small></th><th>订单权重<small style="display:block">Weight</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span></td><td>3</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;DiffScore&quot;: 3,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 10,
  &quot;Code&quot;: &quot;1803&quot;,
  &quot;Price&quot;: 7
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span></td><td>6</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;DiffScore&quot;: 6,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 10,
  &quot;Code&quot;: &quot;1804&quot;,
  &quot;Price&quot;: 13
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span></td><td>11</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;DiffScore&quot;: 11,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 10,
  &quot;Code&quot;: &quot;1805&quot;,
  &quot;Price&quot;: 21
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span></td><td>22</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;DiffScore&quot;: 22,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 10,
  &quot;Code&quot;: &quot;1806&quot;,
  &quot;Price&quot;: 32
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1807.png" alt="1807"><span><b>1807</b><small>喇叭海螺</small></span></span></td><td>43</td><td>21</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;DiffScore&quot;: 43,
  &quot;ProgressUnlock&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 21,
  &quot;Code&quot;: &quot;1807&quot;,
  &quot;Price&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1808.png" alt="1808"><span><b>1808</b><small>神奇海螺</small></span></span></td><td>86</td><td>26</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;DiffScore&quot;: 86,
  &quot;ProgressUnlock&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 26,
  &quot;Code&quot;: &quot;1808&quot;,
  &quot;Price&quot;: 79
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1809.png" alt="1809"><span><b>1809</b><small>装甲外壳</small></span></span></td><td>171</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 31,
  &quot;Price&quot;: 118,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 171,
  &quot;Code&quot;: &quot;1809&quot;,
  &quot;RepeatWeightDecrease&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1810.png" alt="1810"><span><b>1810</b><small>伪装海螺</small></span></span></td><td>341</td><td>36</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 36,
  &quot;Price&quot;: 180,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 341,
  &quot;Code&quot;: &quot;1810&quot;,
  &quot;RepeatWeightDecrease&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1811.png" alt="1811"><span><b>1811</b><small>封闭式蛤蜊</small></span></span></td><td>682</td><td>41</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 41,
  &quot;Price&quot;: 271,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 682,
  &quot;Code&quot;: &quot;1811&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1812.png" alt="1812"><span><b>1812</b><small>珍珠贝</small></span></span></td><td>1364</td><td>41</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;RecommendedPrice&quot;: 409,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 41,
  &quot;Price&quot;: 409,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;Code&quot;: &quot;1812&quot;,
  &quot;DiffScore&quot;: 1364
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_g_artifact_3</b><small>无本地视图映射</small></span></span></td><td>11</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;UnlockLevel&quot;: 9,
  &quot;DiffScore&quot;: 11,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 4,
  &quot;Code&quot;: &quot;main_g_artifact_3&quot;,
  &quot;Price&quot;: 13
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_g_artifact_4</b><small>无本地视图映射</small></span></span></td><td>22</td><td>15</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;UnlockLevel&quot;: 15,
  &quot;DiffScore&quot;: 22,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 5,
  &quot;Code&quot;: &quot;main_g_artifact_4&quot;,
  &quot;Price&quot;: 21
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_g_artifact_5</b><small>无本地视图映射</small></span></span></td><td>43</td><td>21</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 21,
  &quot;Price&quot;: 32,
  &quot;DiffScore&quot;: 43,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 6,
  &quot;Code&quot;: &quot;main_g_artifact_5&quot;,
  &quot;RepeatWeightDecrease&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_g_artifact_6</b><small>无本地视图映射</small></span></span></td><td>86</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 31,
  &quot;Price&quot;: 50,
  &quot;DiffScore&quot;: 86,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 7,
  &quot;Code&quot;: &quot;main_g_artifact_6&quot;,
  &quot;RepeatWeightDecrease&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_g_artifact_7</b><small>无本地视图映射</small></span></span></td><td>171</td><td>41</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 41,
  &quot;Price&quot;: 79,
  &quot;DiffScore&quot;: 171,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 8,
  &quot;Code&quot;: &quot;main_g_artifact_7&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><span><b>main_g_artifact_8</b><small>无本地视图映射</small></span></span></td><td>341</td><td>51</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;RecommendedPrice&quot;: 118,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 51,
  &quot;Price&quot;: 118,
  &quot;RecommendedNumber&quot;: 2,
  &quot;DiffScore&quot;: 341,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 9,
  &quot;Code&quot;: &quot;main_g_artifact_8&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr></tbody></table></div></div>


`OrderItemConfig_hard`：共 74 条，新增/不同记录 21 条；相同记录见默认表。移除代码：无。


### OrderItemConfig_hard 的新增/不同记录（21 条）

来源：`Data.Config.OrderItemConfig_hard`。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 21 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>产物 ID<small style="display:block">Code</small></th><th>产物难度分<small style="display:block">DiffScore</small></th><th>解锁等级<small style="display:block">UnlockLevel</small></th><th>订单权重<small style="display:block">Weight</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/306.png" alt="306"><span><b>306</b><small>薯条鸡块组合</small></span></span></td><td>92</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 10,
  &quot;Price&quot;: 38,
  &quot;DiffScore&quot;: 92,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 7,
  &quot;Code&quot;: &quot;306&quot;,
  &quot;RepeatWeightDecrease&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/307.png" alt="307"><span><b>307</b><small>全家桶</small></span></span></td><td>184</td><td>16</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;RecommendedPrice&quot;: 58,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 16,
  &quot;Price&quot;: 58,
  &quot;RecommendedNumber&quot;: 2,
  &quot;DiffScore&quot;: 184,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 8,
  &quot;Code&quot;: &quot;307&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/606.png" alt="606"><span><b>606</b><small>高雅茶壶</small></span></span></td><td>110</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 10,
  &quot;Price&quot;: 41,
  &quot;DiffScore&quot;: 110,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 7,
  &quot;Code&quot;: &quot;606&quot;,
  &quot;RepeatWeightDecrease&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/607.png" alt="607"><span><b>607</b><small>精致茶饮</small></span></span></td><td>220</td><td>16</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;RecommendedPrice&quot;: 62,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 16,
  &quot;Price&quot;: 62,
  &quot;RecommendedNumber&quot;: 2,
  &quot;DiffScore&quot;: 220,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 8,
  &quot;Code&quot;: &quot;607&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/908.png" alt="908"><span><b>908</b><small>水煮全蟹</small></span></span></td><td>239</td><td>15</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 15,
  &quot;Price&quot;: 88,
  &quot;DiffScore&quot;: 239,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 9,
  &quot;Code&quot;: &quot;908&quot;,
  &quot;RepeatWeightDecrease&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/909.png" alt="909"><span><b>909</b><small>龙虾大餐</small></span></span></td><td>479</td><td>15</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 15,
  &quot;Price&quot;: 132,
  &quot;DiffScore&quot;: 479,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 10,
  &quot;Code&quot;: &quot;909&quot;,
  &quot;RepeatWeightDecrease&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/910.png" alt="910"><span><b>910</b><small>大海鲜塔</small></span></span></td><td>957</td><td>15</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;RecommendedPrice&quot;: 202,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 15,
  &quot;Price&quot;: 202,
  &quot;RecommendedNumber&quot;: 1,
  &quot;DiffScore&quot;: 957,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 11,
  &quot;Code&quot;: &quot;910&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1105.png" alt="1105"><span><b>1105</b><small>令人惬意的橘子蛋糕</small></span></span></td><td>35</td><td>15</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11,
    18
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 15,
  &quot;Price&quot;: 24,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 35,
  &quot;Code&quot;: &quot;1105&quot;,
  &quot;RepeatWeightDecrease&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1106.png" alt="1106"><span><b>1106</b><small>橙色梦幻蛋糕</small></span></span></td><td>70</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11,
    18
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 31,
  &quot;Price&quot;: 36,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 70,
  &quot;Code&quot;: &quot;1106&quot;,
  &quot;RepeatWeightDecrease&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1107.png" alt="1107"><span><b>1107</b><small>豪华梦幻蛋糕</small></span></span></td><td>140</td><td>41</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11,
    18
  ],
  &quot;RecommendedPrice&quot;: 42,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 41,
  &quot;Price&quot;: 54,
  &quot;RecommendedNumber&quot;: 2,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 140,
  &quot;Code&quot;: &quot;1107&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1307.png" alt="1307"><span><b>1307</b><small>鸭子漂浮圈</small></span></span></td><td>52</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;DiffScore&quot;: 52,
  &quot;ProgressUnlock&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 9,
  &quot;Code&quot;: &quot;1307&quot;,
  &quot;Price&quot;: 56
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1308.png" alt="1308"><span><b>1308</b><small>独角兽漂浮圈</small></span></span></td><td>88</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;DiffScore&quot;: 88,
  &quot;ProgressUnlock&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 9,
  &quot;Code&quot;: &quot;1308&quot;,
  &quot;Price&quot;: 88
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1309.png" alt="1309"><span><b>1309</b><small>火烈鸟漂浮圈</small></span></span></td><td>176</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 9,
  &quot;Price&quot;: 132,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 176,
  &quot;Code&quot;: &quot;1309&quot;,
  &quot;RepeatWeightDecrease&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1310.png" alt="1310"><span><b>1310</b><small>皇家孔雀漂浮圈</small></span></span></td><td>352</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 9,
  &quot;Price&quot;: 202,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 352,
  &quot;Code&quot;: &quot;1310&quot;,
  &quot;RepeatWeightDecrease&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1311.png" alt="1311"><span><b>1311</b><small>恐龙漂浮圈</small></span></span></td><td>704</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;RecommendedPrice&quot;: 318,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 9,
  &quot;Price&quot;: 318,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 704,
  &quot;Code&quot;: &quot;1311&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1807.png" alt="1807"><span><b>1807</b><small>喇叭海螺</small></span></span></td><td>58</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;DiffScore&quot;: 58,
  &quot;ProgressUnlock&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 10,
  &quot;Code&quot;: &quot;1807&quot;,
  &quot;Price&quot;: 56
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1808.png" alt="1808"><span><b>1808</b><small>神奇海螺</small></span></span></td><td>91</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;DiffScore&quot;: 91,
  &quot;ProgressUnlock&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 10,
  &quot;Code&quot;: &quot;1808&quot;,
  &quot;Price&quot;: 88
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1809.png" alt="1809"><span><b>1809</b><small>装甲外壳</small></span></span></td><td>183</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 10,
  &quot;Price&quot;: 132,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 183,
  &quot;Code&quot;: &quot;1809&quot;,
  &quot;RepeatWeightDecrease&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1810.png" alt="1810"><span><b>1810</b><small>伪装海螺</small></span></span></td><td>366</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 10,
  &quot;Price&quot;: 202,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 366,
  &quot;Code&quot;: &quot;1810&quot;,
  &quot;RepeatWeightDecrease&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1811.png" alt="1811"><span><b>1811</b><small>封闭式蛤蜊</small></span></span></td><td>731</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 10,
  &quot;Price&quot;: 304,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 731,
  &quot;Code&quot;: &quot;1811&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1812.png" alt="1812"><span><b>1812</b><small>珍珠贝</small></span></span></td><td>1463</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;RecommendedPrice&quot;: 458,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 10,
  &quot;Price&quot;: 458,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;Code&quot;: &quot;1812&quot;,
  &quot;DiffScore&quot;: 1463
}</pre></details></td></tr></tbody></table></div></div>


`OrderItemConfig_nerf`：共 74 条，新增/不同记录 24 条；相同记录见默认表。移除代码：无。


### OrderItemConfig_nerf 的新增/不同记录（24 条）

来源：`Data.Config.OrderItemConfig_nerf`。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 24 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>产物 ID<small style="display:block">Code</small></th><th>产物难度分<small style="display:block">DiffScore</small></th><th>解锁等级<small style="display:block">UnlockLevel</small></th><th>订单权重<small style="display:block">Weight</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span></td><td>3</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;DiffScore&quot;: 3,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 9,
  &quot;Code&quot;: &quot;1303&quot;,
  &quot;Price&quot;: 7
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span></td><td>6</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;DiffScore&quot;: 6,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 9,
  &quot;Code&quot;: &quot;1304&quot;,
  &quot;Price&quot;: 12
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span></td><td>13</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;DiffScore&quot;: 13,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 9,
  &quot;Code&quot;: &quot;1305&quot;,
  &quot;Price&quot;: 20
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span></td><td>26</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;DiffScore&quot;: 26,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 9,
  &quot;Code&quot;: &quot;1306&quot;,
  &quot;Price&quot;: 30
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1307.png" alt="1307"><span><b>1307</b><small>鸭子漂浮圈</small></span></span></td><td>52</td><td>18</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;DiffScore&quot;: 52,
  &quot;ProgressUnlock&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 18,
  &quot;Code&quot;: &quot;1307&quot;,
  &quot;Price&quot;: 47
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1308.png" alt="1308"><span><b>1308</b><small>独角兽漂浮圈</small></span></span></td><td>88</td><td>21</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;DiffScore&quot;: 88,
  &quot;ProgressUnlock&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 21,
  &quot;Code&quot;: &quot;1308&quot;,
  &quot;Price&quot;: 73
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1309.png" alt="1309"><span><b>1309</b><small>火烈鸟漂浮圈</small></span></span></td><td>176</td><td>26</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 26,
  &quot;Price&quot;: 110,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 176,
  &quot;Code&quot;: &quot;1309&quot;,
  &quot;RepeatWeightDecrease&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1310.png" alt="1310"><span><b>1310</b><small>皇家孔雀漂浮圈</small></span></span></td><td>352</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 31,
  &quot;Price&quot;: 168,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 352,
  &quot;Code&quot;: &quot;1310&quot;,
  &quot;RepeatWeightDecrease&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1311.png" alt="1311"><span><b>1311</b><small>恐龙漂浮圈</small></span></span></td><td>704</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;RecommendedPrice&quot;: 318,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 31,
  &quot;Price&quot;: 265,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 704,
  &quot;Code&quot;: &quot;1311&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span></td><td>12</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;UnlockLevel&quot;: 9,
  &quot;ProgressUnlock&quot;: 1,
  &quot;DiffScore&quot;: 12,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 4,
  &quot;Code&quot;: &quot;1403&quot;,
  &quot;Price&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span></td><td>24</td><td>15</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 15,
  &quot;Price&quot;: 18,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 5,
  &quot;Code&quot;: &quot;1404&quot;,
  &quot;DiffScore&quot;: 24
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td>48</td><td>21</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 21,
  &quot;Price&quot;: 28,
  &quot;DiffScore&quot;: 48,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 6,
  &quot;Code&quot;: &quot;1405&quot;,
  &quot;RepeatWeightDecrease&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1406.png" alt="1406"><span><b>1406</b><small>微型氧气罐</small></span></span></td><td>97</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 31,
  &quot;Price&quot;: 45,
  &quot;DiffScore&quot;: 97,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 7,
  &quot;Code&quot;: &quot;1406&quot;,
  &quot;RepeatWeightDecrease&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1407.png" alt="1407"><span><b>1407</b><small>潜水探险舱</small></span></span></td><td>194</td><td>41</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;RecommendedPrice&quot;: 86,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 41,
  &quot;Price&quot;: 72,
  &quot;RecommendedNumber&quot;: 1,
  &quot;DiffScore&quot;: 194,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 8,
  &quot;Code&quot;: &quot;1407&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span></td><td>3</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;DiffScore&quot;: 3,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 10,
  &quot;Code&quot;: &quot;1803&quot;,
  &quot;Price&quot;: 7
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span></td><td>7</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;DiffScore&quot;: 7,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 10,
  &quot;Code&quot;: &quot;1804&quot;,
  &quot;Price&quot;: 12
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span></td><td>13</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;DiffScore&quot;: 13,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 10,
  &quot;Code&quot;: &quot;1805&quot;,
  &quot;Price&quot;: 20
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span></td><td>27</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;DiffScore&quot;: 27,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 10,
  &quot;Code&quot;: &quot;1806&quot;,
  &quot;Price&quot;: 30
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1807.png" alt="1807"><span><b>1807</b><small>喇叭海螺</small></span></span></td><td>58</td><td>21</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;DiffScore&quot;: 58,
  &quot;ProgressUnlock&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 21,
  &quot;Code&quot;: &quot;1807&quot;,
  &quot;Price&quot;: 47
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1808.png" alt="1808"><span><b>1808</b><small>神奇海螺</small></span></span></td><td>91</td><td>26</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;DiffScore&quot;: 91,
  &quot;ProgressUnlock&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 26,
  &quot;Code&quot;: &quot;1808&quot;,
  &quot;Price&quot;: 73
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1809.png" alt="1809"><span><b>1809</b><small>装甲外壳</small></span></span></td><td>183</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 31,
  &quot;Price&quot;: 110,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 183,
  &quot;Code&quot;: &quot;1809&quot;,
  &quot;RepeatWeightDecrease&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1810.png" alt="1810"><span><b>1810</b><small>伪装海螺</small></span></span></td><td>366</td><td>36</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 36,
  &quot;Price&quot;: 168,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 366,
  &quot;Code&quot;: &quot;1810&quot;,
  &quot;RepeatWeightDecrease&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1811.png" alt="1811"><span><b>1811</b><small>封闭式蛤蜊</small></span></span></td><td>731</td><td>41</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 41,
  &quot;Price&quot;: 253,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 731,
  &quot;Code&quot;: &quot;1811&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1812.png" alt="1812"><span><b>1812</b><small>珍珠贝</small></span></span></td><td>1463</td><td>41</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;RecommendedPrice&quot;: 458,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 41,
  &quot;Price&quot;: 382,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;Code&quot;: &quot;1812&quot;,
  &quot;DiffScore&quot;: 1463
}</pre></details></td></tr></tbody></table></div></div>


`OrderItemConfig_nerf_more`：共 74 条，新增/不同记录 24 条；相同记录见默认表。移除代码：无。


### OrderItemConfig_nerf_more 的新增/不同记录（24 条）

来源：`Data.Config.OrderItemConfig_nerf_more`。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 24 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>产物 ID<small style="display:block">Code</small></th><th>产物难度分<small style="display:block">DiffScore</small></th><th>解锁等级<small style="display:block">UnlockLevel</small></th><th>订单权重<small style="display:block">Weight</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1303.png" alt="1303"><span><b>1303</b><small>救生圈</small></span></span></td><td>3</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;DiffScore&quot;: 3,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 9,
  &quot;Code&quot;: &quot;1303&quot;,
  &quot;Price&quot;: 6
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1304.png" alt="1304"><span><b>1304</b><small>粉红果冻游泳圈</small></span></span></td><td>6</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;DiffScore&quot;: 6,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 9,
  &quot;Code&quot;: &quot;1304&quot;,
  &quot;Price&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1305.png" alt="1305"><span><b>1305</b><small>璀璨泳圈</small></span></span></td><td>13</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;DiffScore&quot;: 13,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 9,
  &quot;Code&quot;: &quot;1305&quot;,
  &quot;Price&quot;: 17
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1306.png" alt="1306"><span><b>1306</b><small>美人鱼漂浮圈</small></span></span></td><td>26</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;DiffScore&quot;: 26,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 9,
  &quot;Code&quot;: &quot;1306&quot;,
  &quot;Price&quot;: 26
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1307.png" alt="1307"><span><b>1307</b><small>鸭子漂浮圈</small></span></span></td><td>52</td><td>18</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;DiffScore&quot;: 52,
  &quot;ProgressUnlock&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 18,
  &quot;Code&quot;: &quot;1307&quot;,
  &quot;Price&quot;: 40
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1308.png" alt="1308"><span><b>1308</b><small>独角兽漂浮圈</small></span></span></td><td>88</td><td>21</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;DiffScore&quot;: 88,
  &quot;ProgressUnlock&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 21,
  &quot;Code&quot;: &quot;1308&quot;,
  &quot;Price&quot;: 63
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1309.png" alt="1309"><span><b>1309</b><small>火烈鸟漂浮圈</small></span></span></td><td>176</td><td>26</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 26,
  &quot;Price&quot;: 94,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 176,
  &quot;Code&quot;: &quot;1309&quot;,
  &quot;RepeatWeightDecrease&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1310.png" alt="1310"><span><b>1310</b><small>皇家孔雀漂浮圈</small></span></span></td><td>352</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 31,
  &quot;Price&quot;: 144,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 352,
  &quot;Code&quot;: &quot;1310&quot;,
  &quot;RepeatWeightDecrease&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1311.png" alt="1311"><span><b>1311</b><small>恐龙漂浮圈</small></span></span></td><td>704</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;RecommendedPrice&quot;: 318,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 31,
  &quot;Price&quot;: 227,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 704,
  &quot;Code&quot;: &quot;1311&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1403.png" alt="1403"><span><b>1403</b><small>基础救生衣</small></span></span></td><td>12</td><td>9</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;UnlockLevel&quot;: 9,
  &quot;ProgressUnlock&quot;: 1,
  &quot;DiffScore&quot;: 12,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 4,
  &quot;Code&quot;: &quot;1403&quot;,
  &quot;Price&quot;: 9
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1404.png" alt="1404"><span><b>1404</b><small>潜水手套</small></span></span></td><td>24</td><td>15</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 15,
  &quot;Price&quot;: 16,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 5,
  &quot;Code&quot;: &quot;1404&quot;,
  &quot;DiffScore&quot;: 24
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1405.png" alt="1405"><span><b>1405</b><small>潜水脚蹼</small></span></span></td><td>48</td><td>21</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 21,
  &quot;Price&quot;: 24,
  &quot;DiffScore&quot;: 48,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 6,
  &quot;Code&quot;: &quot;1405&quot;,
  &quot;RepeatWeightDecrease&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1406.png" alt="1406"><span><b>1406</b><small>微型氧气罐</small></span></span></td><td>97</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 31,
  &quot;Price&quot;: 39,
  &quot;DiffScore&quot;: 97,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 7,
  &quot;Code&quot;: &quot;1406&quot;,
  &quot;RepeatWeightDecrease&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1407.png" alt="1407"><span><b>1407</b><small>潜水探险舱</small></span></span></td><td>194</td><td>41</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;RecommendedPrice&quot;: 86,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 41,
  &quot;Price&quot;: 61,
  &quot;RecommendedNumber&quot;: 1,
  &quot;DiffScore&quot;: 194,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 8,
  &quot;Code&quot;: &quot;1407&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1803.png" alt="1803"><span><b>1803</b><small>新鲜扇贝</small></span></span></td><td>3</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;DiffScore&quot;: 3,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 10,
  &quot;Code&quot;: &quot;1803&quot;,
  &quot;Price&quot;: 6
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1804.png" alt="1804"><span><b>1804</b><small>点状贝壳</small></span></span></td><td>7</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;DiffScore&quot;: 7,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 10,
  &quot;Code&quot;: &quot;1804&quot;,
  &quot;Price&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1805.png" alt="1805"><span><b>1805</b><small>金色海螺</small></span></span></td><td>13</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;DiffScore&quot;: 13,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 10,
  &quot;Code&quot;: &quot;1805&quot;,
  &quot;Price&quot;: 17
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1806.png" alt="1806"><span><b>1806</b><small>稀有鹦鹉螺</small></span></span></td><td>27</td><td>10</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;DiffScore&quot;: 27,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 10,
  &quot;Code&quot;: &quot;1806&quot;,
  &quot;Price&quot;: 26
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1807.png" alt="1807"><span><b>1807</b><small>喇叭海螺</small></span></span></td><td>58</td><td>21</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;DiffScore&quot;: 58,
  &quot;ProgressUnlock&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 21,
  &quot;Code&quot;: &quot;1807&quot;,
  &quot;Price&quot;: 40
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1808.png" alt="1808"><span><b>1808</b><small>神奇海螺</small></span></span></td><td>91</td><td>26</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;DiffScore&quot;: 91,
  &quot;ProgressUnlock&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;UnlockLevel&quot;: 26,
  &quot;Code&quot;: &quot;1808&quot;,
  &quot;Price&quot;: 63
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1809.png" alt="1809"><span><b>1809</b><small>装甲外壳</small></span></span></td><td>183</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 31,
  &quot;Price&quot;: 94,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 183,
  &quot;Code&quot;: &quot;1809&quot;,
  &quot;RepeatWeightDecrease&quot;: 10
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1810.png" alt="1810"><span><b>1810</b><small>伪装海螺</small></span></span></td><td>366</td><td>36</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 36,
  &quot;Price&quot;: 144,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 366,
  &quot;Code&quot;: &quot;1810&quot;,
  &quot;RepeatWeightDecrease&quot;: 50
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1811.png" alt="1811"><span><b>1811</b><small>封闭式蛤蜊</small></span></span></td><td>731</td><td>41</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 41,
  &quot;Price&quot;: 217,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 731,
  &quot;Code&quot;: &quot;1811&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1812.png" alt="1812"><span><b>1812</b><small>珍珠贝</small></span></span></td><td>1463</td><td>41</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;RecommendedPrice&quot;: 458,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 41,
  &quot;Price&quot;: 327,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;Code&quot;: &quot;1812&quot;,
  &quot;DiffScore&quot;: 1463
}</pre></details></td></tr></tbody></table></div></div>


`OrderItemConfig_extracust`：共 76 条，新增/不同记录 11 条；相同记录见默认表。移除代码：无。


### OrderItemConfig_extracust 的新增/不同记录（11 条）

来源：`Data.Config.OrderItemConfig_extracust`。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 11 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>产物 ID<small style="display:block">Code</small></th><th>产物难度分<small style="display:block">DiffScore</small></th><th>解锁等级<small style="display:block">UnlockLevel</small></th><th>订单权重<small style="display:block">Weight</small></th><th>完整记录</th></tr></thead><tbody><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/212.png" alt="212"><span><b>212</b><small>火腿奶酪羊角面包</small></span></span></td><td>878</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;RecommendedPrice&quot;: 178,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 1,
  &quot;Price&quot;: 178,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;Code&quot;: &quot;212&quot;,
  &quot;DiffScore&quot;: 878
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/213.png" alt="213"><span><b>213</b><small>粘稠的芝士汉堡</small></span></span></td><td>1317</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;RecommendedPrice&quot;: 270,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 1,
  &quot;Price&quot;: 270,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;Code&quot;: &quot;213&quot;,
  &quot;DiffScore&quot;: 1317
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/214.png" alt="214"><span><b>214</b><small>芝士汉堡和薯条</small></span></span></td><td>1976</td><td>1</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;RecommendedPrice&quot;: 406,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 1,
  &quot;Price&quot;: 406,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;Code&quot;: &quot;214&quot;,
  &quot;DiffScore&quot;: 1976
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/512.png" alt="512"><span><b>512</b><small>蜜饯浆果咖啡</small></span></span></td><td>926</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;RecommendedPrice&quot;: 202,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 3,
  &quot;Price&quot;: 202,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;Code&quot;: &quot;512&quot;,
  &quot;DiffScore&quot;: 926
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/513.png" alt="513"><span><b>513</b><small>咖啡甜点</small></span></span></td><td>1389</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;RecommendedPrice&quot;: 304,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 3,
  &quot;Price&quot;: 304,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;Code&quot;: &quot;513&quot;,
  &quot;DiffScore&quot;: 1389
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/514.png" alt="514"><span><b>514</b><small>甜茶派对</small></span></span></td><td>2084</td><td>3</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10
  ],
  &quot;RecommendedPrice&quot;: 458,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 3,
  &quot;Price&quot;: 458,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;Code&quot;: &quot;514&quot;,
  &quot;DiffScore&quot;: 2084
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/910.png" alt="910"><span><b>910</b><small>大海鲜塔</small></span></span></td><td>957</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 31,
  &quot;Price&quot;: 202,
  &quot;DiffScore&quot;: 957,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 11,
  &quot;Code&quot;: &quot;910&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/911.png" alt="911"><span><b>911</b><small>Seafood11</small></span></span></td><td>1436</td><td>51</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;RecommendedPrice&quot;: 309,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 51,
  &quot;Price&quot;: 309,
  &quot;RecommendedNumber&quot;: 1,
  &quot;DiffScore&quot;: 1436,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DifficultyLevel&quot;: 12,
  &quot;Code&quot;: &quot;911&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1311.png" alt="1311"><span><b>1311</b><small>恐龙漂浮圈</small></span></span></td><td>704</td><td>31</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 31,
  &quot;Price&quot;: 318,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 704,
  &quot;Code&quot;: &quot;1311&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1312.png" alt="1312"><span><b>1312</b><small>SwimmingRing12</small></span></span></td><td>1056</td><td>51</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;RecommendedPrice&quot;: 501,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 51,
  &quot;Price&quot;: 501,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;DiffScore&quot;: 1056,
  &quot;Code&quot;: &quot;1312&quot;,
  &quot;RepeatWeightDecrease&quot;: 100
}</pre></details></td></tr><tr><td><span class="config-piece"><img loading="lazy" src="../../../../../assets/config-pieces/1812.png" alt="1812"><span><b>1812</b><small>珍珠贝</small></span></span></td><td>1097</td><td>41</td><td>100</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;ForbiddenSlot&quot;: [
    10,
    11
  ],
  &quot;RecommendedPrice&quot;: 458,
  &quot;ProgressUnlock&quot;: 1,
  &quot;UnlockLevel&quot;: 41,
  &quot;Price&quot;: 458,
  &quot;RecommendedNumber&quot;: 1,
  &quot;WeightMultiple&quot;: 1,
  &quot;Weight&quot;: 100,
  &quot;Code&quot;: &quot;1812&quot;,
  &quot;DiffScore&quot;: 1097
}</pre></details></td></tr></tbody></table></div></div>


## 本逻辑使用的配表在哪里

- [母体配置与包内变体](../../state/model/detail.md#configuration-item-model)：ItemSpread:Init(itemConfig) 读取 Spread_* 并写入实例字段；其它状态、恢复和扣费阶段使用这些字段。


<!-- generator-configs:end -->
