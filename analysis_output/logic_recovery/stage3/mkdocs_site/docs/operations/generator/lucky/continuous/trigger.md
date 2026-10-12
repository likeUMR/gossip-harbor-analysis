# 三连/二连触发判断

当前特殊模式配置存在时，先以 `Random(1,10000)` 判断三连；三连未命中才以同范围随机判断二连。三连写入最大连续次数 2，二连写入最大连续次数 1。

**配置**：`triple_lucky_chance`、`double_lucky_chance`。**源码**：`_Try2TriggerContiLuckyProduce`。两个判断不是并列独立同时执行，而是二连只在三连失败后执行。

---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例使用基础配置，没有断言本次触发二连或三连。

### 代入本页的值

基础 105 行确认的是 `lucky_chance` 和物品池；没有能量区间的实际配置快照，不能填写二连/三连概率。B 调用 `_Try2TriggerContiLuckyProduce("105")`，是否写入连续状态取决于实际配置。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

演示输入：等级 10、活动 Started、无既有连续资格、GeneratorBoost/Disco/Smart/教程强制/落点优化不生效；余额 10、次数 80、储备 240、有效空格 P、基础能量档。周期计数 60/1；A 机会抽样 60 且免费资格失败，普通抽样点 20；B 机会抽样 1、Lucky 抽样点 50。以上是静态规则演算，未采集真实账号回放。

本例没执行的机制会明确标为跳过；对照分支只为解释条件，不能冒充主路径。

</details>

<!-- generator-configs:start -->

<a id="configuration-continuous-lucky"></a>

## 本页涉及的配表：连续 Lucky 服务器字段

**实际读取链**：`_CalculateLuckyProduceConfigIndex 按 energy_cost.range_entry 选段；_Try2TriggerContiLuckyProduce 直接读取 triple_lucky_chance / double_lucky_chance。`

本组配表集中展示在本页；其它使用同一份已加载配置的页面提供查阅链接。包内值与服务器生效值分开标注。


### 本页服务器配置字段（3 条）

来源：`LuckyProduceModel:_LoadOtherServerConfig`。这些字段不是 LuckyProduceConfig_triple 的包内字段；当前材料只确认读取结构，不能填写账号实际阈值。

<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="搜索棋子 ID、名称或配置值"><span class="config-count">全部 3 条配置</span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>字段</th><th>用途</th><th>来源</th><th>本地值</th><th>完整记录</th></tr></thead><tbody><tr><td>energy_cost.range_entry</td><td>当前能量消耗区间 [下界,上界]，用于选段与生成阈值</td><td>活动服务器 luckyProduceConfig</td><td>未采集服务器生效配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;字段&quot;: &quot;energy_cost.range_entry&quot;,
  &quot;用途&quot;: &quot;当前能量消耗区间 [下界,上界]，用于选段与生成阈值&quot;,
  &quot;来源&quot;: &quot;活动服务器 luckyProduceConfig&quot;,
  &quot;本地值&quot;: &quot;未采集服务器生效配置&quot;
}</pre></details></td></tr><tr><td>triple_lucky_chance</td><td>三连阈值，与整数 1..10000 比较</td><td>活动服务器 luckyProduceConfig</td><td>未采集服务器生效配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;字段&quot;: &quot;triple_lucky_chance&quot;,
  &quot;用途&quot;: &quot;三连阈值，与整数 1..10000 比较&quot;,
  &quot;来源&quot;: &quot;活动服务器 luckyProduceConfig&quot;,
  &quot;本地值&quot;: &quot;未采集服务器生效配置&quot;
}</pre></details></td></tr><tr><td>double_lucky_chance</td><td>三连失败后比较二连阈值，与整数 1..10000 比较</td><td>活动服务器 luckyProduceConfig</td><td>未采集服务器生效配置</td><td><details><summary>展开全部字段</summary><pre>{
  &quot;字段&quot;: &quot;double_lucky_chance&quot;,
  &quot;用途&quot;: &quot;三连失败后比较二连阈值，与整数 1..10000 比较&quot;,
  &quot;来源&quot;: &quot;活动服务器 luckyProduceConfig&quot;,
  &quot;本地值&quot;: &quot;未采集服务器生效配置&quot;
}</pre></details></td></tr></tbody></table></div></div>


<!-- generator-configs:end -->

