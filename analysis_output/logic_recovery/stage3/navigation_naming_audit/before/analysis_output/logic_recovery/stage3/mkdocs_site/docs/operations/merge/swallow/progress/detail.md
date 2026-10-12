# 吞入、保存与进度通知：具体算法与配置

Swallow遍历info，遇Code相等即Swallowed+=1并break，内部未再次检查<Count；依赖外层CanSwallow。存在重复需求代码时，它可能给第一条已满项继续加数，不能按设计直觉改成优先未满项。

SaveItemProperty(target)→RemoveItem(source)→局部SwallowItem(Source,Target)→BI SwallowItem→遍历所有info，任一Swallowed<Count则canTransform=false→局部ProgressChanged。其后完成才Transform；全局ItemSwallow在变换之后派发。

持久化将每项Code-Swallowed-Count以';'连接；恢复逐项'-'分割、tonumber两计数。需求选定后恢复保存记录，不能重抽需求或清空进度。原版重载仍需实际存档差分验证。

## 对应本地配表

| 字段 | 在本步骤中的含义 |
| --- | --- |
| Swallow_Weight1/2 | 创建目标时两项需求的代码与份额，不是每次吞入的概率 |
| Swallow_Number1/2 | 对应需求总件数；逐个吞入+1 |
| Swallow_AllowTap | 恰为0禁点击/移动，其余包含缺省允许；拖入资格单独检查 |
| Transform_Weight | 完成后的独立加权奖励候选，不扣份额 |

同一文件后缀是可选变体，不代表本次账号全部同时生效。全局require按FileReplace的首个精确file匹配追加后缀，替换装载失败才回退默认；账号实际后缀尚未取得。下表列出此步骤所用字段，下载保留完整原记录。字段缺省以“—”表示，不能当作数值0。

以下包含其它活动棋盘的吞噬配置，表名表明其适用玩法；用于解释共同组件和包内记录，不表示主棋盘本次拖动会加载这些活动表。默认主棋盘表未发现吞噬需求记录，主例的吞噬对照为明确假设。

