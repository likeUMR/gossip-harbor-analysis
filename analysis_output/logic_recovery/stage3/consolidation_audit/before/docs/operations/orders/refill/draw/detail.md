# 需求抽取与项数：具体算法与配置

CreateNormalRandomOrder：测试指定需求可直接返回；Chest创建资格可把randomConfig换ChestRandom，缺配置才回退普通并清chestModel。初始化重复链状态与ItemsUsingDynamicLevel[slot]，选Filter。selectItem每次重建候选，动态修正→等级过滤→第一项允许备用→空返nil→重复链衰减→ListWeightSelectOne.Code→加入alreadyRequiredItems→超普通max记动态项→MarkSelectedLine。第二依赖first存在，第三依赖second存在。最后RandomOrderHelper.Create再ItemAmounts或按Level升序表逆扫最大≤当前等级档，缺键补0；Count1须first，Count2须second，Count3须third；空Count池返nil。加权选Count后只保留前Count件，再头像/礼物。

重复链：支持Random1/2/3/4/5New/Conti；mapChainRepeatWeight[chain]非nil且配置RepeatWeightDecrease非nil才Weight除该配置值（不是除剩余次数，也非指数）。处理过链先SelectedLine=true，若真正选中此链且有衰减字段/计数则false。最终UpdateMapInfo：true链计数减1，到0删除，false重置3，再保存。候选步骤中已选但最后Count未保留的第二/第三项也已参与MarkSelectedLine，不能按最终需求重算历史。

ListWeightSelectOne按ipairs求sumWeight，用MathUtil.Random(sumWeight)得到floor(u×sum)+1，依次比较≤Weight否则减Weight。只读列表，不统一移除已选项；防重复来自重建候选时alreadyRequiredItems和过滤规则。权重经除法可能为小数，而该工具要求sum为整数的断言仍存在，不能擅自改成浮点轮盘；sum≤0也有断言及非空回退首项边界。正常每单重建池，有放回/排除规则须按具体code候选条件判断，不是全局有限订单池。

## 对应本地配表

各后缀为可选变体，不是同时叠加。require受FileReplace精确文件名首匹配替换，失败才回退默认；实际账号选择及远端档位未取得。缺字段记“—”，不能当0。下方保留全记录与全部字段；嵌套Filters/Rewards可横向滚动查看。

**OrderRandomConfig字段含义：** Type索引内部类型，IsLucky=1行独立选为Lucky配置；UnlockLevel等级门槛，RefreshTime秒，Point批次可创建次数，LuckyTriggerChance为浮点阈值（缺省不抽）；Filters按数组首匹配，Player/DiffSum/MonthPay上下界含端点，First/Second/Third及Dynamic上限控制逐项难度；ItemAmounts是一/二/三项权重，不是产物code权重。

<details><summary>OrderRandomConfig：9条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Filters</th><th>ItemAmounts</th><th>Point</th><th>RefreshTime</th><th>Type</th><th>UnlockLevel</th></tr></thead><tbody>
<tr><td>[{&quot;FirstMax&quot;: 6, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 6, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>5</td><td>3600</td><td>1</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>1800</td><td>2</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 35, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 8, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 36}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 9, &quot;PlayerMin&quot;: 36}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;DiffSumMax&quot;: 2500, &quot;PlayerMin&quot;: 61}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2501, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>900</td><td>3</td><td>4</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 50, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 8, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 50, &quot;SecondMax&quot;: 7, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 9, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 9, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 51}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 51}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 10, &quot;DiffSumMax&quot;: 2500, &quot;PlayerMin&quot;: 81}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 9, &quot;DiffSumMin&quot;: 2501, &quot;FirstMin&quot;: 11, &quot;PlayerMin&quot;: 81}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>300</td><td>4</td><td>5</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>1200</td><td>9</td><td>10</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6}]</td><td>—</td><td>—</td><td>3600</td><td>12</td><td>14</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;SecondMin&quot;: 4, &quot;ThirdMin&quot;: 3, &quot;FirstMin&quot;: 5, &quot;SecondMax&quot;: 5}]</td><td>—</td><td>—</td><td>1</td><td>15</td><td>12</td></tr>
<tr><td>[{}]</td><td>—</td><td>—</td><td>1</td><td>16</td><td>1</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 12, &quot;ThirdMax&quot;: 10, &quot;SecondMax&quot;: 10, &quot;FirstMin&quot;: 12}]</td><td>{&quot;OneItemWeight&quot;: 100, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 0}</td><td>—</td><td>120</td><td>21</td><td>10</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderRandomConfig.json">完整原记录</a></p></details>

<details><summary>OrderRandomConfig_dynamic：9条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Filters</th><th>ItemAmounts</th><th>Point</th><th>RefreshTime</th><th>Type</th><th>UnlockLevel</th></tr></thead><tbody>
<tr><td>[{&quot;FirstMax&quot;: 6, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 6, &quot;PlayerMax&quot;: 40, &quot;SecondMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 6, &quot;DynamicFirstMax&quot;: 7, &quot;SecondMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;PlayerMin&quot;: 41}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>5</td><td>3600</td><td>1</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 40, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 7, &quot;DynamicFirstMax&quot;: 8, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 41}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>1800</td><td>2</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 35, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 8, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 36}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 9, &quot;PlayerMin&quot;: 36}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;DiffSumMax&quot;: 2500, &quot;PlayerMin&quot;: 61}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2501, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>900</td><td>3</td><td>4</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 50, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 8, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 50, &quot;SecondMax&quot;: 7, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 9, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 9, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 51}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 51}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 10, &quot;DiffSumMax&quot;: 2500, &quot;PlayerMin&quot;: 81}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 9, &quot;DiffSumMin&quot;: 2501, &quot;FirstMin&quot;: 11, &quot;PlayerMin&quot;: 81}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>300</td><td>4</td><td>5</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 40, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 8, &quot;DynamicFirstMax&quot;: 9, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 41}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>1200</td><td>9</td><td>10</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6}]</td><td>—</td><td>—</td><td>3600</td><td>12</td><td>14</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;SecondMin&quot;: 4, &quot;ThirdMin&quot;: 3, &quot;FirstMin&quot;: 5, &quot;SecondMax&quot;: 5}]</td><td>—</td><td>—</td><td>1</td><td>15</td><td>12</td></tr>
<tr><td>[{}]</td><td>—</td><td>—</td><td>1</td><td>16</td><td>1</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 12, &quot;ThirdMax&quot;: 10, &quot;SecondMax&quot;: 10, &quot;FirstMin&quot;: 12}]</td><td>{&quot;OneItemWeight&quot;: 100, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 0}</td><td>—</td><td>120</td><td>21</td><td>10</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderRandomConfig_dynamic.json">完整原记录</a></p></details>

<details><summary>OrderRandomConfig_hard：9条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Filters</th><th>ItemAmounts</th><th>Point</th><th>RefreshTime</th><th>Type</th><th>UnlockLevel</th></tr></thead><tbody>
<tr><td>[{&quot;FirstMax&quot;: 6, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 6, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>5</td><td>3600</td><td>1</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>1800</td><td>2</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 40, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 9, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 41}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 41}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;DiffSumMax&quot;: 2500, &quot;PlayerMin&quot;: 61}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2501, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>900</td><td>3</td><td>4</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 40, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 9, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 40, &quot;SecondMax&quot;: 7, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 10, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 41}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 11, &quot;PlayerMin&quot;: 41}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 11, &quot;DiffSumMax&quot;: 2500, &quot;PlayerMin&quot;: 81}, {&quot;FirstMax&quot;: 12, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 9, &quot;DiffSumMin&quot;: 2501, &quot;FirstMin&quot;: 11, &quot;PlayerMin&quot;: 81}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>300</td><td>4</td><td>5</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 40, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 9, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;PlayerMin&quot;: 41}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>1200</td><td>9</td><td>10</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6}]</td><td>—</td><td>—</td><td>3600</td><td>12</td><td>14</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;SecondMin&quot;: 4, &quot;ThirdMin&quot;: 3, &quot;FirstMin&quot;: 5, &quot;SecondMax&quot;: 5}]</td><td>—</td><td>—</td><td>1</td><td>15</td><td>12</td></tr>
<tr><td>[{}]</td><td>—</td><td>—</td><td>1</td><td>16</td><td>1</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 12, &quot;ThirdMax&quot;: 10, &quot;SecondMax&quot;: 10, &quot;FirstMin&quot;: 12}]</td><td>{&quot;OneItemWeight&quot;: 100, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 0}</td><td>—</td><td>120</td><td>21</td><td>10</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderRandomConfig_hard.json">完整原记录</a></p></details>

