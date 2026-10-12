# 三连/二连触发判断

当前特殊模式配置存在时，先以 `Random(1,10000)` 判断三连；三连未命中才以同范围随机判断二连。三连写入最大连续次数 2，二连写入最大连续次数 1。

**配置**：`triple_lucky_chance`、`double_lucky_chance`。**源码**：`_Try2TriggerContiLuckyProduce`。两个判断不是并列独立同时执行，而是二连只在三连失败后执行。
---

## 贯穿案例：点击食品袋 105

<div class="case-assets"><img src="../../../../../assets/cases/lucky_item_1.png" alt="Lucky 标记" class="case-icon" style="width:88px;height:88px;object-fit:contain;margin:0 12px 0 0;vertical-align:middle;"></div>

**目的**：制作食物，观察同一次点击怎样从前置检查进入当前页面所解释的分支。

**本页发生什么**：本例明确设定食品袋 105 已经产生 Lucky 物品，随后连续奖励检查命中三连或二连中的一个分支。系统因此保存连续资格；如果两种分支都未命中，玩家只保留本次 Lucky 物品，下一次点击重新进行普通机会判断。

### 代入本页的值

假设服务器配置为 `triple_lucky_chance=1000`、`double_lucky_chance=3000`（随机范围 1..10000）。B 调用 `_Try2TriggerContiLuckyProduce("105")`：先抽 `r3=800`，因为 `800<=1000`，命中三连，写入 `clpit="105"、clpmc=2、clpc=0、clpeet=1010`，随后不再判断二连。另一个独立二连例子假设三连抽到 `r3=4500`（失败）、二连抽到 `r2=1200`（`1200<=3000` 成功），写入 `clpmc=1`；若 `r2=4000`，两次都失败，不写连续状态。以上概率是为演示计算而假设的配置。

<details><summary>本案例共同前提</summary>

本地配表确认：105 的普通池 201-35 / 202-2 / 301-5；可用次数上限 80，储备上限 240，恢复时长 30 / 60 秒。视图表把 105 映射到 GroceryBag05，201/204 映射到 Flour01/Flour04。

共同演示输入：等级 10、活动 Started、余额 10、次数 80、储备 240、有效空格 P。每个页面会为本页机制单独假设触发条件，并给出完整结果；其它机制只有在需要隔离当前分支时才单独说明。所有新增配置和数值均为演示假设。

本页案例只把当前机制设为触发条件；其它机制若被隔离，会在该段中明确说明假设。

</details>

<!-- generator-configs:start -->

<a id="configuration-continuous-lucky"></a>

## 本页涉及的配表：连续 Lucky 服务器字段

**实际读取链**：`_CalculateLuckyProduceConfigIndex 按 energy_cost.range_entry 选段；_Try2TriggerContiLuckyProduce 直接读取 triple_lucky_chance / double_lucky_chance。`

本组配表集中展示在本页；其它使用同一份已加载配置的页面提供查阅链接。包内值与服务器生效值分开标注。


### 本页服务器配置字段（3 条）

来源：`LuckyProduceModel:_LoadOtherServerConfig`。本页底层案例已经假设三连、二连阈值，用于演示两种命中路径；这些数值是演示配置，不代表某个账号的真实配置。

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
