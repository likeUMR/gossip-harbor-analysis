"""Pin generator state save/restore specifications in existing execution nodes."""
import json,shutil
from reconcile_generator_logic import ROOT,OUT,DOCS,sha
SOURCES={
 'ItemManager':'373ce1d8ad86d04bc53d5a305c26f66bae571df054285890fc7bf2e88c9b911b',
 'ItemModelFactory':'6f396c8440b2e8701b86962bde4e8b920e62437ce0567bd65823b3edc3f71e54',
 'ItemUtility':'178ef2202c33886134428e8dc40c86f0f6a348fc4176f6492c06de352192b16d',
 'StringUtil':'12944227f29b3c06a503b4af56d23950a964e0552c8ee746de5db7f419bbf7bf',
 'DBTable':'3805da595fff579e334b1d3147c735ca4df8a1d1429b82dcb9a05d321ec5e6d7',
 'ItemSchema':'2039d9cc5171967af7243f73d9b6ccebc893678c0a9e4a66140ef17e0ab5c703',
 'BaseActionBoardModel':'b01cc1db109fdfdb7b0c2e89a65d58fbc44b23e2a459742ef77a2f64480d82e3',
}
FIELDS=[('m_state','spreadState','当前开启阶段'),('m_startTimer','spreadStartTimer','当前恢复阶段起点；nil表示没有计时'),('m_itemRestNumber','spreadItemRestNumber','可用次数'),('m_storageRestNumber','spreadStorageRestNumber','储备次数'),('m_spreadCount','spreadCount','累计产出计数；读取缺省0'),('m_codeWeightPairs','spreadCodeWeightPairs','当前剩余产出池，按原顺序编码')]
BODIES={
 'state/model/detail.md':'''## 存档如何恢复当前母体

主棋盘继承 BaseActionBoardModel；`SaveItemProperty` 调用 ItemManager:SetItem，不是 BaseBoardModel 的空实现。同步数据结束时，ItemManager 逐行读取 Item 表，经 ItemModelFactory.CreateWithData 重建母体。先 CreateWithCode 按当前配置创建对象和组件，再覆盖存档状态；不是只保存类型，重新登录就补满次数。

| 实例字段 | 存档列 | 恢复方法 |
| --- | --- | --- |
| m_state | spreadState | 原样覆盖；无默认状态替代 |
| m_startTimer | spreadStartTimer | 原样覆盖；缺字段成为nil |
| m_itemRestNumber | spreadItemRestNumber | 原样覆盖，不自动补满 |
| m_storageRestNumber | spreadStorageRestNumber | 原样覆盖，不自动补满 |
| m_spreadCount | spreadCount | 缺值才用0 |
| m_codeWeightPairs | spreadCodeWeightPairs | 解析存档字符串，覆盖配置初始池 |

如果按代码创建对象失败，工厂返回nil；ItemManager记ItemNotFound并删除该存档行。主棋盘成功恢复后标记棋子类型已解锁。恢复函数本身没有重新推进冷却；时间推进由随后UpdatePerSecond处理。当前配置的上限、时长和权重模式仍来自创建过程，存档只恢复上表的运行值。
''',
 'lifecycle/cooldown/detail.md':'''## 冷却起点怎样保存、清除和恢复

每次 SaveItemProperty 都重填该棋子的整组运行字段。ItemManager:SetItem先批量写字段，再检查本次spreadStartTimer是否为nil；若为nil，显式Remove(id,"spreadStartTimer")。Lua的pairs不会遍历nil字段，若只做批量更新，旧计时起点会残留，因此不能省略这条删除。没有计时的母体不是起点0，也不能将原有时间继续保留。

DBTable批量写入会更新内存缓存，并将数据同步标记设false、缓存变化标记设true；非JSON模式另外排队数据库命令。Remove成功后同样标记变化，并在非JSON模式排队删行或单列更新。这里是请求保存与缓存变化，不能解释成此刻已经完成原生磁盘提交或服务器确认。

重载时spreadStartTimer原样回写实例。恢复进度用当前服务器时间减保存的起点，当前配置决定阶段时长；不把重新登录的时间作为新的起点。有起点且加速生效时，先修正起点并保存；到期再恢复并保存。无起点分支新建计时后立即返回，所以第一次调用只开始计时，不在同一次调用里检查它是否已完成。

### 保存与恢复的具体例子

假设食品袋105当前Opened、次数0、储备10、起点1000，存档对应spreadState=3、spreadItemRestNumber=0、spreadStorageRestNumber=10、spreadStartTimer=1000。1030重载后仍是这组值；UpdatePerSecond按30秒单轮恢复补到80次，储备截为0，起点推进到1030。1090储备恢复结束，次数80、储备240，起点nil；SetItem显式移除spreadStartTimer列。再次重载时起点为nil，不会重复执行旧冷却。
''',
 'lifecycle/count/detail.md':'''## 次数与剩余权重池怎样跨重载保留

ItemManager:_FillDBTable用getter读取实际次数、储备和累计产出计数，同时把当前池编码成`Code-Weight;Code-Weight`。例如剩余池201×2、202×1保存为`201-2;202-1`；顺序保留。StringToCodeWeightPairs先按分号切分，再由GetCodeAndWeightPairs按连字符拆Code与Weight，Weight用tonumber转数值；空串或nil经StringUtil.Split得到空列表。解析器没有自动补齐到初始权重，也没有检查负权重或自动修复格式。

CreateWithData在配置创建之后覆盖这个池。因此Decremental的已抽份额不会因重载恢复；Fixed池也保存当前实例值，不能在恢复时统一改回配表。已耗尽空池保存为空串，读取仍为空池。首次创建与存档恢复是两个不同路径。

### 剩余池恢复的具体例子

假设一次性Decremental母体初始池201×2、202×1，已抽出一个201；当前次数2、累计产出1、剩余池201×1和202×1。保存spreadItemRestNumber=2、spreadCount=1、spreadCodeWeightPairs="201-1;202-1"。重载按同一类型创建后，这些存档值覆盖初始3次与3份池；玩家仍只有2次产出机会，不能重新获得已抽走的201。池耗尽后保存空串，再次读取为空列表。
''',
}
def main():
 OUT.mkdir(parents=True,exist_ok=True)
 for rel,body in BODIES.items():
  p=DOCS/'operations/generator'/rel;text=p.read_text(encoding='utf-8')
  start='<!-- reconciliation-persistence:start -->';end='<!-- reconciliation-persistence:end -->'
  if start in text:continue
  backup=OUT/'before_persistence'/rel;backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,backup)
  marker='---\n'
  assert marker in text
  text=text.replace(marker,start+'\n'+body+'\n'+end+'\n\n'+marker,1);p.write_text(text,encoding='utf-8')
 evidence=[]
 for module,h in SOURCES.items():
  p=ROOT/'analysis_data/logic_index/lua/decoded'/h/'decompiled.lua'
  evidence.append({'module':module,'source':p.relative_to(ROOT).as_posix(),'sha256':sha(p)})
 result={'state_columns':[{'field':f,'column':c,'meaning':m} for f,c,m in FIELDS],'sources':evidence,'documents':[{'page':'operations/generator/'+r,'sha256':sha(DOCS/'operations/generator'/r)} for r in BODIES],'explained_edges':['MainBoardModel inheritance→BaseActionBoardModel.SaveItemProperty→ItemManager.SetItem→_FillDBTable→DBTable.BatchSet/Remove','ItemManager.OnSyncDataFinished→ItemModelFactory.CreateWithData→configured creation then saved field override','ItemUtility encode→StringUtil split→ItemModelFactory.GetCodeAndWeightPairs'], 'open_edges':['DBTable serialization, SQL queues, native commit and sync ingestion','ItemModelFactory creation components, configuration reload and repair','All timer/state event consumers and ItemAccelerateTime lifecycle','Initialization/update scheduling and authoritative server-time lifecycle'], 'scope':'Lua field save/restore contract, not complete native persistence or full generator closure.'}
 (OUT/'persistence_review.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');print('3 existing leaf pages supplemented')
if __name__=='__main__':main()