<details><summary>OrderRandomConfig_lessitem：8条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Filters</th><th>ItemAmounts</th><th>Point</th><th>RefreshTime</th><th>Type</th><th>UnlockLevel</th></tr></thead><tbody>
<tr><td>[{&quot;FirstMax&quot;: 6, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 6, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>5</td><td>3600</td><td>1</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>1800</td><td>2</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 35, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 8, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 36}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 9, &quot;PlayerMin&quot;: 36}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;DiffSumMax&quot;: 2500, &quot;PlayerMin&quot;: 61}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2501, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>900</td><td>3</td><td>4</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 50, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 8, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 50, &quot;SecondMax&quot;: 7, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 9, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 9, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 51}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 51}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 10, &quot;DiffSumMax&quot;: 2500, &quot;PlayerMin&quot;: 81}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 9, &quot;DiffSumMin&quot;: 2501, &quot;FirstMin&quot;: 11, &quot;PlayerMin&quot;: 81}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>300</td><td>4</td><td>5</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>1200</td><td>9</td><td>10</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6}]</td><td>—</td><td>—</td><td>3600</td><td>12</td><td>14</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;SecondMin&quot;: 4, &quot;ThirdMin&quot;: 3, &quot;FirstMin&quot;: 5, &quot;SecondMax&quot;: 5}]</td><td>—</td><td>—</td><td>1</td><td>15</td><td>12</td></tr>
<tr><td>[{}]</td><td>—</td><td>—</td><td>1</td><td>16</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderRandomConfig_lessitem.json">完整原记录</a></p></details>

<details><summary>OrderRandomConfig_lessitem2：8条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Filters</th><th>ItemAmounts</th><th>Point</th><th>RefreshTime</th><th>Type</th><th>UnlockLevel</th></tr></thead><tbody>
<tr><td>[{&quot;FirstMax&quot;: 6, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 6, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>5</td><td>3600</td><td>1</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>—</td><td>1800</td><td>2</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 35, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 8, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 36}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 9, &quot;PlayerMin&quot;: 36}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;DiffSumMax&quot;: 2500, &quot;PlayerMin&quot;: 61}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2501, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>—</td><td>900</td><td>3</td><td>4</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 50, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 8, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 50, &quot;SecondMax&quot;: 7, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 9, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 9, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 51}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 51}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 10, &quot;DiffSumMax&quot;: 2500, &quot;PlayerMin&quot;: 81}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 9, &quot;DiffSumMin&quot;: 2501, &quot;FirstMin&quot;: 11, &quot;PlayerMin&quot;: 81}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>—</td><td>300</td><td>4</td><td>5</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>—</td><td>1200</td><td>9</td><td>10</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6}]</td><td>—</td><td>—</td><td>3600</td><td>12</td><td>14</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;SecondMin&quot;: 4, &quot;ThirdMin&quot;: 3, &quot;FirstMin&quot;: 5, &quot;SecondMax&quot;: 5}]</td><td>—</td><td>—</td><td>1</td><td>15</td><td>12</td></tr>
<tr><td>[{}]</td><td>—</td><td>—</td><td>1</td><td>16</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderRandomConfig_lessitem2.json">完整原记录</a></p></details>

<details><summary>OrderRandomConfig_lessitem3：8条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Filters</th><th>ItemAmounts</th><th>Point</th><th>RefreshTime</th><th>Type</th><th>UnlockLevel</th></tr></thead><tbody>
<tr><td>[{&quot;FirstMax&quot;: 6, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 5, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>5</td><td>3600</td><td>1</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;SecondMin&quot;: 5, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>—</td><td>1800</td><td>2</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;SecondMin&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 35, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;SecondMin&quot;: 5, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;PlayerMin&quot;: 36, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 8, &quot;SecondMin&quot;: 5, &quot;DiffSumMax&quot;: 2000}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;PlayerMin&quot;: 36, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 9, &quot;SecondMin&quot;: 6}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 61, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;SecondMin&quot;: 6, &quot;DiffSumMax&quot;: 2500}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 61, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2501, &quot;FirstMin&quot;: 10, &quot;SecondMin&quot;: 7}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>—</td><td>900</td><td>3</td><td>4</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;SecondMin&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 50, &quot;PlayerMin&quot;: 30, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 8, &quot;SecondMin&quot;: 5, &quot;DiffSumMax&quot;: 2000}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 50, &quot;PlayerMin&quot;: 30, &quot;SecondMax&quot;: 7, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 9, &quot;SecondMin&quot;: 5}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;PlayerMin&quot;: 51, &quot;SecondMax&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 9, &quot;SecondMin&quot;: 6, &quot;DiffSumMax&quot;: 2000}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;PlayerMin&quot;: 51, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 10, &quot;SecondMin&quot;: 6}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 81, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 10, &quot;SecondMin&quot;: 7, &quot;DiffSumMax&quot;: 2500}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 81, &quot;SecondMax&quot;: 9, &quot;DiffSumMin&quot;: 2501, &quot;FirstMin&quot;: 11, &quot;SecondMin&quot;: 8}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>—</td><td>300</td><td>4</td><td>5</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;SecondMin&quot;: 5, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>—</td><td>1200</td><td>9</td><td>10</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6}]</td><td>—</td><td>—</td><td>3600</td><td>12</td><td>14</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;SecondMin&quot;: 4, &quot;ThirdMin&quot;: 3, &quot;FirstMin&quot;: 5, &quot;SecondMax&quot;: 5}]</td><td>—</td><td>—</td><td>1</td><td>15</td><td>12</td></tr>
<tr><td>[{}]</td><td>—</td><td>—</td><td>1</td><td>16</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderRandomConfig_lessitem3.json">完整原记录</a></p></details>

<details><summary>OrderRandomConfig_medium：9条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Filters</th><th>ItemAmounts</th><th>Point</th><th>RefreshTime</th><th>Type</th><th>UnlockLevel</th></tr></thead><tbody>
<tr><td>[{&quot;FirstMax&quot;: 6, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 6, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>5</td><td>3600</td><td>1</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>1800</td><td>2</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 40, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 9, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 41}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 9, &quot;PlayerMin&quot;: 41}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 10, &quot;DiffSumMax&quot;: 2500, &quot;PlayerMin&quot;: 61}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2501, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>900</td><td>3</td><td>4</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 40, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 9, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 40, &quot;SecondMax&quot;: 7, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 9, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 10, &quot;DiffSumMax&quot;: 2000, &quot;PlayerMin&quot;: 41}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 8, &quot;DiffSumMin&quot;: 2001, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 41}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 11, &quot;DiffSumMax&quot;: 2500, &quot;PlayerMin&quot;: 81}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 9, &quot;DiffSumMin&quot;: 2501, &quot;FirstMin&quot;: 11, &quot;PlayerMin&quot;: 81}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>300</td><td>4</td><td>5</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 40, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 9, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;PlayerMin&quot;: 41}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>1200</td><td>9</td><td>10</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6}]</td><td>—</td><td>—</td><td>3600</td><td>12</td><td>14</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;SecondMin&quot;: 4, &quot;ThirdMin&quot;: 3, &quot;FirstMin&quot;: 5, &quot;SecondMax&quot;: 5}]</td><td>—</td><td>—</td><td>1</td><td>15</td><td>12</td></tr>
<tr><td>[{}]</td><td>—</td><td>—</td><td>1</td><td>16</td><td>1</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 12, &quot;ThirdMax&quot;: 10, &quot;SecondMax&quot;: 10, &quot;FirstMin&quot;: 12}]</td><td>{&quot;OneItemWeight&quot;: 100, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 0}</td><td>—</td><td>120</td><td>21</td><td>10</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderRandomConfig_medium.json">完整原记录</a></p></details>

**OrderItemNumberWeightConfig字段含义：** Level升序装载后从末尾选最大≤玩家等级一条；OneItemWeight/TwoItemsWeight/ThreeItemsWeight仅在对应候选已存在时进需求项数池。

<details><summary>OrderItemNumberWeightConfig：4条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Level</th><th>OneItemWeight</th><th>ThreeItemsWeight</th><th>TwoItemsWeight</th></tr></thead><tbody>
<tr><td>1</td><td>60</td><td>20</td><td>20</td></tr>
<tr><td>4</td><td>40</td><td>30</td><td>30</td></tr>
<tr><td>8</td><td>33</td><td>34</td><td>33</td></tr>
<tr><td>11</td><td>30</td><td>40</td><td>30</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderItemNumberWeightConfig.json">完整原记录</a></p></details>

**OrderItemConfig字段含义：** Code是精确需求代码；Price/RecommendedPrice用于普通/基准单价格；DiffScore为难度累计与活动输入；UnlockLevel含端点门槛；ProgressUnlock=1要求前一级已解锁；ForbiddenSlot排槽；Weight为原始份额；WeightMultiple参与库存链倍率；RepeatWeightDecrease为除数；DifficultyLevel覆盖链等级筛选；RecommendedNumber控制基准单重复数。

