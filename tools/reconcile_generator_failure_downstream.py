"""Document failure consumers in their triggering steps and preserve open edges."""
import json,re,shutil
from reconcile_generator_logic import ROOT,OUT,DOCS,sha
DECODED=ROOT/'analysis_data/logic_index/lua/decoded'
SOURCES={
 'MainBoardView':'52680b5a4abed125a8dde2c711abed8c192485b98be02c575c5126f82cbd5298',
 'BaseUIBoardView':'c5a885bb08fb62bf8102322c24aafce1d9297795cf7421ca0115d68bc96bc99a',
 'EnergyModel':'0030230aa205488a410d3c4ff05d57c69ae5138a92c10ec91f0fe2d31966b7ae',
 'BundleEnergyModel':'61ed4d451148c140bbde2bbda56c90dd0e9374bb58f6448b5502332912b4c9bd',
 'ShopModel':'e51fade50aa50666fbecc7cd30ebeed3387aa9f1c66487bf4ece7a5c0d599bc9',
 'DiscoTutorial':'13c912ee38a04befa0356d7ef49b32b7e595490ef75dfa4049b66769971ceb0e',
 'BaseBoardView':'2e2dcfa5176ca1325d4fe47e36cdba5b4343edf1ec81015f1ac18ed69c8af7ce',
}
COMMON='主棋盘的失败提示由 `MainBoardView:_OnSpreadFailed` 接收棋盘事件后处理。提示位置取母体视图位置加 `(0,100,0)`，再转换为屏幕坐标；母体视图已不存在时，用 `V3Zero` 加同一偏移。失败还发送全局 SpreadFailed：Disco 教程若处于 `m_OnTapState`，会清除强制源格和目标格，再执行第三段教程。因此“没有产出”不等于“没有其它响应”；该教程回调不检查失败原因。'
BODIES={
 'state/closed/detail.md':'## 点击关闭母体后，界面如何响应\n\n'+COMMON+'\n\n关闭原因选择 `hint_item_locked` 提示。只有棋盘当前没有正在开启的物品，才让信息栏的开启按钮播放强调效果；已有开启中物品则不播放。此分支不播放冷却点击音效，也不会由这条视图逻辑调用冷却订阅窗口。',
 'state/opening/detail.md':'## 点击开启中的母体后，界面如何响应\n\n'+COMMON+'\n\n开启中原因选择 `hint_item_opening` 提示，并让信息栏的跳过按钮播放强调效果。本分支不播放冷却点击音效，不调用冷却订阅窗口；剩余20分钟阈值属于冷却失败分支，不能套到所有失败原因。',
 'state/initializing/detail.md':'## 被初始化或零次数拦截后，界面如何响应\n\n'+COMMON+'\n\n只有可恢复母体会送出本分支的 ItemRecharging 原因。视图选择 `hint_item_recharging`，播放 `SfxColdingClick`，取得母体 ItemSpread 组件；组件存在时计算 `恢复时长＋开始时间－服务器当前时间`，剩余时间至少1200秒才尝试微信冷却恢复订阅窗口。随后显示提示并强调跳过按钮。这个微信订阅尝试发生在局部失败事件处理中，与 OnTap 循环结束后的 iOS 通知尝试是两个不同入口。一次性母体在该阻止分支没有失败事件，因此不经这条提示和教程响应链。',
 'position/full/detail.md':'## 满盘失败如何提示玩家\n\n'+COMMON+'\n\n主棋盘将 BoardFull 映射为 `hint_board_full`；不播放冷却点击音效，也不强调跳过或开启按钮。视图的最后一条 else 同样接收其它未列明原因，不能认为它对原因做了完整枚举验证。活动棋盘的 `BaseUIBoardView:_OnSpreadFailed` 仅区分 ItemRecharging 与其它原因：前者提示冷却并播放音效，其余都提示满盘；不能把主棋盘的四种提示直接套给活动棋盘。',
 'energy/consume/detail.md':'''## 缺能量后先显示什么窗口

主棋盘局部 LackEnergy 由 `MainBoardView:_OnLackEnergy` 转交 `EnergyModel:OnLackEnergy(EnergyType.Main)`。它和状态失败的 SpreadFailed 是不同通知链。

1. 主能量且没有强制教程进行时，先读取内购资格并取得能量礼包模型。内购开启且模型存在，才尝试触发能量礼包。
2. 尝试之后，如果当前礼包配置存在，且不是“先显示能量窗口”的弹出类型，则直接打开 BundleEnergyWindow 并返回。
3. 其余情况调用 `ShopModel:OpenEnergyWindow(type,true)`。商城若已开启链式能量窗口，就选择当前链式窗口，否则选择 BuyEnergyWindow；此调用未传等待空闲参数，因此立即请求打开。

尝试触发礼包不是纯查询：`Try2TriggerEnergyBundle` 通过资格后，可能写入礼包组编号、Open状态和组结束时间；选择当前礼包，清旧礼包数据，保存剩余购买次数1、刷新时间INVALID_TIME、礼包到期、商品和组编号，增加触发次数，派发 BundleDataRefreshed。`IsBundleWindowPopupAfterEnergyWindow` 在没有组时返回false；有组时严格判断 PopType==1。具体触发资格、选组和界面初始化由各自模型继续处理，不能把“缺能量”直接等同于必定出现某个固定礼包。

本次母体点击仍不会生成棋子或扣母体次数；玩家随后确认购买属于新的交互，不能把购买奖励自动算进本次点击。''',
}

