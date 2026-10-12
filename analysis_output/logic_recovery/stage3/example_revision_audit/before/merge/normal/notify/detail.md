# 合成通知与四邻格震动：具体算法与配置

message含Source/Target/New/itemType/isFirstUnlock。局部BoardEventType.MergeItem先于全局ItemMerged；PairEvent按注册数组从1到#handlers同步执行。随后ShockNeighborItems(T)按dir1..4，偏移(1,0)、(0,1)、(−1,0)、(0,−1)，读取当时邻格对象并DispatchComponentEvent(OnShock)；再全局ItemShocked。不是八邻格，也不递归震动所有棋子。

ItemPaperBox.OnShock仅not IsItemPaperBoxLocked才CollapseItem(position)；Try2Unlock的等级解锁路径还要求UnlockLevel>0。Collapse将内含物替换到原格，局部CollapseItem与全局PaperboxDisappear等通知在自身调用内发生。带蜘蛛网的纸箱内含编码由Factory决定，消箱不一定得到裸普通物。

ItemMerged消费者可包括卡片链、教程、解锁表现和活动；必须按各自注册及资格判断，不能认为所有订阅都无条件加分。主棋盘ScoreRace的直接计分在下一个调用位置，不是上述通知自动等价完成。

## ItemMerged通知内的同步响应

这些响应由订阅与资格决定，不是每次合成都全部生效，也没有源码保证以下活动之间的固定注册顺序。普通合成、升级和两剪刀都发送ItemMerged，故监听需按Source/New及自身条件区分，不能把它们都当普通合成副产物。

| 消费者 | 读取什么、何时处理 | 已确认的本地规则 |
| --- | --- | --- |
| Avenue、Road、Exped、Upward、FloatRace | Source属于主棋盘，CanAddScore通过，按Source.Type读MergeItemScoreConfig | 取merge_score，非nil才交给各活动加分 |
| Battle、Team | 主棋盘Source且活动允许加分 | 取merge_score_race；Team在监听直接读表，Battle在helper内读 |
| Combo | 主棋盘，活动Started；任务Doing或自己未达目标且无网络 | 按Source.Type取merge_score，加连击代币 |
| Pass | 不在入口额外过滤棋盘，处理New.Code与固定目标merge各1次 | 活动Started；非Super票且已到最后配置等级时不再加任务；遍历活动任务，Target一致才增加 |
| CardItem | 活动Started且New.Type为最高级卡片 | 未标记已展示则保存链提示标志，派CardItemFirstPopWindow，不再抽一张卡 |
| Farmboard | 活动Started，New.Type在Item等级表 | 找匹配等级，严格高于当前等级才保存、尝试解雾并通知；入口未额外检查Source主棋盘 |
| GeneratorFactory | 服务器开关开启，尚未全部解锁，New.Type在工厂母体集合 | 重新计算开启状态；从关闭转开启会CheckCobweb，再发状态通知与刷新仓库红点 |
| TaskEventProgressGainModule | 读取New并逐个调用已注册且conditionFunction通过的任务模型 | 发ItemMerge+1和Item+1；New链等级恰为3..10时额外发对应ItemMergeN+1及Source.BoardType，超范围无这条额外类型 |
| TutorialOrderModel | 当前教程订单Doing、UnlockItem=Fishing05、新物RawFish05、海鲜第二教程未完成 | 标记待开始并派TutorialStartPop |
| SDKHelper | 日期按服务器时间转YMD，按本地计数处理 | 新日期清零；每5次合成发一次支付宝行为，日上传次数上限40，即最多200次合成对应40次行为；不足5次的运行内余数与持久化上传计数不同 |
| GooglePgsManager | 合成通知入口调用RecordGameStatsMerge | 平台统计不改棋盘结果；平台可用性由平台服务控制 |

TaskEventProgressGainModule默认operation=Add；BubbleSpread监听则为Bubble、operation=Update、num=1。动态注册任务模型的具体任务条件、目标量和奖励仍由各自活动配置决定，不能把注册器当成统一奖励算法。事件响应需要继续追到各活动存档/奖励边界，表格描述的是已核实的入口与直接规则，不把尚未取得的远端档位当已知值。