<details><summary>OrderItemConfig：74条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Code</th><th>DiffScore</th><th>DifficultyLevel</th><th>ForbiddenSlot</th><th>Price</th><th>ProgressUnlock</th><th>RecommendedNumber</th><th>RecommendedPrice</th><th>RepeatWeightDecrease</th><th>UnlockLevel</th><th>Weight</th><th>WeightMultiple</th></tr></thead><tbody>
<tr><td>203</td><td>2</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>204</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>205</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>206</td><td>19</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>207</td><td>39</td><td>—</td><td>—</td><td>20</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>208</td><td>78</td><td>—</td><td>[10]</td><td>32</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>209</td><td>146</td><td>—</td><td>[10]</td><td>50</td><td>—</td><td>—</td><td>—</td><td>10</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>210</td><td>293</td><td>—</td><td>[10]</td><td>78</td><td>1</td><td>—</td><td>—</td><td>50</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>211</td><td>585</td><td>—</td><td>[10]</td><td>118</td><td>1</td><td>—</td><td>—</td><td>100</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>212</td><td>1170</td><td>—</td><td>[10]</td><td>178</td><td>1</td><td>1</td><td>178</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>213</td><td>2000</td><td>—</td><td>[10]</td><td>270</td><td>1</td><td>1</td><td>270</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>214</td><td>2500</td><td>—</td><td>[10]</td><td>406</td><td>1</td><td>1</td><td>406</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>215</td><td>3000</td><td>—</td><td>[10]</td><td>612</td><td>1</td><td>1</td><td>612</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>303</td><td>11</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>304</td><td>23</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>305</td><td>46</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>5</td><td>100</td><td>1</td></tr>
<tr><td>306</td><td>92</td><td>7</td><td>[10]</td><td>38</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>307</td><td>184</td><td>8</td><td>[10]</td><td>58</td><td>1</td><td>2</td><td>58</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>503</td><td>3</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>504</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>505</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>506</td><td>21</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>507</td><td>42</td><td>—</td><td>—</td><td>24</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>508</td><td>84</td><td>—</td><td>[10]</td><td>36</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>509</td><td>154</td><td>—</td><td>[10]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>10</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>510</td><td>307</td><td>—</td><td>[10]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>50</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>511</td><td>617</td><td>—</td><td>[10]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>100</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>512</td><td>1229</td><td>—</td><td>[10]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>513</td><td>2000</td><td>—</td><td>[10]</td><td>304</td><td>1</td><td>1</td><td>304</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>514</td><td>2500</td><td>—</td><td>[10]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>603</td><td>14</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>604</td><td>27</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>605</td><td>55</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>6</td><td>100</td><td>1</td></tr>
<tr><td>606</td><td>110</td><td>7</td><td>[10]</td><td>41</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>607</td><td>220</td><td>8</td><td>[10]</td><td>62</td><td>1</td><td>2</td><td>62</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>902</td><td>3</td><td>3</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>0</td><td>—</td></tr>
<tr><td>903</td><td>7</td><td>4</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>904</td><td>15</td><td>5</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>905</td><td>30</td><td>6</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>7</td><td>100</td><td>—</td></tr>
<tr><td>906</td><td>60</td><td>7</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>907</td><td>120</td><td>8</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>908</td><td>239</td><td>9</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>909</td><td>479</td><td>10</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>50</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>910</td><td>957</td><td>11</td><td>[10, 11]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1102</td><td>4</td><td>—</td><td>[11, 18]</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1103</td><td>9</td><td>—</td><td>[11, 18]</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1104</td><td>18</td><td>—</td><td>[11, 18]</td><td>14</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1105</td><td>35</td><td>—</td><td>[10, 11, 18]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>10</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1106</td><td>70</td><td>—</td><td>[10, 11, 18]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>50</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1107</td><td>140</td><td>—</td><td>[10, 11, 18]</td><td>54</td><td>1</td><td>2</td><td>42</td><td>100</td><td>25</td><td>100</td><td>1</td></tr>
<tr><td>1303</td><td>3</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1304</td><td>6</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1305</td><td>13</td><td>—</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1306</td><td>26</td><td>—</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1307</td><td>52</td><td>—</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>18</td><td>100</td><td>1</td></tr>
<tr><td>1308</td><td>88</td><td>—</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1309</td><td>176</td><td>—</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>10</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1310</td><td>352</td><td>—</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1311</td><td>704</td><td>—</td><td>[10, 11]</td><td>318</td><td>1</td><td>1</td><td>318</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1403</td><td>12</td><td>4</td><td>[10, 11]</td><td>12</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1404</td><td>24</td><td>5</td><td>[10, 11]</td><td>22</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1405</td><td>48</td><td>6</td><td>[10, 11]</td><td>34</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1406</td><td>97</td><td>7</td><td>[10, 11]</td><td>54</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1407</td><td>194</td><td>8</td><td>[10, 11]</td><td>86</td><td>1</td><td>1</td><td>86</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1803</td><td>3</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1804</td><td>7</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1805</td><td>13</td><td>—</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1806</td><td>27</td><td>—</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1807</td><td>58</td><td>—</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1808</td><td>91</td><td>—</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>—</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1809</td><td>183</td><td>—</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>10</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1810</td><td>366</td><td>—</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>50</td><td>36</td><td>100</td><td>1</td></tr>
<tr><td>1811</td><td>731</td><td>—</td><td>[10, 11]</td><td>304</td><td>1</td><td>—</td><td>—</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1812</td><td>1463</td><td>—</td><td>[10, 11]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>41</td><td>100</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderItemConfig.json">完整原记录</a></p></details>