FUNCTIONS={
 'MainBoardView':['_OnSpreadFailed','_OnLackEnergy'],
 'BaseUIBoardView':['_OnSpreadFailed'],
 'EnergyModel':['OnLackEnergy'],
 'BundleEnergyModel':['Try2TriggerEnergyBundle','IsBundleWindowPopupAfterEnergyWindow','_GetNextTriggerBundleData','_CanTriggerEnergyBundle'],
 'ShopModel':['OpenEnergyWindow','IsChainEnergyOpen','GetChainEnergyPrefabName'],
 'DiscoTutorial':['_OnItemSpread','StartTutorial3','OnStart'],
}
def main():
 OUT.mkdir(parents=True,exist_ok=True);rows=[]
 for module,names in FUNCTIONS.items():
  p=DECODED/SOURCES[module]/'decompiled.lua';text=p.read_text(encoding='utf-8');lines=text.splitlines()
  starts=[(i,m.group(1)) for i,l in enumerate(lines,1) if (m:=re.match(r'\s*function\s+([\w.:]+)\(',l))]
  for name in names:
   matches=[(j,i,ident) for j,(i,ident) in enumerate(starts) if ident.split(':')[-1].split('.')[-1]==name]
   assert matches,(module,name)
   for j,i,ident in matches:
    end=starts[j+1][0]-1 if j+1<len(starts) else len(lines)
    rows.append(dict(module=module,identifier=ident,source=p.relative_to(ROOT).as_posix(),source_sha256=sha(p),line=i,end_line=end,body='\n'.join(lines[i-1:end]),status='待解决',local_review='Direct logic inspected; branch-level approval and all dependencies not yet complete.'))
 for rel,body in BODIES.items():
  p=DOCS/'operations/generator'/rel;old=p.read_text(encoding='utf-8')
  if '<!-- reconciliation-failure:start -->' in old:continue
  backup=OUT/'before_failure'/rel;backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,backup)
  marker='**证据状态**'
  assert marker in old,rel
  old=old.replace(marker,'<!-- reconciliation-failure:start -->\n'+body+'\n<!-- reconciliation-failure:end -->\n\n'+marker,1)
  p.write_text(old,encoding='utf-8')
 result={'expanded_function_candidates':rows,'registration_helper':{'source':(DECODED/SOURCES['BaseBoardView']/'decompiled.lua').relative_to(ROOT).as_posix(),'sha256':sha(DECODED/SOURCES['BaseBoardView']/'decompiled.lua'),'line':7,'meaning':'eventName maps to BoardEventType[eventName], method maps to view[_On..eventName]; handler lookup honors view inheritance.'},'new_edges':['SpreadFailed→MainBoardView._OnSpreadFailed→prompt/button/audio/subscription','SpreadFailed(global)→DiscoTutorial._OnItemSpread→clear forced positions→StartTutorial3','LackEnergy→MainBoardView._OnLackEnergy→EnergyModel.OnLackEnergy→BundleEnergyModel or ShopModel','BundleEnergyModel.Try2TriggerEnergyBundle→DB writes→BundleDataRefreshed'], 'open_edges':['AddHandlerAndRecordMap/PairEvent inherited registration and callback order','UIManager prompt/window initialization and asynchronous callbacks','Tutorial StartTutorial3 gesture/mask callbacks','BundleEnergyModel trigger qualification, group/cache/lifecycle','BundleDataRefreshed consumers','Shop chain-energy qualification/window selection lifecycle','WX/iOS platform subscription helpers'], 'document_pages':[{ 'page':'operations/generator/'+rel,'sha256':sha(DOCS/'operations/generator'/rel)} for rel in BODIES],'scope':'Expanded downstream candidates; not a complete listener inventory or full closure certificate.'}
 (OUT/'failure_downstream.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps({'expanded_function_candidates':len(rows),'pages_supplemented':len(BODIES)}))
if __name__=='__main__':main()