## 对应本地配表

| 字段 | 在本步骤中的含义 |
| --- | --- |
| item_id | 以Source.Type索引的输入棋子 |
| merge_score | Avenue/Road/Exped/Upward/FloatRace/Combo等读取的分数 |
| merge_score_race | 竞速、Battle、Team读取的分数；缺省跳过 |
| bubble_score / shop_score | 本表的其它字段；不是本次合成加分，不能合计进merge分数 |

同一文件后缀是可选变体，不代表本次账号全部同时生效。全局require按FileReplace的首个精确file匹配追加后缀，替换装载失败才回退默认；账号实际后缀尚未取得。下表列出此步骤所用字段，下载保留完整原记录。字段缺省以“—”表示，不能当作数值0。

<details><summary>MergeItemScoreConfig：159条相关记录（原表159条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>item_id</th><th>merge_score_race</th><th>bubble_score</th><th>shop_score</th></tr></thead><tbody>
<tr><td>101</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>401</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>701</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>1001</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>1201</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>1701</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>203</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>204</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>205</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>206</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>207</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>208</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>209</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>210</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>211</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>212</td><td>3</td><td>11</td><td>11</td></tr>
<tr><td>213</td><td>4</td><td>12</td><td>12</td></tr>
<tr><td>214</td><td>4</td><td>13</td><td>13</td></tr>
<tr><td>215</td><td>—</td><td>14</td><td>14</td></tr>
<tr><td>301</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>302</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>303</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>304</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>305</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>306</td><td>3</td><td>7</td><td>7</td></tr>
<tr><td>307</td><td>—</td><td>8</td><td>8</td></tr>
<tr><td>503</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>504</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>505</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>506</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>507</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>508</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>509</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>510</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>511</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>512</td><td>3</td><td>11</td><td>11</td></tr>
<tr><td>513</td><td>4</td><td>12</td><td>12</td></tr>
<tr><td>514</td><td>—</td><td>13</td><td>13</td></tr>
<tr><td>601</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>602</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>603</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>604</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>605</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>606</td><td>3</td><td>7</td><td>7</td></tr>
<tr><td>607</td><td>—</td><td>8</td><td>8</td></tr>
<tr><td>801</td><td>—</td><td>1</td><td>1</td></tr>
<tr><td>802</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>803</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>804</td><td>2</td><td>4</td><td>4</td></tr>
<tr><td>805</td><td>—</td><td>5</td><td>5</td></tr>
<tr><td>901</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>902</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>903</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>904</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>905</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>906</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>907</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>908</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>909</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>910</td><td>—</td><td>11</td><td>11</td></tr>
<tr><td>1101</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>1102</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1103</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1104</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>1105</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1106</td><td>3</td><td>7</td><td>7</td></tr>
<tr><td>1107</td><td>—</td><td>8</td><td>8</td></tr>
<tr><td>1302</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>1303</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1304</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1305</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>1306</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1307</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>1308</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>1309</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>1310</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>1311</td><td>—</td><td>11</td><td>11</td></tr>
<tr><td>1401</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1402</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1403</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>1404</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1405</td><td>3</td><td>7</td><td>7</td></tr>
<tr><td>1406</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>1407</td><td>—</td><td>9</td><td>9</td></tr>
<tr><td>1801</td><td>—</td><td>1</td><td>1</td></tr>
<tr><td>1802</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>1803</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1804</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1805</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>1806</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1807</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>1808</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>1809</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>1810</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>1811</td><td>3</td><td>11</td><td>11</td></tr>
<tr><td>1812</td><td>—</td><td>12</td><td>12</td></tr>
<tr><td>1602</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>1603</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1604</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1605</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>1606</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1607</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>1608</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>1609</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>1610</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>2002</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>2003</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>2004</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>2005</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>2006</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>2007</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>2008</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>2009</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>2010</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>sp3_2_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp3_2_3</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp3_2_4</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp3_2_5</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp3_2_6</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp3_2_7</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>sp3_2_8</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>sp3_2_9</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>sp3_2_10</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>sp3_3_1</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp3_3_2</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp3_3_3</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp3_3_4</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp3_3_5</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp3_3_6</td><td>—</td><td>7</td><td>7</td></tr>
<tr><td>sp4_2_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp4_2_3</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp4_2_4</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp4_3_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp4_3_3</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp4_3_4</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp4_3_5</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp4_3_6</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp4_3_7</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>sp4_3_8</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>sp4_3_9</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>sp4_3_10</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>sp5_2_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp5_2_3</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp5_2_4</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp5_2_5</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp5_2_6</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp5_2_7</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>sp5_2_8</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>sp5_2_9</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>sp5_2_10</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>sp6_2_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp6_2_3</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp6_2_4</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp6_2_5</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp6_2_6</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp6_2_7</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>sp6_2_8</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>sp6_2_9</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>sp6_2_10</td><td>—</td><td>10</td><td>10</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/MergeItemScoreConfig.json">完整原记录</a></p>
</details>