<details><summary>OrderItemConfig_extracust：76条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Code</th><th>DiffScore</th><th>DifficultyLevel</th><th>ForbiddenSlot</th><th>Price</th><th>ProgressUnlock</th><th>RecommendedNumber</th><th>RecommendedPrice</th><th>RepeatWeightDecrease</th><th>UnlockLevel</th><th>Weight</th><th>WeightMultiple</th></tr></thead><tbody>
<tr><td>203</td><td>2</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>204</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>205</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>206</td><td>19</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>207</td><td>39</td><td>—</td><td>—</td><td>20</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>208</td><td>78</td><td>—</td><td>[10]</td><td>32</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>209</td><td>146</td><td>—</td><td>[10]</td><td>50</td><td>—</td><td>—</td><td>—</td><td>10</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>210</td><td>293</td><td>—</td><td>[10]</td><td>78</td><td>1</td><td>—</td><td>—</td><td>50</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>211</td><td>585</td><td>—</td><td>[10]</td><td>118</td><td>1</td><td>—</td><td>—</td><td>100</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>212</td><td>878</td><td>—</td><td>[10]</td><td>178</td><td>1</td><td>1</td><td>178</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>213</td><td>1317</td><td>—</td><td>[10]</td><td>270</td><td>1</td><td>1</td><td>270</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>214</td><td>1976</td><td>—</td><td>[10]</td><td>406</td><td>1</td><td>1</td><td>406</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>215</td><td>3000</td><td>—</td><td>[10]</td><td>612</td><td>1</td><td>1</td><td>612</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>303</td><td>11</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>304</td><td>23</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>305</td><td>46</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>5</td><td>100</td><td>1</td></tr>
<tr><td>306</td><td>92</td><td>7</td><td>[10]</td><td>38</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>307</td><td>184</td><td>8</td><td>[10]</td><td>58</td><td>1</td><td>2</td><td>58</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>503</td><td>3</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>504</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>505</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>506</td><td>21</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>507</td><td>42</td><td>—</td><td>—</td><td>24</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>508</td><td>84</td><td>—</td><td>[10]</td><td>36</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>509</td><td>154</td><td>—</td><td>[10]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>10</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>510</td><td>307</td><td>—</td><td>[10]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>50</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>511</td><td>617</td><td>—</td><td>[10]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>100</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>512</td><td>926</td><td>—</td><td>[10]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>513</td><td>1389</td><td>—</td><td>[10]</td><td>304</td><td>1</td><td>1</td><td>304</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>514</td><td>2084</td><td>—</td><td>[10]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>603</td><td>14</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>604</td><td>27</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>605</td><td>55</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>6</td><td>100</td><td>1</td></tr>
<tr><td>606</td><td>110</td><td>7</td><td>[10]</td><td>41</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>607</td><td>220</td><td>8</td><td>[10]</td><td>62</td><td>1</td><td>2</td><td>62</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>902</td><td>3</td><td>3</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>0</td><td>—</td></tr>
<tr><td>903</td><td>7</td><td>4</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>904</td><td>15</td><td>5</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>905</td><td>30</td><td>6</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>7</td><td>100</td><td>—</td></tr>
<tr><td>906</td><td>60</td><td>7</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>907</td><td>120</td><td>8</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>908</td><td>239</td><td>9</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>909</td><td>479</td><td>10</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>50</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>910</td><td>957</td><td>11</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>911</td><td>1436</td><td>12</td><td>[10, 11]</td><td>309</td><td>1</td><td>1</td><td>309</td><td>100</td><td>51</td><td>100</td><td>1</td></tr>
<tr><td>1102</td><td>4</td><td>—</td><td>[11, 18]</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1103</td><td>9</td><td>—</td><td>[11, 18]</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1104</td><td>18</td><td>—</td><td>[11, 18]</td><td>14</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1105</td><td>35</td><td>—</td><td>[10, 11, 18]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>10</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1106</td><td>70</td><td>—</td><td>[10, 11, 18]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>50</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1107</td><td>140</td><td>—</td><td>[10, 11, 18]</td><td>54</td><td>1</td><td>2</td><td>42</td><td>100</td><td>25</td><td>100</td><td>1</td></tr>
<tr><td>1303</td><td>3</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1304</td><td>6</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1305</td><td>13</td><td>—</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1306</td><td>26</td><td>—</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1307</td><td>52</td><td>—</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>18</td><td>100</td><td>1</td></tr>
<tr><td>1308</td><td>88</td><td>—</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1309</td><td>176</td><td>—</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>10</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1310</td><td>352</td><td>—</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1311</td><td>704</td><td>—</td><td>[10, 11]</td><td>318</td><td>1</td><td>—</td><td>—</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1312</td><td>1056</td><td>—</td><td>[10, 11]</td><td>501</td><td>1</td><td>1</td><td>501</td><td>100</td><td>51</td><td>100</td><td>1</td></tr>
<tr><td>1403</td><td>12</td><td>4</td><td>[10, 11]</td><td>12</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1404</td><td>24</td><td>5</td><td>[10, 11]</td><td>22</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1405</td><td>48</td><td>6</td><td>[10, 11]</td><td>34</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1406</td><td>97</td><td>7</td><td>[10, 11]</td><td>54</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1407</td><td>194</td><td>8</td><td>[10, 11]</td><td>86</td><td>1</td><td>1</td><td>86</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1803</td><td>3</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1804</td><td>7</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1805</td><td>13</td><td>—</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1806</td><td>27</td><td>—</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1807</td><td>58</td><td>—</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1808</td><td>91</td><td>—</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>—</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1809</td><td>183</td><td>—</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>10</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1810</td><td>366</td><td>—</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>50</td><td>36</td><td>100</td><td>1</td></tr>
<tr><td>1811</td><td>731</td><td>—</td><td>[10, 11]</td><td>304</td><td>1</td><td>—</td><td>—</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1812</td><td>1097</td><td>—</td><td>[10, 11]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>41</td><td>100</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderItemConfig_extracust.json">完整原记录</a></p></details>

<details><summary>OrderItemConfig_hard：74条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Code</th><th>DiffScore</th><th>DifficultyLevel</th><th>ForbiddenSlot</th><th>Price</th><th>ProgressUnlock</th><th>RecommendedNumber</th><th>RecommendedPrice</th><th>RepeatWeightDecrease</th><th>UnlockLevel</th><th>Weight</th><th>WeightMultiple</th></tr></thead><tbody>
<tr><td>203</td><td>2</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>204</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>205</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>206</td><td>19</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>207</td><td>39</td><td>—</td><td>—</td><td>20</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>208</td><td>78</td><td>—</td><td>[10]</td><td>32</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>209</td><td>146</td><td>—</td><td>[10]</td><td>50</td><td>—</td><td>—</td><td>—</td><td>10</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>210</td><td>293</td><td>—</td><td>[10]</td><td>78</td><td>1</td><td>—</td><td>—</td><td>50</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>211</td><td>585</td><td>—</td><td>[10]</td><td>118</td><td>1</td><td>—</td><td>—</td><td>100</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>212</td><td>1170</td><td>—</td><td>[10]</td><td>178</td><td>1</td><td>1</td><td>178</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>213</td><td>2000</td><td>—</td><td>[10]</td><td>270</td><td>1</td><td>1</td><td>270</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>214</td><td>2500</td><td>—</td><td>[10]</td><td>406</td><td>1</td><td>1</td><td>406</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>215</td><td>3000</td><td>—</td><td>[10]</td><td>612</td><td>1</td><td>1</td><td>612</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>303</td><td>11</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>304</td><td>23</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>305</td><td>46</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>5</td><td>100</td><td>1</td></tr>
<tr><td>306</td><td>92</td><td>7</td><td>[10]</td><td>38</td><td>1</td><td>—</td><td>—</td><td>50</td><td>10</td><td>100</td><td>1</td></tr>
<tr><td>307</td><td>184</td><td>8</td><td>[10]</td><td>58</td><td>1</td><td>2</td><td>58</td><td>100</td><td>16</td><td>100</td><td>1</td></tr>
<tr><td>503</td><td>3</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>504</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>505</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>506</td><td>21</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>507</td><td>42</td><td>—</td><td>—</td><td>24</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>508</td><td>84</td><td>—</td><td>[10]</td><td>36</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>509</td><td>154</td><td>—</td><td>[10]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>10</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>510</td><td>307</td><td>—</td><td>[10]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>50</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>511</td><td>617</td><td>—</td><td>[10]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>100</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>512</td><td>1229</td><td>—</td><td>[10]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>513</td><td>2000</td><td>—</td><td>[10]</td><td>304</td><td>1</td><td>1</td><td>304</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>514</td><td>2500</td><td>—</td><td>[10]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>603</td><td>14</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>604</td><td>27</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>605</td><td>55</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>6</td><td>100</td><td>1</td></tr>
<tr><td>606</td><td>110</td><td>7</td><td>[10]</td><td>41</td><td>1</td><td>—</td><td>—</td><td>50</td><td>10</td><td>100</td><td>1</td></tr>
<tr><td>607</td><td>220</td><td>8</td><td>[10]</td><td>62</td><td>1</td><td>2</td><td>62</td><td>100</td><td>16</td><td>100</td><td>1</td></tr>
<tr><td>902</td><td>3</td><td>3</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>0</td><td>—</td></tr>
<tr><td>903</td><td>7</td><td>4</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>904</td><td>15</td><td>5</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>905</td><td>30</td><td>6</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>7</td><td>100</td><td>—</td></tr>
<tr><td>906</td><td>60</td><td>7</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>907</td><td>120</td><td>8</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>908</td><td>239</td><td>9</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>10</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>909</td><td>479</td><td>10</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>910</td><td>957</td><td>11</td><td>[10, 11]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>100</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1102</td><td>4</td><td>—</td><td>[11, 18]</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1103</td><td>9</td><td>—</td><td>[11, 18]</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1104</td><td>18</td><td>—</td><td>[11, 18]</td><td>14</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1105</td><td>35</td><td>—</td><td>[10, 11, 18]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>10</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1106</td><td>70</td><td>—</td><td>[10, 11, 18]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1107</td><td>140</td><td>—</td><td>[10, 11, 18]</td><td>54</td><td>1</td><td>2</td><td>42</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1303</td><td>3</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1304</td><td>6</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1305</td><td>13</td><td>—</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1306</td><td>26</td><td>—</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1307</td><td>52</td><td>—</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1308</td><td>88</td><td>—</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1309</td><td>176</td><td>—</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>10</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1310</td><td>352</td><td>—</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>50</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1311</td><td>704</td><td>—</td><td>[10, 11]</td><td>318</td><td>1</td><td>1</td><td>318</td><td>100</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1403</td><td>12</td><td>4</td><td>[10, 11]</td><td>12</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1404</td><td>24</td><td>5</td><td>[10, 11]</td><td>22</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1405</td><td>48</td><td>6</td><td>[10, 11]</td><td>34</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1406</td><td>97</td><td>7</td><td>[10, 11]</td><td>54</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1407</td><td>194</td><td>8</td><td>[10, 11]</td><td>86</td><td>1</td><td>1</td><td>86</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1803</td><td>3</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1804</td><td>7</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1805</td><td>13</td><td>—</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1806</td><td>27</td><td>—</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1807</td><td>58</td><td>—</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>1</td></tr>
<tr><td>1808</td><td>91</td><td>—</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>1</td></tr>
<tr><td>1809</td><td>183</td><td>—</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>10</td><td>10</td><td>100</td><td>1</td></tr>
<tr><td>1810</td><td>366</td><td>—</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>50</td><td>10</td><td>100</td><td>1</td></tr>
<tr><td>1811</td><td>731</td><td>—</td><td>[10, 11]</td><td>304</td><td>1</td><td>—</td><td>—</td><td>100</td><td>10</td><td>100</td><td>1</td></tr>
<tr><td>1812</td><td>1463</td><td>—</td><td>[10, 11]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>10</td><td>100</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderItemConfig_hard.json">完整原记录</a></p></details>

