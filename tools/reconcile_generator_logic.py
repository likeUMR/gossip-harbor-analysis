"""Persistent local-rule ledger; candidate inventory is never a full closure claim."""
from pathlib import Path
import hashlib,json,re
from collections import Counter
from build_stage3_function_audit import source_functions
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'analysis_output/logic_recovery/stage3/generator_gate_audit/reconciliation'
DOCS=ROOT/'analysis_output/logic_recovery/stage3/mkdocs_site/docs'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

REVIEWS={
 'ItemSpread:SafeSpreadItem':([
  ('次数超过上限',465,474,'只在次数>实例上限时记录错误并截上限；不是能量下限检查，不拒绝后续产出。','output/preparation/detail.md'),
  ('储备超过上限',475,485,'储备非nil且>实例上限时记录并截上限；不改权重池与累计次数。','output/preparation/detail.md')],['BI日志下游','配置与实例创建边界']),
 'LuckyProduceModel:ReloadFileConfig':([
  ('先装表再链预处理',123,126,'先_LoadFileConfig(boostConfig)再CalculateItemChainMap。','lucky/chance/load.md'),
  ('按新表母体清两种份额',127,134,'bUpdate真时遍历新表generator，依次清Lucky和总份额；不清其它特殊状态。','lucky/chance/load.md')],['_LoadFileConfig及CalculateItemChainMap逐分支','GeneratorBoost变化入口完整生命周期','DB删除持久化']),
 'LuckyProduceModel:_ClearLuckyLeftSpreadCount':([
  ('键缓存门槛和删除',286,292,'未缓存键直接返回；已缓存才Remove对应ll_行。','lucky/chance/load.md')],['缓存建立及全部状态重置入口','DB删除持久化']),
 'LuckyProduceModel:_ClearTotalLeftSpreadCount':([
  ('键缓存门槛和删除',293,299,'未缓存键直接返回；已缓存才Remove对应tl_行。','lucky/chance/load.md')],['缓存建立及全部状态重置入口','DB删除持久化']),
 'ItemSpread:UpdatePerSecond':([
  ('无起点时启动并立即返回',76,86,'初始化/开启中，或可恢复Opened且次数未满/储备0时建立服务器时间起点；有item才保存，通知；无起点分支始终立即返回。','lifecycle/cooldown/detail.md'),
  ('加速修正起点',87,92,'有起点、加速组件且生效时，用lastUpdate-min(endTime,now)修正起点并保存。','lifecycle/cooldown/detail.md'),
  ('到期恢复及最后通知',93,99,'比例==1才恢复再保存；最后发状态事件，不以>=1替换比较式。','lifecycle/cooldown/detail.md')],['ItemAccelerateTime字段及更新顺序','StateChanged消费者','DB原生提交、同步及重载调度']),
 'ItemSpread:_UpdateRecoveryState':([
  ('初始化或开启转Opened',114,123,'清计时，设置Opened，发送ItemOpened并更新开启列表后返回。','lifecycle/cooldown/detail.md'),
  ('储备为0补满',124,129,'清计时，次数和储备同时补满后返回。','lifecycle/cooldown/detail.md'),
  ('单轮次数补满及储备扣除',130,141,'先补次数，储备扣上限-原次数；<=0截0、起点加单轮时长并递归UpdatePerSecond，否则清起点。','lifecycle/cooldown/detail.md')],['ItemOpened及UpdateOpeningItem全部消费者','配置装载','DB提交及离线更新调度']),
 'ItemSpread:GetTimerAmount':([
  ('无计时与已过时长',358,365,'nil起点返回1，否则以now-start进入_GetTimerAmount。','lifecycle/cooldown/detail.md')],['_GetTimerAmount','服务器时间来源']),
 'ItemSpread:GetNextTimerAmount':([
  ('预测下一秒',366,373,'nil起点返回1，否则以now-start+1进入_GetTimerAmount。','lifecycle/cooldown/detail.md')],['_GetTimerAmount','预测值消费者']),
 'ItemSpread:_GetTimerAmount':([
  ('缺时长诊断与清起点',374,389,'时长nil记录字段诊断，清起点并返回1。','lifecycle/cooldown/detail.md'),
  ('零时长和普通比例',390,395,'duration==0直接1，否则min(elapsed/duration,1)，无下限。','lifecycle/cooldown/detail.md')],['GetTimerDuration','诊断及起点清除之后的保存路径']),
 'ItemSpread:GetTimerDuration':([
  ('按阶段及储备选时长',396,411,'初始化/init，开启/open；Opened储备==0/storage，否则/item；未知状态assert。','lifecycle/cooldown/detail.md')],['Spread四种时长全部配置记录及覆盖']),
 'ItemSpread:CanAccelerate':([
  ('起点非nil',100,103,'仅检查存在计时起点，不以加速组件生效作为资格。','lifecycle/cooldown/detail.md')],['起点生命周期']),
 'ItemSpread:CheckSpreadState':([
  ('Closed优先',829,834,'Closed先于Opening、初始化和零次数；调用ItemClosed失败通知并返回false。','state/closed/detail.md'),
  ('Opening其次',835,838,'非Closed后判断Opening；调用ItemOpening失败通知并返回false。','state/opening/detail.md'),
  ('初始化或次数恰为零',839,844,'Initializing=4或次数==0进入阻止分支；非一次性通知ItemRecharging，一次性静默；均返回false。','state/initializing/detail.md'),
  ('其余状态放行',845,846,'无显式Opened白名单、无<=0检查；未命中三个拒绝条件即返回true。','state/opened/detail.md')],['_NotifySpreadFailed的局部/全局消费者','字段初始化、存档恢复与时间更新']),
 'ItemSpread:CostEnergy':([
  ('教程非nil优先',267,272,'先读强制值，非nil直接返回，包括false；不再读普通配置。','energy/cost/detail.md'),
  ('普通配置严格等于1',273,274,'无强制值时比较m_costEnergy==1；字段由Init原样保存。','energy/cost/detail.md')],['TutorialBoardHelper强制数据的设置和清除生命周期']),
 'ItemSpread:IsDisposable':([
  ('缺少恢复时长',354,357,'一次性定义为m_itemRecoveryDuration==nil；0不是nil，仍属可恢复。','state/model/index.md')],['恢复时长配置的覆盖与重载']),
 'ItemSpread:IsAutoSpread':([
  ('自动标记',259,262,'只有m_auto数值等于1才自动；不是一般truthy判定。','position/auto/detail.md')],['自动字段装载及自动更新下游']),
 'ItemSpread:CheckEnergy':([
  ('教程配置后Disco覆盖',863,868,'CostEnergy后检查Disco支持；支持就覆盖为false。','energy/cost/detail.md'),
  ('免能量立即返回',869,871,'false/nil返回true,0,false；不检查余额，也不修改弹窗标记。','energy/cost/detail.md'),
  ('最大档余额不足',872,881,'按母体类型取最大成本/指数；不足先写弹窗标记true，派局部LackEnergy并只返回false。','energy/cost/detail.md'),
  ('余额充足',882,883,'写弹窗标记false并返回true,最大指数,costEnergy；尚未消费。','energy/cost/detail.md')],['GetCostEnergyNum及EnergyBoost支持/成本','HasEnoughEnergy与能量状态生命周期','LackEnergy所有局部消费者','Disco支持及缓存生命周期']),
 'ItemSpread:OnTimeSkip':([
  ('无显式时长时重置起点',196,202,'只有已有计时起点才处理；duration为nil时先把起点改成当前服务器时间，再减去当前阶段完整时长。','lifecycle/cooldown/detail.md'),
  ('保存、恢复与BI顺序',203,213,'先保存母体属性，再播放加速音效并调用UpdatePerSecond；IgnoreBI为false时记录SpeedUp及跳过类型，最后结束。','lifecycle/cooldown/detail.md')],['UpdatePerSecond完整恢复闭包','服务器时间及原生DB提交','不同跳过入口的资格']),
 'ItemSpread:TryUseCDBuff':([
  ('三类资格任一成立',222,225,'普通CD Buff、GeneratorBoost CD Buff或测试免费资格任一成立才继续；三者都不成立立即返回。','lifecycle/cooldown/detail.md'),
  ('次数耗尽才跳时',226,228,'仅m_itemRestNumber==0时调用OnTimeSkip(nil,Buff)；有剩余次数不跳时。','lifecycle/cooldown/detail.md'),
  ('资格成立总会通知',229,230,'即使次数未耗尽，也会发送StateChanged；通知不等于一定恢复计时。','lifecycle/cooldown/detail.md')],['各CanSupport资格的活动/测试来源','OnTimeSkip与UpdatePerSecond下游','状态事件消费者']),
 'ItemSpread:OnTimeSkipInZeroRestNumber':([
  ('生成器与能量门槛',232,238,'先要求物品是生成器，再要求CostEnergy为真；任一不满足立即返回。','lifecycle/cooldown/detail.md'),
  ('主棋盘门槛',239,241,'只有该母体所属棋盘就是GM.MainBoardModel才继续，教程棋盘或其它棋盘直接返回。','lifecycle/cooldown/detail.md'),
  ('次数耗尽后的跳时与通知',242,246,'次数恰为0才调用OnTimeSkip(nil,Buff)，随后无条件发送StateChanged；次数非0只通知、不跳时。','lifecycle/cooldown/detail.md')],['GeneratorBoost全局回调包装器','OnTimeSkip与状态事件消费者']),
 'ItemSpread:TryUnlockCdByZroCd':([
  ('只在次数为零时尝试',216,220,'该入口只检查m_itemRestNumber==0；满足时转调TryUseCDBuff，否则不做任何事。','lifecycle/cooldown/detail.md')],['调用入口及重复通知时序']),
}