<details><summary>MergeItemScoreConfig_extracust：161条相关记录（原表161条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>item_id</th><th>merge_score_race</th><th>bubble_score</th><th>shop_score</th></tr></thead><tbody>
<tr><td>101</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>401</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>701</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>1001</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>1201</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>1701</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>203</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>204</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>205</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>206</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>207</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>208</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>209</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>210</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>211</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>212</td><td>3</td><td>11</td><td>11</td></tr>
<tr><td>213</td><td>4</td><td>12</td><td>12</td></tr>
<tr><td>214</td><td>4</td><td>13</td><td>13</td></tr>
<tr><td>215</td><td>—</td><td>14</td><td>14</td></tr>
<tr><td>301</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>302</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>303</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>304</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>305</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>306</td><td>3</td><td>7</td><td>7</td></tr>
<tr><td>307</td><td>—</td><td>8</td><td>8</td></tr>
<tr><td>503</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>504</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>505</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>506</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>507</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>508</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>509</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>510</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>511</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>512</td><td>3</td><td>11</td><td>11</td></tr>
<tr><td>513</td><td>4</td><td>12</td><td>12</td></tr>
<tr><td>514</td><td>—</td><td>13</td><td>13</td></tr>
<tr><td>601</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>602</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>603</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>604</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>605</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>606</td><td>3</td><td>7</td><td>7</td></tr>
<tr><td>607</td><td>—</td><td>8</td><td>8</td></tr>
<tr><td>801</td><td>—</td><td>1</td><td>1</td></tr>
<tr><td>802</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>803</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>804</td><td>2</td><td>4</td><td>4</td></tr>
<tr><td>805</td><td>—</td><td>5</td><td>5</td></tr>
<tr><td>901</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>902</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>903</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>904</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>905</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>906</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>907</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>908</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>909</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>910</td><td>5</td><td>11</td><td>11</td></tr>
<tr><td>911</td><td>—</td><td>12</td><td>12</td></tr>
<tr><td>1101</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>1102</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1103</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1104</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>1105</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1106</td><td>3</td><td>7</td><td>7</td></tr>
<tr><td>1107</td><td>—</td><td>8</td><td>8</td></tr>
<tr><td>1302</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>1303</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1304</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1305</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>1306</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1307</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>1308</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>1309</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>1310</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>1311</td><td>5</td><td>11</td><td>11</td></tr>
<tr><td>1312</td><td>—</td><td>12</td><td>12</td></tr>
<tr><td>1401</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1402</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1403</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>1404</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1405</td><td>3</td><td>7</td><td>7</td></tr>
<tr><td>1406</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>1407</td><td>—</td><td>9</td><td>9</td></tr>
<tr><td>1801</td><td>—</td><td>1</td><td>1</td></tr>
<tr><td>1802</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>1803</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1804</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1805</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>1806</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1807</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>1808</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>1809</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>1810</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>1811</td><td>3</td><td>11</td><td>11</td></tr>
<tr><td>1812</td><td>—</td><td>12</td><td>12</td></tr>
<tr><td>1602</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>1603</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1604</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1605</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>1606</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1607</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>1608</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>1609</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>1610</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>2002</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>2003</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>2004</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>2005</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>2006</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>2007</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>2008</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>2009</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>2010</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>sp3_2_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp3_2_3</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp3_2_4</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp3_2_5</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp3_2_6</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp3_2_7</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>sp3_2_8</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>sp3_2_9</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>sp3_2_10</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>sp3_3_1</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp3_3_2</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp3_3_3</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp3_3_4</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp3_3_5</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp3_3_6</td><td>—</td><td>7</td><td>7</td></tr>
<tr><td>sp4_2_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp4_2_3</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp4_2_4</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp4_3_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp4_3_3</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp4_3_4</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp4_3_5</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp4_3_6</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp4_3_7</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>sp4_3_8</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>sp4_3_9</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>sp4_3_10</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>sp5_2_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp5_2_3</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp5_2_4</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp5_2_5</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp5_2_6</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp5_2_7</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>sp5_2_8</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>sp5_2_9</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>sp5_2_10</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>sp6_2_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp6_2_3</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp6_2_4</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp6_2_5</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp6_2_6</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp6_2_7</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>sp6_2_8</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>sp6_2_9</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>sp6_2_10</td><td>—</td><td>10</td><td>10</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/MergeItemScoreConfig_extracust.json">完整原记录</a></p>
</details>

