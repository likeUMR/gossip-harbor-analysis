"""Timer transitions checked against original bytecode and recovered source."""
import json
from lupa.lua53 import LuaRuntime
from reconcile_generator_logic import ROOT,OUT
SETUP=r'''
now=1000;saves=0;notices=0;opened=0;refreshes=0
GM={GameModel={GetServerTime=function() return now end}}
ItemAccelerateTime={};ItemSpreadEventType={};EEventType={ItemOpened=1}
EventDispatcher={DispatchEvent=function(e) assert(e==1);opened=opened+1 end}
Log={Error=function() end,Assert=function(ok) assert(ok) end};json={encode=function() return '{}' end}
function model(s)
 s.event={Call=function() notices=notices+1 end}
 s.m_itemModel={GetType=function() return '105' end,GetComponent=function() return nil end,GetBoardModel=function() return {SaveItemProperty=function() saves=saves+1 end,UpdateOpeningItem=function() refreshes=refreshes+1 end} end}
 return setmetatable(s,ItemSpread)
end
'''
CASES={
 'start_returns_before_expiry':"local m=model{m_state=3,m_itemRestNumber=79,m_itemMaxNumber=80,m_storageRestNumber=240,m_itemRecoveryDuration=0};m:UpdatePerSecond();assert(m.m_startTimer==1000 and m.m_itemRestNumber==79 and saves==1 and notices==1)",
 'full_no_timer':"local m=model{m_state=3,m_itemRestNumber=80,m_itemMaxNumber=80,m_storageRestNumber=240,m_itemRecoveryDuration=30};m:UpdatePerSecond();assert(m.m_startTimer==nil and saves==0 and notices==0)",
 'disposable_no_recovery_timer':"local m=model{m_state=3,m_itemRestNumber=1,m_itemMaxNumber=2,m_storageRestNumber=0};m:UpdatePerSecond();assert(m.m_startTimer==nil)",
 'initializing_disposable_does_time':"local m=model{m_state=4,m_itemRestNumber=1,m_itemMaxNumber=2,m_initDuration=10};m:UpdatePerSecond();assert(m.m_startTimer==1000)",
 'negative_ratio_not_clamped':"local m=model{m_state=3,m_startTimer=1010,m_storageRestNumber=1,m_itemRecoveryDuration=20};assert(m:GetTimerAmount()==-0.5 and m:GetNextTimerAmount()==-0.45)",
 'missing_duration_clears_start':"local m=model{m_state=3,m_startTimer=900,m_storageRestNumber=1};assert(m:GetTimerAmount()==1 and m.m_startTimer==nil)",
 'opening_finishes_and_notifies':"local m=model{m_state=2,m_startTimer=990,m_openDuration=10};m:UpdatePerSecond();assert(m.m_state==3 and m.m_startTimer==nil and opened==1 and refreshes==1 and saves==1)",
 'partial_recovery_debits_only_used':"local m=model{m_state=3,m_startTimer=970,m_itemRestNumber=75,m_itemMaxNumber=80,m_storageRestNumber=10,m_storageMaxNumber=240,m_itemRecoveryDuration=30};m:UpdatePerSecond();assert(m.m_itemRestNumber==80 and m.m_storageRestNumber==5 and m.m_startTimer==nil)",
 'insufficient_storage_still_full_round':"local m=model{m_state=3,m_startTimer=970,m_itemRestNumber=0,m_itemMaxNumber=80,m_storageRestNumber=10,m_storageMaxNumber=240,m_itemRecoveryDuration=30,m_storageRecoveryDuration=60};m:UpdatePerSecond();assert(m.m_itemRestNumber==80 and m.m_storageRestNumber==0 and m.m_startTimer==1000)",
 'offline_completes_two_stages':"now=1090;local m=model{m_state=3,m_startTimer=1000,m_itemRestNumber=0,m_itemMaxNumber=80,m_storageRestNumber=10,m_storageMaxNumber=240,m_itemRecoveryDuration=30,m_storageRecoveryDuration=60};m:UpdatePerSecond();assert(m.m_itemRestNumber==80 and m.m_storageRestNumber==240 and m.m_startTimer==nil)",
 'accelerate_rewinds_start':"local m=model{m_state=3,m_startTimer=990,m_itemRestNumber=1,m_itemMaxNumber=80,m_storageRestNumber=240,m_itemRecoveryDuration=30};m.m_itemModel.GetComponent=function() return {IsAccelerated=function() return true end,GetTime=function() return 1005 end,GetLastUpdateTime=function() return 995 end} end;m:UpdatePerSecond();assert(m.m_startTimer==985 and saves==1)",
}
def main():
 modules=json.loads((ROOT/'analysis_data/logic_index/lua_modules.json').read_text(encoding='utf-8'));m=next(m for m in modules if m['name']=='Board.Model.Item.ItemSpread');rows=[]
 for mode,path in [('bytecode',ROOT/m['standard_path']),('recovered-source',ROOT/'analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua')]:
  for name,body in CASES.items():
   try:
    lua=LuaRuntime();lua.execute(SETUP);lua.execute(path.read_bytes() if mode=='bytecode' else path.read_text(encoding='utf-8'));lua.execute(body);rows.append(dict(case=name,mode=mode,status='passed'))
   except Exception as e:rows.append(dict(case=name,mode=mode,status='failed',error=str(e)))
 result={'cases':rows,'passed':sum(r['status']=='passed' for r in rows),'total':len(rows),'limits':'Controlled clock, acceleration and save/event substitutes; no scheduler, native DB or complete consumer verification.'}
 (OUT/'timer_tests.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(result,ensure_ascii=False));assert result['passed']==result['total']
if __name__=='__main__':main()