<details><summary>OrderItemConfig_nerf：74条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Code</th><th>DiffScore</th><th>DifficultyLevel</th><th>ForbiddenSlot</th><th>Price</th><th>ProgressUnlock</th><th>RecommendedNumber</th><th>RecommendedPrice</th><th>RepeatWeightDecrease</th><th>UnlockLevel</th><th>Weight</th><th>WeightMultiple</th></tr></thead><tbody>
<tr><td>203</td><td>2</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>204</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>205</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>206</td><td>19</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>207</td><td>39</td><td>—</td><td>—</td><td>20</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>208</td><td>78</td><td>—</td><td>[10]</td><td>32</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>209</td><td>146</td><td>—</td><td>[10]</td><td>50</td><td>—</td><td>—</td><td>—</td><td>10</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>210</td><td>293</td><td>—</td><td>[10]</td><td>78</td><td>1</td><td>—</td><td>—</td><td>50</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>211</td><td>585</td><td>—</td><td>[10]</td><td>118</td><td>1</td><td>—</td><td>—</td><td>100</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>212</td><td>1170</td><td>—</td><td>[10]</td><td>178</td><td>1</td><td>1</td><td>178</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>213</td><td>2000</td><td>—</td><td>[10]</td><td>270</td><td>1</td><td>1</td><td>270</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>214</td><td>2500</td><td>—</td><td>[10]</td><td>406</td><td>1</td><td>1</td><td>406</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>215</td><td>3000</td><td>—</td><td>[10]</td><td>612</td><td>1</td><td>1</td><td>612</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>303</td><td>11</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>304</td><td>23</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>305</td><td>46</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>5</td><td>100</td><td>1</td></tr>
<tr><td>306</td><td>92</td><td>7</td><td>[10]</td><td>38</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>307</td><td>184</td><td>8</td><td>[10]</td><td>58</td><td>1</td><td>2</td><td>58</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>503</td><td>3</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>504</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>505</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>506</td><td>21</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>507</td><td>42</td><td>—</td><td>—</td><td>24</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>508</td><td>84</td><td>—</td><td>[10]</td><td>36</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>509</td><td>154</td><td>—</td><td>[10]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>10</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>510</td><td>307</td><td>—</td><td>[10]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>50</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>511</td><td>617</td><td>—</td><td>[10]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>100</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>512</td><td>1229</td><td>—</td><td>[10]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>513</td><td>2000</td><td>—</td><td>[10]</td><td>304</td><td>1</td><td>1</td><td>304</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>514</td><td>2500</td><td>—</td><td>[10]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>603</td><td>14</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>604</td><td>27</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>605</td><td>55</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>6</td><td>100</td><td>1</td></tr>
<tr><td>606</td><td>110</td><td>7</td><td>[10]</td><td>41</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>607</td><td>220</td><td>8</td><td>[10]</td><td>62</td><td>1</td><td>2</td><td>62</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>902</td><td>3</td><td>3</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>0</td><td>—</td></tr>
<tr><td>903</td><td>7</td><td>4</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>904</td><td>15</td><td>5</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>905</td><td>30</td><td>6</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>7</td><td>100</td><td>—</td></tr>
<tr><td>906</td><td>60</td><td>7</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>907</td><td>120</td><td>8</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>908</td><td>239</td><td>9</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>909</td><td>479</td><td>10</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>50</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>910</td><td>957</td><td>11</td><td>[10, 11]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1102</td><td>4</td><td>—</td><td>[11, 18]</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1103</td><td>9</td><td>—</td><td>[11, 18]</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1104</td><td>18</td><td>—</td><td>[11, 18]</td><td>14</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1105</td><td>35</td><td>—</td><td>[10, 11, 18]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>10</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1106</td><td>70</td><td>—</td><td>[10, 11, 18]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>50</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1107</td><td>140</td><td>—</td><td>[10, 11, 18]</td><td>54</td><td>1</td><td>2</td><td>42</td><td>100</td><td>25</td><td>100</td><td>1</td></tr>
<tr><td>1303</td><td>3</td><td>—</td><td>—</td><td>7</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1304</td><td>6</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1305</td><td>13</td><td>—</td><td>[10]</td><td>20</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1306</td><td>26</td><td>—</td><td>[10, 11]</td><td>30</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1307</td><td>52</td><td>—</td><td>[10, 11]</td><td>47</td><td>1</td><td>—</td><td>—</td><td>—</td><td>18</td><td>100</td><td>1</td></tr>
<tr><td>1308</td><td>88</td><td>—</td><td>[10, 11]</td><td>73</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1309</td><td>176</td><td>—</td><td>[10, 11]</td><td>110</td><td>1</td><td>—</td><td>—</td><td>10</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1310</td><td>352</td><td>—</td><td>[10, 11]</td><td>168</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1311</td><td>704</td><td>—</td><td>[10, 11]</td><td>265</td><td>1</td><td>1</td><td>318</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1403</td><td>12</td><td>4</td><td>[10, 11]</td><td>10</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1404</td><td>24</td><td>5</td><td>[10, 11]</td><td>18</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1405</td><td>48</td><td>6</td><td>[10, 11]</td><td>28</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1406</td><td>97</td><td>7</td><td>[10, 11]</td><td>45</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1407</td><td>194</td><td>8</td><td>[10, 11]</td><td>72</td><td>1</td><td>1</td><td>86</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1803</td><td>3</td><td>—</td><td>—</td><td>7</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1804</td><td>7</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1805</td><td>13</td><td>—</td><td>[10]</td><td>20</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1806</td><td>27</td><td>—</td><td>[10, 11]</td><td>30</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1807</td><td>58</td><td>—</td><td>[10, 11]</td><td>47</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1808</td><td>91</td><td>—</td><td>[10, 11]</td><td>73</td><td>1</td><td>—</td><td>—</td><td>—</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1809</td><td>183</td><td>—</td><td>[10, 11]</td><td>110</td><td>1</td><td>—</td><td>—</td><td>10</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1810</td><td>366</td><td>—</td><td>[10, 11]</td><td>168</td><td>1</td><td>—</td><td>—</td><td>50</td><td>36</td><td>100</td><td>1</td></tr>
<tr><td>1811</td><td>731</td><td>—</td><td>[10, 11]</td><td>253</td><td>1</td><td>—</td><td>—</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1812</td><td>1463</td><td>—</td><td>[10, 11]</td><td>382</td><td>1</td><td>1</td><td>458</td><td>—</td><td>41</td><td>100</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderItemConfig_nerf.json">完整原记录</a></p></details>