<details><summary>MergeItemScoreConfig_shell：166条相关记录（原表166条）</summary>
<div class="config-block"><div class="config-controls"><input type="search" aria-label="筛选配置" placeholder="按棋子代码或字段值筛选"><span class="config-count"></span></div><div class="config-scroll"><table class="config-table"><thead><tr><th>item_id</th><th>merge_score_race</th><th>bubble_score</th><th>shop_score</th></tr></thead><tbody>
<tr><td>101</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>401</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>701</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>1001</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>1201</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>1701</td><td>—</td><td>2</td><td>5</td></tr>
<tr><td>203</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>204</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>205</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>206</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>207</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>208</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>209</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>210</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>211</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>212</td><td>3</td><td>11</td><td>11</td></tr>
<tr><td>213</td><td>4</td><td>12</td><td>12</td></tr>
<tr><td>214</td><td>4</td><td>13</td><td>13</td></tr>
<tr><td>215</td><td>—</td><td>14</td><td>14</td></tr>
<tr><td>301</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>302</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>303</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>304</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>305</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>306</td><td>3</td><td>7</td><td>7</td></tr>
<tr><td>307</td><td>—</td><td>8</td><td>8</td></tr>
<tr><td>503</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>504</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>505</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>506</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>507</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>508</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>509</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>510</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>511</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>512</td><td>3</td><td>11</td><td>11</td></tr>
<tr><td>513</td><td>4</td><td>12</td><td>12</td></tr>
<tr><td>514</td><td>—</td><td>13</td><td>13</td></tr>
<tr><td>601</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>602</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>603</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>604</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>605</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>606</td><td>3</td><td>7</td><td>7</td></tr>
<tr><td>607</td><td>—</td><td>8</td><td>8</td></tr>
<tr><td>801</td><td>—</td><td>1</td><td>1</td></tr>
<tr><td>802</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>803</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>804</td><td>2</td><td>4</td><td>4</td></tr>
<tr><td>805</td><td>—</td><td>5</td><td>5</td></tr>
<tr><td>901</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>902</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>903</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>904</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>905</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>906</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>907</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>908</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>909</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>910</td><td>—</td><td>11</td><td>11</td></tr>
<tr><td>1101</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>1102</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1103</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1104</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>1105</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1106</td><td>3</td><td>7</td><td>7</td></tr>
<tr><td>1107</td><td>—</td><td>8</td><td>8</td></tr>
<tr><td>1302</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>1303</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1304</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1305</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>1306</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1307</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>1308</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>1309</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>1310</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>1311</td><td>—</td><td>11</td><td>11</td></tr>
<tr><td>1401</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1402</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1403</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>1404</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1405</td><td>3</td><td>7</td><td>7</td></tr>
<tr><td>1406</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>1407</td><td>—</td><td>9</td><td>9</td></tr>
<tr><td>1801</td><td>—</td><td>1</td><td>1</td></tr>
<tr><td>1802</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>1803</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1804</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1805</td><td>1</td><td>5</td><td>5</td></tr>
<tr><td>1806</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1807</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>1808</td><td>2</td><td>8</td><td>8</td></tr>
<tr><td>1809</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>1810</td><td>3</td><td>10</td><td>10</td></tr>
<tr><td>1811</td><td>3</td><td>11</td><td>11</td></tr>
<tr><td>1812</td><td>—</td><td>12</td><td>12</td></tr>
<tr><td>1602</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>1603</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>1604</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>1605</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>1606</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>1607</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>1608</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>1609</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>1610</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>2002</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>2003</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>2004</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>2005</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>2006</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>2007</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>2008</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>2009</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>2010</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>sp3_2_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp3_2_3</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp3_2_4</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp3_2_5</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp3_2_6</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp3_2_7</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>sp3_2_8</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>sp3_2_9</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>sp3_2_10</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>sp3_3_1</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp3_3_2</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp3_3_3</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp3_3_4</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp3_3_5</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp3_3_6</td><td>—</td><td>7</td><td>7</td></tr>
<tr><td>sp4_2_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp4_2_3</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp4_2_4</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp4_3_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp4_3_3</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp4_3_4</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp4_3_5</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp4_3_6</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp4_3_7</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>sp4_3_8</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>sp4_3_9</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>sp4_3_10</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>sp5_2_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp5_2_3</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp5_2_4</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp5_2_5</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp5_2_6</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp5_2_7</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>sp5_2_8</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>sp5_2_9</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>sp5_2_10</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>sp6_2_2</td><td>—</td><td>2</td><td>2</td></tr>
<tr><td>sp6_2_3</td><td>1</td><td>3</td><td>3</td></tr>
<tr><td>sp6_2_4</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>sp6_2_5</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>sp6_2_6</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>sp6_2_7</td><td>2</td><td>7</td><td>7</td></tr>
<tr><td>sp6_2_8</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>sp6_2_9</td><td>3</td><td>9</td><td>9</td></tr>
<tr><td>sp6_2_10</td><td>—</td><td>10</td><td>10</td></tr>
<tr><td>main_g_artifact_2</td><td>1</td><td>4</td><td>4</td></tr>
<tr><td>main_g_artifact_3</td><td>2</td><td>5</td><td>5</td></tr>
<tr><td>main_g_artifact_4</td><td>2</td><td>6</td><td>6</td></tr>
<tr><td>main_g_artifact_5</td><td>3</td><td>7</td><td>7</td></tr>
<tr><td>main_g_artifact_6</td><td>3</td><td>8</td><td>8</td></tr>
<tr><td>main_g_artifact_7</td><td>4</td><td>9</td><td>9</td></tr>
<tr><td>main_g_artifact_8</td><td>—</td><td>10</td><td>10</td></tr>
</tbody></table></div></div>
<p><a href="../../../../../assets/merge-evidence/MergeItemScoreConfig_shell.json">完整原记录</a></p>
</details>