def main():
 OUT.mkdir(parents=True,exist_ok=True)
 ledger_path=OUT/'ledger.json'
 previous=json.loads(ledger_path.read_text(encoding='utf-8')) if ledger_path.exists() else None
 rows=[]
 for f in source_functions():
  if f['module'] not in ('ItemSpread','LuckyProduceModel'):continue
  p=ROOT/f['path'];lines=p.read_text(encoding='utf-8').splitlines();body='\n'.join(lines[f['line']-1:f['end_line']])
  row=dict(f,unit_id=f["module"]+'::'+f['identifier'],source_sha256=sha(p),body_sha256=hashlib.sha256(body.encode()).hexdigest(),status='待解决',local_rule_status='待解决',scope='core named function candidate; closure pending',branch_candidates=[{'line':i,'text':line.strip(),'status':'待解决'} for i,line in enumerate(lines[f['line']-1:f['end_line']],f['line']) if re.search(r'\b(if|elseif|for|while|return)\b',line)],reviewed_units=[],open_dependencies=[])
  if f['identifier'] in REVIEWS:
   units,deps=REVIEWS[f['identifier']]
   row['local_rule_status']='已解释';row['open_dependencies']=deps
   for name,start,end,meaning,page in units:
    doc='operations/generator/'+page
    row['reviewed_units'].append(dict(name=name,line=start,end_line=end,meaning=meaning,status='已解释',document=doc,document_sha256=sha(DOCS/doc),paragraph_evidence=(DOCS/doc).read_text(encoding='utf-8').split('\n---')[0],boundary='Local rule only; dependencies remain open.'))
  if previous:
   prior=next((x for x in previous['functions'] if x['unit_id']==row['unit_id']),None)
   if prior and prior['source_sha256']==row['source_sha256']:
    # Retain additional manually reviewed units rather than resetting completed work.
    names={u['name'] for u in row['reviewed_units']}
    row['reviewed_units'] += [u for u in prior['reviewed_units'] if u['name'] not in names]
    if prior['status']!='待解决':
     valid=all(sha(DOCS/u['document'])==u['document_sha256'] for u in prior['reviewed_units'])
     if valid:row.update(status=prior['status'],open_dependencies=prior['open_dependencies'],local_rule_status=prior['local_rule_status'])
  rows.append(row)
 audit=json.loads((OUT.parent/'audit.json').read_text(encoding='utf-8'))
 protos=[dict(module=name,prototype=p['prototype'],offset=p['offset'],status='待解决',reason='Need bytecode prototype to named/anonymous logic mapping; do not infer from function counts.') for name,m in audit['module_evidence'].items() for p in m['prototypes']]
 events=json.loads((OUT.parent/'event_consumers.json').read_text(encoding='utf-8'))
 event_rows=[dict(source=r['source'],line=r['registration_line'],callback=r['callback'],status='待解决',reason='Need guards, consumers, downstream dispatch and state/config closure.') for r in events['registrations']]
 mapping_path=OUT/'prototype_mapping.json'
 mapping=json.loads(mapping_path.read_text(encoding='utf-8')) if mapping_path.exists() else None
 if mapping:
  for row in rows:
   match=next(x for x in mapping['named_mappings'] if x['identifier']==row['identifier'])
   assert row['source_sha256']==match['source_sha256']
   row['original_prototype']=match
 result={'scope':'Core seed plus independently extracted prototypes and direct ItemSpread listener candidates. NOT complete operation denominator. Expand on every newly resolved call/registration.','functions':rows,'prototype_candidates':protos,'prototype_mapping':mapping,'event_candidates':event_rows,'external_boundaries':['Original runtime event/state/save differential unavailable','Actual account remote values unconfirmed'],'counts':{'named_function_candidates':len(rows),'locally_explained_functions':sum(r['local_rule_status']=='已解释' for r in rows),'locally_explained_units':sum(len(r['reviewed_units']) for r in rows),'whole_function_closure':dict(Counter(r['status'] for r in rows)),'prototype_candidates':len(protos),'direct_listener_candidates':len(event_rows)},'full_acceptance':False}
 if previous:(OUT/'ledger.previous.json').write_text(json.dumps(previous,ensure_ascii=False,indent=2),encoding='utf-8')
 ledger_path.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
 md=['# 母体点击逐单元核销台账','','本台账属于工作记录。局部规则已解释不等于整个函数下游已闭合。没有证据排除的项目均保留待解决，不把名称匹配当解释。','','| 函数 | 本地规则 | 整函数闭包 | 未闭合依赖 |','|---|---|---|---|']
 md += [f"| {r['identifier']} | {r['local_rule_status']} | {r['status']} | {'；'.join(r['open_dependencies']) or '尚待逐项审阅'} |" for r in rows]
 md+=['','## 范围纪律','','114个核心命名函数只是起始候选；独立原型和直接监听保留待核销。新发现的调用、继承、动态注册和配置消费者必须扩展范围。未取得远端实值和原版对照单独列界限，不替代可继续的本地分析。']
 (OUT/'LEDGER.md').write_text('\n'.join(md)+'\n',encoding='utf-8')
 print(json.dumps(result['counts'],ensure_ascii=False))
if __name__=='__main__':main()