<details><summary>OrderItemConfig_nerf_more：74条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Code</th><th>DiffScore</th><th>DifficultyLevel</th><th>ForbiddenSlot</th><th>Price</th><th>ProgressUnlock</th><th>RecommendedNumber</th><th>RecommendedPrice</th><th>RepeatWeightDecrease</th><th>UnlockLevel</th><th>Weight</th><th>WeightMultiple</th></tr></thead><tbody>
<tr><td>203</td><td>2</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>204</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>205</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>206</td><td>19</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>207</td><td>39</td><td>—</td><td>—</td><td>20</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>208</td><td>78</td><td>—</td><td>[10]</td><td>32</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>209</td><td>146</td><td>—</td><td>[10]</td><td>50</td><td>—</td><td>—</td><td>—</td><td>10</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>210</td><td>293</td><td>—</td><td>[10]</td><td>78</td><td>1</td><td>—</td><td>—</td><td>50</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>211</td><td>585</td><td>—</td><td>[10]</td><td>118</td><td>1</td><td>—</td><td>—</td><td>100</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>212</td><td>1170</td><td>—</td><td>[10]</td><td>178</td><td>1</td><td>1</td><td>178</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>213</td><td>2000</td><td>—</td><td>[10]</td><td>270</td><td>1</td><td>1</td><td>270</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>214</td><td>2500</td><td>—</td><td>[10]</td><td>406</td><td>1</td><td>1</td><td>406</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>215</td><td>3000</td><td>—</td><td>[10]</td><td>612</td><td>1</td><td>1</td><td>612</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>303</td><td>11</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>304</td><td>23</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>305</td><td>46</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>5</td><td>100</td><td>1</td></tr>
<tr><td>306</td><td>92</td><td>7</td><td>[10]</td><td>38</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>307</td><td>184</td><td>8</td><td>[10]</td><td>58</td><td>1</td><td>2</td><td>58</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>503</td><td>3</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>504</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>505</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>506</td><td>21</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>507</td><td>42</td><td>—</td><td>—</td><td>24</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>508</td><td>84</td><td>—</td><td>[10]</td><td>36</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>509</td><td>154</td><td>—</td><td>[10]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>10</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>510</td><td>307</td><td>—</td><td>[10]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>50</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>511</td><td>617</td><td>—</td><td>[10]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>100</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>512</td><td>1229</td><td>—</td><td>[10]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>513</td><td>2000</td><td>—</td><td>[10]</td><td>304</td><td>1</td><td>1</td><td>304</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>514</td><td>2500</td><td>—</td><td>[10]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>603</td><td>14</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>604</td><td>27</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>605</td><td>55</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>6</td><td>100</td><td>1</td></tr>
<tr><td>606</td><td>110</td><td>7</td><td>[10]</td><td>41</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>607</td><td>220</td><td>8</td><td>[10]</td><td>62</td><td>1</td><td>2</td><td>62</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>902</td><td>3</td><td>3</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>0</td><td>—</td></tr>
<tr><td>903</td><td>7</td><td>4</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>904</td><td>15</td><td>5</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>905</td><td>30</td><td>6</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>7</td><td>100</td><td>—</td></tr>
<tr><td>906</td><td>60</td><td>7</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>907</td><td>120</td><td>8</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>908</td><td>239</td><td>9</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>909</td><td>479</td><td>10</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>50</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>910</td><td>957</td><td>11</td><td>[10, 11]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1102</td><td>4</td><td>—</td><td>[11, 18]</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1103</td><td>9</td><td>—</td><td>[11, 18]</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1104</td><td>18</td><td>—</td><td>[11, 18]</td><td>14</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1105</td><td>35</td><td>—</td><td>[10, 11, 18]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>10</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1106</td><td>70</td><td>—</td><td>[10, 11, 18]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>50</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1107</td><td>140</td><td>—</td><td>[10, 11, 18]</td><td>54</td><td>1</td><td>2</td><td>42</td><td>100</td><td>25</td><td>100</td><td>1</td></tr>
<tr><td>1303</td><td>3</td><td>—</td><td>—</td><td>6</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1304</td><td>6</td><td>—</td><td>—</td><td>10</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1305</td><td>13</td><td>—</td><td>[10]</td><td>17</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1306</td><td>26</td><td>—</td><td>[10, 11]</td><td>26</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1307</td><td>52</td><td>—</td><td>[10, 11]</td><td>40</td><td>1</td><td>—</td><td>—</td><td>—</td><td>18</td><td>100</td><td>1</td></tr>
<tr><td>1308</td><td>88</td><td>—</td><td>[10, 11]</td><td>63</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1309</td><td>176</td><td>—</td><td>[10, 11]</td><td>94</td><td>1</td><td>—</td><td>—</td><td>10</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1310</td><td>352</td><td>—</td><td>[10, 11]</td><td>144</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1311</td><td>704</td><td>—</td><td>[10, 11]</td><td>227</td><td>1</td><td>1</td><td>318</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1403</td><td>12</td><td>4</td><td>[10, 11]</td><td>9</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1404</td><td>24</td><td>5</td><td>[10, 11]</td><td>16</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1405</td><td>48</td><td>6</td><td>[10, 11]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1406</td><td>97</td><td>7</td><td>[10, 11]</td><td>39</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1407</td><td>194</td><td>8</td><td>[10, 11]</td><td>61</td><td>1</td><td>1</td><td>86</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1803</td><td>3</td><td>—</td><td>—</td><td>6</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1804</td><td>7</td><td>—</td><td>—</td><td>10</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1805</td><td>13</td><td>—</td><td>[10]</td><td>17</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1806</td><td>27</td><td>—</td><td>[10, 11]</td><td>26</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1807</td><td>58</td><td>—</td><td>[10, 11]</td><td>40</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1808</td><td>91</td><td>—</td><td>[10, 11]</td><td>63</td><td>1</td><td>—</td><td>—</td><td>—</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1809</td><td>183</td><td>—</td><td>[10, 11]</td><td>94</td><td>1</td><td>—</td><td>—</td><td>10</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1810</td><td>366</td><td>—</td><td>[10, 11]</td><td>144</td><td>1</td><td>—</td><td>—</td><td>50</td><td>36</td><td>100</td><td>1</td></tr>
<tr><td>1811</td><td>731</td><td>—</td><td>[10, 11]</td><td>217</td><td>1</td><td>—</td><td>—</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1812</td><td>1463</td><td>—</td><td>[10, 11]</td><td>327</td><td>1</td><td>1</td><td>458</td><td>—</td><td>41</td><td>100</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderItemConfig_nerf_more.json">完整原记录</a></p></details>