## 源码依据

- Board.Model.Board.BaseBoardModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.BaseBoardModel.disassembly.txt)
- Board.Model.Item.ItemPaperBox：[恢复源码](../../../../assets/merge-evidence/Board.Model.Item.ItemPaperBox.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Item.ItemPaperBox.disassembly.txt)
- Common.Event.PairEvent：[恢复源码](../../../../assets/merge-evidence/Common.Event.PairEvent.lua) · [原指令与源码行](../../../../assets/merge-evidence/Common.Event.PairEvent.disassembly.txt)
- Board.View.MainBoardView：[恢复源码](../../../../assets/merge-evidence/Board.View.MainBoardView.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.View.MainBoardView.disassembly.txt)
- Avenue.Model.AvenueModel：[恢复源码](../../../../assets/merge-evidence/Avenue.Model.AvenueModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Avenue.Model.AvenueModel.disassembly.txt)
- Road.Model.RoadModel：[恢复源码](../../../../assets/merge-evidence/Road.Model.RoadModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Road.Model.RoadModel.disassembly.txt)
- ExpedActivity.Model.ExpedModel：[恢复源码](../../../../assets/merge-evidence/ExpedActivity.Model.ExpedModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/ExpedActivity.Model.ExpedModel.disassembly.txt)
- Upward.Model.UpwardModel：[恢复源码](../../../../assets/merge-evidence/Upward.Model.UpwardModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Upward.Model.UpwardModel.disassembly.txt)
- FloatRace.Model.FloatRaceModel：[恢复源码](../../../../assets/merge-evidence/FloatRace.Model.FloatRaceModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/FloatRace.Model.FloatRaceModel.disassembly.txt)
- BattleActivity.Model.BattleActivityModel：[恢复源码](../../../../assets/merge-evidence/BattleActivity.Model.BattleActivityModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/BattleActivity.Model.BattleActivityModel.disassembly.txt)
- TeamActivity.Model.TeamActivityModel：[恢复源码](../../../../assets/merge-evidence/TeamActivity.Model.TeamActivityModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/TeamActivity.Model.TeamActivityModel.disassembly.txt)
- ComboActivity.Model.ComboActivityModel：[恢复源码](../../../../assets/merge-evidence/ComboActivity.Model.ComboActivityModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/ComboActivity.Model.ComboActivityModel.disassembly.txt)
- PassActivity.Model.PassActivityModel：[恢复源码](../../../../assets/merge-evidence/PassActivity.Model.PassActivityModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/PassActivity.Model.PassActivityModel.disassembly.txt)
- CardItem.CardItemModel：[恢复源码](../../../../assets/merge-evidence/CardItem.CardItemModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/CardItem.CardItemModel.disassembly.txt)
- FarmboardActivity.Model.FarmboardActivityModel：[恢复源码](../../../../assets/merge-evidence/FarmboardActivity.Model.FarmboardActivityModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/FarmboardActivity.Model.FarmboardActivityModel.disassembly.txt)
- Board.Model.Board.ItemGeneratorFactoryModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Board.ItemGeneratorFactoryModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Board.ItemGeneratorFactoryModel.disassembly.txt)
- Model.Activity.ActivityModule.TaskEventProgressGainModule：[恢复源码](../../../../assets/merge-evidence/Model.Activity.ActivityModule.TaskEventProgressGainModule.lua) · [原指令与源码行](../../../../assets/merge-evidence/Model.Activity.ActivityModule.TaskEventProgressGainModule.disassembly.txt)
- Board.Model.Order.TutorialOrderModel：[恢复源码](../../../../assets/merge-evidence/Board.Model.Order.TutorialOrderModel.lua) · [原指令与源码行](../../../../assets/merge-evidence/Board.Model.Order.TutorialOrderModel.disassembly.txt)
- Common.Platform.SDKHelper：[恢复源码](../../../../assets/merge-evidence/Common.Platform.SDKHelper.lua) · [原指令与源码行](../../../../assets/merge-evidence/Common.Platform.SDKHelper.disassembly.txt)
- Model.GooglePgsManager：[恢复源码](../../../../assets/merge-evidence/Model.GooglePgsManager.lua) · [原指令与源码行](../../../../assets/merge-evidence/Model.GooglePgsManager.disassembly.txt)

---

## 贯穿案例：两个201合成202



本例四邻格无纸箱，仍发送合成与震动通知，没有新增空位。对照邻格有已解锁纸箱时先消箱，再检查副产物。

### 代入本页的值

T=(4,3)，检查(5,3)、(4,4)、(3,3)、(4,2)；S=(3,3)已被删除，因此该邻格无OnShock。顺序MergeItem→ItemMerged→四邻OnShock→ItemShocked。

<details><summary>案例共同前提</summary>

本地默认配表：201.MergedType=202，202.MergedType=203、BubbleChance=0。演示输入：源S=(3,3)、目标T=(4,3)，两边为不同对象的普通201；棋盘7×9，其它格占用且无邻格障碍；没有教程落点限制、仓库存入或最近高亮吸附；竞速、临时物、卡片、能量气泡活动不生效；测试强制气泡关闭。能量余额10，金币门槛采用本地默认8。

本例不需要抽普通产物池，不扣点击能量。各页面的“对照”会明确改变前提，属于另一条路径；假设倍率、时间、权重与随机值只用于推演，不冒充远端配置。

</details>