<details><summary>AdventureItemModelConfig_bandgirl：4条相关记录（原表32条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>adv_bandgirl_baby_1</td><td>[&quot;adv_bandgirl_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_bandgirl_baby_a_f_1-10&quot;]</td></tr>
<tr><td>adv_bandgirl_baby_a_1</td><td>[&quot;adv_bandgirl_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_bandgirl_baby_b_f_1-10&quot;]</td></tr>
<tr><td>adv_bandgirl_baby_b_1</td><td>[&quot;adv_bandgirl_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_bandgirl_baby_c_f_1-10&quot;]</td></tr>
<tr><td>adv_bandgirl_baby_c_1</td><td>[&quot;adv_bandgirl_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_bandgirl_baby_d_1-10&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/AdventureItemModelConfig_bandgirl.json">完整原记录</a></p>
</details>

<details><summary>AdventureItemModelConfig_bandgirl_obs：4条相关记录（原表33条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>adv_bandgirl_baby_1</td><td>[&quot;adv_bandgirl_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_bandgirl_baby_a_f_1-10&quot;]</td></tr>
<tr><td>adv_bandgirl_baby_a_1</td><td>[&quot;adv_bandgirl_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_bandgirl_baby_b_f_1-10&quot;]</td></tr>
<tr><td>adv_bandgirl_baby_b_1</td><td>[&quot;adv_bandgirl_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_bandgirl_baby_c_f_1-10&quot;]</td></tr>
<tr><td>adv_bandgirl_baby_c_1</td><td>[&quot;adv_bandgirl_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_bandgirl_baby_d_1-10&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/AdventureItemModelConfig_bandgirl_obs.json">完整原记录</a></p>
</details>

<details><summary>AdventureItemModelConfig_dogpark：4条相关记录（原表35条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>adv_dogpark_baby_1</td><td>[&quot;adv_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogpark_baby_a_f_1-10&quot;]</td></tr>
<tr><td>adv_dogpark_baby_a_1</td><td>[&quot;adv_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogpark_baby_b_f_1-10&quot;]</td></tr>
<tr><td>adv_dogpark_baby_b_1</td><td>[&quot;adv_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogpark_baby_c_f_1-10&quot;]</td></tr>
<tr><td>adv_dogpark_baby_c_1</td><td>[&quot;adv_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogpark_baby_d_1-10&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/AdventureItemModelConfig_dogpark.json">完整原记录</a></p>
</details>

<details><summary>AdventureItemModelConfig_dogpark_level：4条相关记录（原表34条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>adv_dogpark_baby_1</td><td>[&quot;adv_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogpark_baby_a_f_1-10&quot;]</td></tr>
<tr><td>adv_dogpark_baby_a_1</td><td>[&quot;adv_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogpark_baby_b_f_1-10&quot;]</td></tr>
<tr><td>adv_dogpark_baby_b_1</td><td>[&quot;adv_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogpark_baby_c_f_1-10&quot;]</td></tr>
<tr><td>adv_dogpark_baby_c_1</td><td>[&quot;adv_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogpark_baby_d_1-10&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/AdventureItemModelConfig_dogpark_level.json">完整原记录</a></p>
</details>

<details><summary>AdventureItemModelConfig_dogpark_obs：4条相关记录（原表36条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>adv_dogpark_baby_1</td><td>[&quot;adv_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogpark_baby_a_f_1-10&quot;]</td></tr>
<tr><td>adv_dogpark_baby_a_1</td><td>[&quot;adv_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogpark_baby_b_f_1-10&quot;]</td></tr>
<tr><td>adv_dogpark_baby_b_1</td><td>[&quot;adv_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogpark_baby_c_f_1-10&quot;]</td></tr>
<tr><td>adv_dogpark_baby_c_1</td><td>[&quot;adv_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogpark_baby_d_1-10&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/AdventureItemModelConfig_dogpark_obs.json">完整原记录</a></p>
</details>

<details><summary>AdventureItemModelConfig_dogparkpure：4条相关记录（原表35条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>adv_dogparkpure_baby_1</td><td>[&quot;adv_dogparkpure_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogparkpure_baby_a_f_1-10&quot;]</td></tr>
<tr><td>adv_dogparkpure_baby_a_1</td><td>[&quot;adv_dogparkpure_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogparkpure_baby_b_f_1-10&quot;]</td></tr>
<tr><td>adv_dogparkpure_baby_b_1</td><td>[&quot;adv_dogparkpure_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogparkpure_baby_c_f_1-10&quot;]</td></tr>
<tr><td>adv_dogparkpure_baby_c_1</td><td>[&quot;adv_dogparkpure_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_dogparkpure_baby_d_1-10&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/AdventureItemModelConfig_dogparkpure.json">完整原记录</a></p>
</details>

<details><summary>AdventureItemModelConfig_witch：4条相关记录（原表33条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>adv_witch_baby_1</td><td>[&quot;adv_witch_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_witch_baby_a_f_1-10&quot;]</td></tr>
<tr><td>adv_witch_baby_a_1</td><td>[&quot;adv_witch_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_witch_baby_b_f_1-10&quot;]</td></tr>
<tr><td>adv_witch_baby_b_1</td><td>[&quot;adv_witch_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_witch_baby_c_f_1-10&quot;]</td></tr>
<tr><td>adv_witch_baby_c_1</td><td>[&quot;adv_witch_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;adv_witch_baby_d_1-10&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/AdventureItemModelConfig_witch.json">完整原记录</a></p>
</details>

<details><summary>BreakItemModelConfig_Shopping：36条相关记录（原表320条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>break_shopping_1_swa_e1_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f1_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e2_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f2_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e3_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f3_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e4_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f4_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e5_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f5_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e6_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f6_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e7_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f7_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e8_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f8_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e9_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f9_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e10_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f10_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e11_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f11_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e12_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f12_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e13_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f13_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e14_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f14_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e15_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f15_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e16_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f16_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e17_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f17_1-1&quot;]</td></tr>
<tr><td>break_shopping_1_swa_e18_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_1_swa_f18_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e1_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f1_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e2_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f2_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e3_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f3_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e4_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f4_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e5_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f5_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e6_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f6_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e7_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f7_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e8_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f8_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e9_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f9_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e10_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f10_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e11_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f11_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e12_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f12_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e13_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f13_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e14_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f14_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e15_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f15_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e16_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f16_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e17_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f17_1-1&quot;]</td></tr>
<tr><td>break_shopping_swa_e18_1</td><td>[&quot;break_shopping_feed_6-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>1</td><td>[&quot;break_shopping_swa_f18_1-1&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/BreakItemModelConfig_Shopping.json">完整原记录</a></p>
</details>

<details><summary>Dig2ItemModelConfig：4条相关记录（原表134条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>mineralDig2_locked_gift_1_1</td><td>[&quot;mineralDig2_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig2_locked_gift_2_1-1&quot;]</td></tr>
<tr><td>mineralDig2_locked_gift_3_1</td><td>[&quot;mineralDig2_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig2_locked_gift_4_1-1&quot;]</td></tr>
<tr><td>mineralDig2_locked_gift_5_1</td><td>[&quot;mineralDig2_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig2_locked_gift_6_1-1&quot;]</td></tr>
<tr><td>mineralDig2_locked_gift_7_1</td><td>[&quot;mineralDig2_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig2_locked_gift_8_1-1&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/Dig2ItemModelConfig.json">完整原记录</a></p>
</details>

<details><summary>Dig2ItemModelConfig_superweb：4条相关记录（原表132条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>mineralDig2_locked_gift_1_1</td><td>[&quot;mineralDig2_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig2_locked_gift_2_1-1&quot;]</td></tr>
<tr><td>mineralDig2_locked_gift_3_1</td><td>[&quot;mineralDig2_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig2_locked_gift_4_1-1&quot;]</td></tr>
<tr><td>mineralDig2_locked_gift_5_1</td><td>[&quot;mineralDig2_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig2_locked_gift_6_1-1&quot;]</td></tr>
<tr><td>mineralDig2_locked_gift_7_1</td><td>[&quot;mineralDig2_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig2_locked_gift_8_1-1&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/Dig2ItemModelConfig_superweb.json">完整原记录</a></p>
</details>

<details><summary>Dig2ItemModelConfig_wheel：4条相关记录（原表134条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>mineralDig2_locked_gift_1_1</td><td>[&quot;mineralDig2_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig2_locked_gift_2_1-1&quot;]</td></tr>
<tr><td>mineralDig2_locked_gift_3_1</td><td>[&quot;mineralDig2_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig2_locked_gift_4_1-1&quot;]</td></tr>
<tr><td>mineralDig2_locked_gift_5_1</td><td>[&quot;mineralDig2_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig2_locked_gift_6_1-1&quot;]</td></tr>
<tr><td>mineralDig2_locked_gift_7_1</td><td>[&quot;mineralDig2_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig2_locked_gift_8_1-1&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/Dig2ItemModelConfig_wheel.json">完整原记录</a></p>
</details>

<details><summary>DigItemModelConfig：4条相关记录（原表134条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>mineralDig_locked_gift_1_1</td><td>[&quot;mineralDig_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig_locked_gift_2_1-1&quot;]</td></tr>
<tr><td>mineralDig_locked_gift_3_1</td><td>[&quot;mineralDig_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig_locked_gift_4_1-1&quot;]</td></tr>
<tr><td>mineralDig_locked_gift_5_1</td><td>[&quot;mineralDig_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig_locked_gift_6_1-1&quot;]</td></tr>
<tr><td>mineralDig_locked_gift_7_1</td><td>[&quot;mineralDig_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig_locked_gift_8_1-1&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/DigItemModelConfig.json">完整原记录</a></p>
</details>

<details><summary>DigItemModelConfig_super500：4条相关记录（原表132条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>mineralDig_locked_gift_1_1</td><td>[&quot;mineralDig_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig_locked_gift_2_1-1&quot;]</td></tr>
<tr><td>mineralDig_locked_gift_3_1</td><td>[&quot;mineralDig_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig_locked_gift_4_1-1&quot;]</td></tr>
<tr><td>mineralDig_locked_gift_5_1</td><td>[&quot;mineralDig_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig_locked_gift_6_1-1&quot;]</td></tr>
<tr><td>mineralDig_locked_gift_7_1</td><td>[&quot;mineralDig_key1_1-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;mineralDig_locked_gift_8_1-1&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/DigItemModelConfig_super500.json">完整原记录</a></p>
</details>

<details><summary>PureboardItemModelConfig_dogpark：4条相关记录（原表35条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>pb_dogpark_baby_1</td><td>[&quot;pb_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;pb_dogpark_baby_a_f_1-10&quot;]</td></tr>
<tr><td>pb_dogpark_baby_a_1</td><td>[&quot;pb_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;pb_dogpark_baby_b_f_1-10&quot;]</td></tr>
<tr><td>pb_dogpark_baby_b_1</td><td>[&quot;pb_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;pb_dogpark_baby_c_f_1-10&quot;]</td></tr>
<tr><td>pb_dogpark_baby_c_1</td><td>[&quot;pb_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;pb_dogpark_baby_d_1-10&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/PureboardItemModelConfig_dogpark.json">完整原记录</a></p>
</details>

<details><summary>PureboardItemModelConfig_dogpark_cloud2：4条相关记录（原表35条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>pb_dogpark_baby_1</td><td>[&quot;pb_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;pb_dogpark_baby_a_f_1-10&quot;]</td></tr>
<tr><td>pb_dogpark_baby_a_1</td><td>[&quot;pb_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;pb_dogpark_baby_b_f_1-10&quot;]</td></tr>
<tr><td>pb_dogpark_baby_b_1</td><td>[&quot;pb_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;pb_dogpark_baby_c_f_1-10&quot;]</td></tr>
<tr><td>pb_dogpark_baby_c_1</td><td>[&quot;pb_dogpark_feed_1-10&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;pb_dogpark_baby_d_1-10&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/PureboardItemModelConfig_dogpark_cloud2.json">完整原记录</a></p>
</details>

<details><summary>StickerboardItemModelConfig_winter：2条相关记录（原表116条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>Type</th><th>Swallow_Weight1</th><th>Swallow_Number1</th><th>Swallow_Weight2</th><th>Swallow_Number2</th><th>Swallow_AllowTap</th><th>Transform_Weight</th></tr></thead><tbody>
<tr><td>stickerboard_winter_locked_portal_1</td><td>[&quot;stickerboard_winter_key_4-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;stickerboard_winter_open_portal_1-1&quot;]</td></tr>
<tr><td>stickerboard_winter_locked_mine_1</td><td>[&quot;stickerboard_winter_key_4-1&quot;]</td><td>1</td><td>—</td><td>—</td><td>—</td><td>[&quot;stickerboard_winter_mine_endless_001-1&quot;]</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/StickerboardItemModelConfig_winter.json">完整原记录</a></p>
</details>

## 源码依据

- Board.Model.Item.ItemSwallow：[恢复源码](../../../../assets/merge-evidence/Board.Model.Item.ItemSwallow.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Item.ItemSwallow.disassembly.txt)
- Board.Model.Board.BaseActionBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseActionBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseActionBoardModel.disassembly.txt)

---

## 演示案例

本例设定本机制所需条件，演示它实际触发后的结果。

### 场景1：吞入第一件但尚未完成

**完整输入（演示设定）：** 未另给坐标时，棋盘7×9、源S=(3,3)、目标T=(4,3)。目标需求201×2、已吞0，源201在S；两者不能普通合成，目标有Swallow组件。

**按执行顺序代入：** 首匹配Code201：Swallowed0+1=1<Count2；保存Swallowed=1，删除源，派吞噬进度通知；完成检查false。

**玩家看到的结果：** 201消失，目标从0/2变1/2，还需一件201；本次没有奖励变换，也不交换。