<details><summary>OrderItemConfig_shell：80条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Code</th><th>DiffScore</th><th>DifficultyLevel</th><th>ForbiddenSlot</th><th>Price</th><th>ProgressUnlock</th><th>RecommendedNumber</th><th>RecommendedPrice</th><th>RepeatWeightDecrease</th><th>UnlockLevel</th><th>Weight</th><th>WeightMultiple</th></tr></thead><tbody>
<tr><td>203</td><td>2</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>204</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>205</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>206</td><td>19</td><td>—</td><td>—</td><td>12</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>207</td><td>39</td><td>—</td><td>—</td><td>20</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>—</td></tr>
<tr><td>208</td><td>78</td><td>—</td><td>[10]</td><td>32</td><td>—</td><td>—</td><td>—</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>209</td><td>146</td><td>—</td><td>[10]</td><td>50</td><td>—</td><td>—</td><td>—</td><td>10</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>210</td><td>293</td><td>—</td><td>[10]</td><td>78</td><td>1</td><td>—</td><td>—</td><td>50</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>211</td><td>585</td><td>—</td><td>[10]</td><td>118</td><td>1</td><td>—</td><td>—</td><td>100</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>212</td><td>1170</td><td>—</td><td>[10]</td><td>178</td><td>1</td><td>1</td><td>178</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>213</td><td>2000</td><td>—</td><td>[10]</td><td>270</td><td>1</td><td>1</td><td>270</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>214</td><td>2500</td><td>—</td><td>[10]</td><td>406</td><td>1</td><td>1</td><td>406</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>215</td><td>3000</td><td>—</td><td>[10]</td><td>612</td><td>1</td><td>1</td><td>612</td><td>—</td><td>1</td><td>100</td><td>1</td></tr>
<tr><td>303</td><td>11</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>304</td><td>23</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>2</td><td>100</td><td>—</td></tr>
<tr><td>305</td><td>46</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>5</td><td>100</td><td>1</td></tr>
<tr><td>306</td><td>92</td><td>7</td><td>[10]</td><td>38</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>307</td><td>184</td><td>8</td><td>[10]</td><td>58</td><td>1</td><td>2</td><td>58</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>503</td><td>3</td><td>—</td><td>—</td><td>2</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>504</td><td>5</td><td>—</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>505</td><td>10</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>506</td><td>21</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>507</td><td>42</td><td>—</td><td>—</td><td>24</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>—</td></tr>
<tr><td>508</td><td>84</td><td>—</td><td>[10]</td><td>36</td><td>—</td><td>—</td><td>—</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>509</td><td>154</td><td>—</td><td>[10]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>10</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>510</td><td>307</td><td>—</td><td>[10]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>50</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>511</td><td>617</td><td>—</td><td>[10]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>100</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>512</td><td>1229</td><td>—</td><td>[10]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>513</td><td>2000</td><td>—</td><td>[10]</td><td>304</td><td>1</td><td>1</td><td>304</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>514</td><td>2500</td><td>—</td><td>[10]</td><td>458</td><td>1</td><td>1</td><td>458</td><td>—</td><td>3</td><td>100</td><td>1</td></tr>
<tr><td>603</td><td>14</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>604</td><td>27</td><td>—</td><td>[10]</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>4</td><td>100</td><td>—</td></tr>
<tr><td>605</td><td>55</td><td>—</td><td>[10]</td><td>24</td><td>—</td><td>—</td><td>—</td><td>10</td><td>6</td><td>100</td><td>1</td></tr>
<tr><td>606</td><td>110</td><td>7</td><td>[10]</td><td>41</td><td>1</td><td>—</td><td>—</td><td>50</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>607</td><td>220</td><td>8</td><td>[10]</td><td>62</td><td>1</td><td>2</td><td>62</td><td>100</td><td>20</td><td>100</td><td>1</td></tr>
<tr><td>902</td><td>3</td><td>3</td><td>—</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>0</td><td>—</td></tr>
<tr><td>903</td><td>7</td><td>4</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>904</td><td>15</td><td>5</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>6</td><td>100</td><td>—</td></tr>
<tr><td>905</td><td>30</td><td>6</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>7</td><td>100</td><td>—</td></tr>
<tr><td>906</td><td>60</td><td>7</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>907</td><td>120</td><td>8</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>908</td><td>239</td><td>9</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>909</td><td>479</td><td>10</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>50</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>910</td><td>957</td><td>11</td><td>[10, 11]</td><td>202</td><td>1</td><td>1</td><td>202</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1102</td><td>4</td><td>—</td><td>[11, 18]</td><td>4</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1103</td><td>9</td><td>—</td><td>[11, 18]</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1104</td><td>18</td><td>—</td><td>[11, 18]</td><td>14</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1105</td><td>35</td><td>—</td><td>[10, 11, 18]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>10</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1106</td><td>70</td><td>—</td><td>[10, 11, 18]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>50</td><td>9</td><td>100</td><td>1</td></tr>
<tr><td>1107</td><td>140</td><td>—</td><td>[10, 11, 18]</td><td>54</td><td>1</td><td>2</td><td>42</td><td>100</td><td>25</td><td>100</td><td>1</td></tr>
<tr><td>1303</td><td>3</td><td>—</td><td>—</td><td>8</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1304</td><td>6</td><td>—</td><td>—</td><td>14</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1305</td><td>13</td><td>—</td><td>[10]</td><td>24</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1306</td><td>26</td><td>—</td><td>[10, 11]</td><td>36</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1307</td><td>52</td><td>—</td><td>[10, 11]</td><td>56</td><td>1</td><td>—</td><td>—</td><td>—</td><td>18</td><td>100</td><td>1</td></tr>
<tr><td>1308</td><td>88</td><td>—</td><td>[10, 11]</td><td>88</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1309</td><td>176</td><td>—</td><td>[10, 11]</td><td>132</td><td>1</td><td>—</td><td>—</td><td>10</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1310</td><td>352</td><td>—</td><td>[10, 11]</td><td>202</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1311</td><td>704</td><td>—</td><td>[10, 11]</td><td>318</td><td>1</td><td>1</td><td>318</td><td>100</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1403</td><td>12</td><td>4</td><td>[10, 11]</td><td>12</td><td>1</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>1404</td><td>24</td><td>5</td><td>[10, 11]</td><td>22</td><td>1</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>1</td></tr>
<tr><td>1405</td><td>48</td><td>6</td><td>[10, 11]</td><td>34</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1406</td><td>97</td><td>7</td><td>[10, 11]</td><td>54</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1407</td><td>194</td><td>8</td><td>[10, 11]</td><td>86</td><td>1</td><td>1</td><td>86</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1803</td><td>3</td><td>—</td><td>—</td><td>7</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1804</td><td>6</td><td>—</td><td>—</td><td>13</td><td>—</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1805</td><td>11</td><td>—</td><td>[10]</td><td>21</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1806</td><td>22</td><td>—</td><td>[10, 11]</td><td>32</td><td>1</td><td>—</td><td>—</td><td>—</td><td>10</td><td>100</td><td>—</td></tr>
<tr><td>1807</td><td>43</td><td>—</td><td>[10, 11]</td><td>50</td><td>1</td><td>—</td><td>—</td><td>—</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>1808</td><td>86</td><td>—</td><td>[10, 11]</td><td>79</td><td>1</td><td>—</td><td>—</td><td>—</td><td>26</td><td>100</td><td>1</td></tr>
<tr><td>1809</td><td>171</td><td>—</td><td>[10, 11]</td><td>118</td><td>1</td><td>—</td><td>—</td><td>10</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>1810</td><td>341</td><td>—</td><td>[10, 11]</td><td>180</td><td>1</td><td>—</td><td>—</td><td>50</td><td>36</td><td>100</td><td>1</td></tr>
<tr><td>1811</td><td>682</td><td>—</td><td>[10, 11]</td><td>271</td><td>1</td><td>—</td><td>—</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>1812</td><td>1364</td><td>—</td><td>[10, 11]</td><td>409</td><td>1</td><td>1</td><td>409</td><td>—</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>main_g_artifact_3</td><td>11</td><td>4</td><td>—</td><td>13</td><td>—</td><td>—</td><td>—</td><td>—</td><td>9</td><td>100</td><td>—</td></tr>
<tr><td>main_g_artifact_4</td><td>22</td><td>5</td><td>—</td><td>21</td><td>—</td><td>—</td><td>—</td><td>—</td><td>15</td><td>100</td><td>—</td></tr>
<tr><td>main_g_artifact_5</td><td>43</td><td>6</td><td>—</td><td>32</td><td>1</td><td>—</td><td>—</td><td>10</td><td>21</td><td>100</td><td>1</td></tr>
<tr><td>main_g_artifact_6</td><td>86</td><td>7</td><td>[10, 11]</td><td>50</td><td>1</td><td>—</td><td>—</td><td>50</td><td>31</td><td>100</td><td>1</td></tr>
<tr><td>main_g_artifact_7</td><td>171</td><td>8</td><td>[10, 11]</td><td>79</td><td>1</td><td>—</td><td>—</td><td>100</td><td>41</td><td>100</td><td>1</td></tr>
<tr><td>main_g_artifact_8</td><td>341</td><td>9</td><td>[10, 11]</td><td>118</td><td>1</td><td>2</td><td>118</td><td>100</td><td>51</td><td>100</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/OrderItemConfig_shell.json">完整原记录</a></p></details>

**ChestOrderRandomConfig字段含义：** Type索引内部类型，IsLucky=1行独立选为Lucky配置；UnlockLevel等级门槛，RefreshTime秒，Point批次可创建次数，LuckyTriggerChance为浮点阈值（缺省不抽）；Filters按数组首匹配，Player/DiffSum/MonthPay上下界含端点，First/Second/Third及Dynamic上限控制逐项难度；ItemAmounts是一/二/三项权重，不是产物code权重。

<details><summary>ChestOrderRandomConfig：8条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Filters</th><th>ItemAmounts</th><th>Point</th><th>RefreshTime</th><th>Type</th><th>UnlockLevel</th></tr></thead><tbody>
<tr><td>[{&quot;FirstMax&quot;: 6, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 6, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>5</td><td>3600</td><td>1</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 3, &quot;FirstMin&quot;: 6, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 100, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 0}</td><td>—</td><td>1800</td><td>2</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 35, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 36}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>900</td><td>3</td><td>4</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 50, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 51}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 10, &quot;FirstMin&quot;: 11, &quot;PlayerMin&quot;: 81}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>300</td><td>4</td><td>5</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>1200</td><td>9</td><td>10</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6}]</td><td>—</td><td>—</td><td>3600</td><td>12</td><td>14</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;SecondMin&quot;: 4, &quot;ThirdMin&quot;: 3, &quot;FirstMin&quot;: 5, &quot;SecondMax&quot;: 5}]</td><td>—</td><td>—</td><td>1</td><td>15</td><td>12</td></tr>
<tr><td>[{}]</td><td>—</td><td>—</td><td>1</td><td>16</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/ChestOrderRandomConfig.json">完整原记录</a></p></details>

<details><summary>ChestOrderRandomConfig_hard：8条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Filters</th><th>ItemAmounts</th><th>Point</th><th>RefreshTime</th><th>Type</th><th>UnlockLevel</th></tr></thead><tbody>
<tr><td>[{&quot;FirstMax&quot;: 6, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 6, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>5</td><td>3600</td><td>1</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 3, &quot;FirstMin&quot;: 6, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 100, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 0}</td><td>—</td><td>1800</td><td>2</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 40, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 41}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>900</td><td>3</td><td>4</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 40, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 11, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 41}, {&quot;FirstMax&quot;: 12, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 10, &quot;FirstMin&quot;: 11, &quot;PlayerMin&quot;: 81}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>300</td><td>4</td><td>5</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 40, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 41}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>1200</td><td>9</td><td>10</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6}]</td><td>—</td><td>—</td><td>3600</td><td>12</td><td>14</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;SecondMin&quot;: 4, &quot;ThirdMin&quot;: 3, &quot;FirstMin&quot;: 5, &quot;SecondMax&quot;: 5}]</td><td>—</td><td>—</td><td>1</td><td>15</td><td>12</td></tr>
<tr><td>[{}]</td><td>—</td><td>—</td><td>1</td><td>16</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/ChestOrderRandomConfig_hard.json">完整原记录</a></p></details>

<details><summary>ChestOrderRandomConfig_lessitem：8条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Filters</th><th>ItemAmounts</th><th>Point</th><th>RefreshTime</th><th>Type</th><th>UnlockLevel</th></tr></thead><tbody>
<tr><td>[{&quot;FirstMax&quot;: 6, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 6, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>5</td><td>3600</td><td>1</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 3, &quot;FirstMin&quot;: 6, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 100, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 0}</td><td>—</td><td>1800</td><td>2</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 35, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 36}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>900</td><td>3</td><td>4</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 50, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 51}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 10, &quot;FirstMin&quot;: 11, &quot;PlayerMin&quot;: 81}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>300</td><td>4</td><td>5</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 50, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 50}</td><td>—</td><td>1200</td><td>9</td><td>10</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6}]</td><td>—</td><td>—</td><td>3600</td><td>12</td><td>14</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;SecondMin&quot;: 4, &quot;ThirdMin&quot;: 3, &quot;FirstMin&quot;: 5, &quot;SecondMax&quot;: 5}]</td><td>—</td><td>—</td><td>1</td><td>15</td><td>12</td></tr>
<tr><td>[{}]</td><td>—</td><td>—</td><td>1</td><td>16</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/ChestOrderRandomConfig_lessitem.json">完整原记录</a></p></details>

<details><summary>ChestOrderRandomConfig_lessitem2：8条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Filters</th><th>ItemAmounts</th><th>Point</th><th>RefreshTime</th><th>Type</th><th>UnlockLevel</th></tr></thead><tbody>
<tr><td>[{&quot;FirstMax&quot;: 6, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 6, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>5</td><td>3600</td><td>1</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 3, &quot;FirstMin&quot;: 6, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 100, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 0}</td><td>—</td><td>1800</td><td>2</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 35, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 36}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 10, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>—</td><td>900</td><td>3</td><td>4</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 50, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 51}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 10, &quot;FirstMin&quot;: 11, &quot;PlayerMin&quot;: 81}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>—</td><td>300</td><td>4</td><td>5</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 7, &quot;FirstMin&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>—</td><td>1200</td><td>9</td><td>10</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6}]</td><td>—</td><td>—</td><td>3600</td><td>12</td><td>14</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;SecondMin&quot;: 4, &quot;ThirdMin&quot;: 3, &quot;FirstMin&quot;: 5, &quot;SecondMax&quot;: 5}]</td><td>—</td><td>—</td><td>1</td><td>15</td><td>12</td></tr>
<tr><td>[{}]</td><td>—</td><td>—</td><td>1</td><td>16</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/ChestOrderRandomConfig_lessitem2.json">完整原记录</a></p></details>

<details><summary>ChestOrderRandomConfig_lessitem3：8条记录</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Filters</th><th>ItemAmounts</th><th>Point</th><th>RefreshTime</th><th>Type</th><th>UnlockLevel</th></tr></thead><tbody>
<tr><td>[{&quot;FirstMax&quot;: 6, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 5, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>5</td><td>3600</td><td>1</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 6, &quot;ThirdMax&quot;: 3, &quot;SecondMax&quot;: 3, &quot;FirstMin&quot;: 6, &quot;PlayerMin&quot;: 16}]</td><td>{&quot;OneItemWeight&quot;: 100, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 0}</td><td>—</td><td>1800</td><td>2</td><td>3</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 8, &quot;SecondMin&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 35, &quot;SecondMax&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 8, &quot;SecondMin&quot;: 6, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 9, &quot;SecondMin&quot;: 7, &quot;PlayerMin&quot;: 36}, {&quot;FirstMax&quot;: 10, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 9, &quot;FirstMin&quot;: 10, &quot;SecondMin&quot;: 8, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>—</td><td>900</td><td>3</td><td>4</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 7, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 3}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;PlayerMin&quot;: 8}, {&quot;FirstMax&quot;: 10, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 8, &quot;SecondMin&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 50, &quot;SecondMax&quot;: 8, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 9, &quot;SecondMin&quot;: 6, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 11, &quot;PlayerMax&quot;: 80, &quot;SecondMax&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 10, &quot;SecondMin&quot;: 7, &quot;PlayerMin&quot;: 51}, {&quot;FirstMax&quot;: 11, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 10, &quot;FirstMin&quot;: 11, &quot;SecondMin&quot;: 8, &quot;PlayerMin&quot;: 81}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>—</td><td>300</td><td>4</td><td>5</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 15, &quot;SecondMax&quot;: 6, &quot;FirstMin&quot;: 7, &quot;ThirdMax&quot;: 4}, {&quot;FirstMax&quot;: 8, &quot;PlayerMax&quot;: 29, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;FirstMin&quot;: 8, &quot;SecondMin&quot;: 5, &quot;PlayerMin&quot;: 16}, {&quot;FirstMax&quot;: 9, &quot;PlayerMax&quot;: 60, &quot;SecondMax&quot;: 7, &quot;ThirdMax&quot;: 6, &quot;FirstMin&quot;: 8, &quot;SecondMin&quot;: 6, &quot;PlayerMin&quot;: 30}, {&quot;FirstMax&quot;: 9, &quot;ThirdMax&quot;: 6, &quot;SecondMax&quot;: 8, &quot;FirstMin&quot;: 9, &quot;SecondMin&quot;: 7, &quot;PlayerMin&quot;: 61}]</td><td>{&quot;OneItemWeight&quot;: 35, &quot;ThreeItemsWeight&quot;: 0, &quot;TwoItemsWeight&quot;: 65}</td><td>—</td><td>1200</td><td>9</td><td>10</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 5, &quot;SecondMax&quot;: 5, &quot;FirstMin&quot;: 6}]</td><td>—</td><td>—</td><td>3600</td><td>12</td><td>14</td></tr>
<tr><td>[{&quot;FirstMax&quot;: 7, &quot;ThirdMax&quot;: 4, &quot;SecondMin&quot;: 4, &quot;ThirdMin&quot;: 3, &quot;FirstMin&quot;: 5, &quot;SecondMax&quot;: 5}]</td><td>—</td><td>—</td><td>1</td><td>15</td><td>12</td></tr>
<tr><td>[{}]</td><td>—</td><td>—</td><td>1</td><td>16</td><td>1</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/order-evidence/ChestOrderRandomConfig_lessitem3.json">完整原记录</a></p></details>

## 源码依据

- Board.Model.Order.MainOrderCreatorRandom：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderCreatorRandom.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderCreatorRandom.disassembly.txt)。对应：RepeatWeightDecreaseHelper.DecreaseItemWeight（恢复文本行47）；RepeatWeightDecreaseHelper.MarkSelectedLine（恢复文本行71）；RepeatWeightDecreaseHelper.UpdateMapInfo（恢复文本行80）；RandomOrderHelper.Create（恢复文本行131）；RandomOrderHelper.CreateNormalRandomOrder（恢复文本行325）

- Board.Model.Order.MainOrderModel：[恢复源码](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.lua) · [原始指令](../../../../assets/order-evidence/Board.Model.Order.MainOrderModel.disassembly.txt)

- Common.Utility.Table：[恢复源码](../../../../assets/order-evidence/Common.Utility.Table.lua) · [原始指令](../../../../assets/order-evidence/Common.Utility.Table.disassembly.txt)。对应：Table.ListWeightSelectOne（恢复文本行103）

- Common.Utility.MathUtil：[恢复源码](../../../../assets/order-evidence/Common.Utility.MathUtil.lua) · [原始指令](../../../../assets/order-evidence/Common.Utility.MathUtil.disassembly.txt)


---

## 演示案例

下面分别改变前提，让各条分支实际发生；互斥结果属于不同场景。

### 场景1：先抽三项再保留两项

**完整输入（演示设定）：** 假设随机槽4前三轮完整合法池分别仅203/503/903，各Weight100；无重复链减权和已有需求冲突；ItemAmounts=(50,50,0)，玩家等级档有效，记录抽样顺序。

**按执行顺序代入：** R1/R2/R3均1→203/503/903；项数总100、R4=75→Count2；需求取前2=[203,503]；第三次选链记录仍交UpdateMapInfo保存。

**玩家看到的结果：** 顾客最终只要203和503；903虽然未显示为需求，第三次预选仍实际发生并可影响选择历史。

### 场景2：重复链减权及保存

**完整输入（演示设定）：** 假设本次前三项逐次唯一合法候选203/503/903；每轮基础权重100，三个链均有历史计数2且该候选RepeatWeightDecrease=10，项数池只有Count2权重100，候选顺序已记录。

**按执行顺序代入：** 每轮Weight=100/10=10，R1=1各选对应code；MarkSelectedLine对各已选链置false；CountR=1→2，需求203/503；UpdateMapInfo对三条被选中链均重置3并保存。

**玩家看到的结果：** 顾客只要203和503，但预选过的903链也记为最近选中；三条链的重复权重历史都更新。
