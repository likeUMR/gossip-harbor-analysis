"""Selected reload transitions executed against original and recovered modules."""
import json
from lupa.lua53 import LuaRuntime
from reconcile_generator_logic import ROOT,OUT
from reconcile_generator_reload import SOURCES
SETUP=r'''
GM={};ActivityType={GeneratorBoost=1};ActivityState={Started=1};LocalConfigKey={ItemModel=1,LuckyProduce=2};Sec2Day=86400
BoardPosition={GetDir8Position=function(_,dir) return dir end}
ItemAccelerate={};PairEvent={Create=function() return {Call=function() notices=notices+1 end} end};now=1000;saves=0;notices=0
GM.GameModel={GetServerTime=function() return now end}
function accel(neighbors,old,last)
 local m=ItemAccelerateTime.Create();m.m_time=old or 0;m.m_lastUpdateTime=last or 0
 local b={GetItem=function(_,pos) local t=neighbors[pos];if t then return {GetComponent=function() return {IsActivated=function() return t.active end,GetStartTimer=function() return t.start end,GetTimerDuration=function() return t.duration end} end} end end,SaveItemProperty=function() saves=saves+1 end}
 m.m_itemModel={GetBoardModel=function() return b end,GetPosition=function() return {} end};return m
end
'''
CASES={
 'two_neighbors_use_max_not_sum':"local m=accel({[1]={active=true,start=990,duration=30},[8]={active=true,start=995,duration=40}});m:UpdateAccelerateTime();assert(m:GetTime()==1035 and m:GetLastUpdateTime()==1000 and saves==1 and notices==1)",
 'inactive_and_expired_ignored':"local m=accel({[1]={active=false,start=1000,duration=40},[2]={active=true,start=990,duration=10}});m:UpdateAccelerateTime();assert(m:GetTime()==0 and saves==0 and notices==1)",
 'old_active_is_cleared_and_saved':"local m=accel({},1020,995);m:UpdateAccelerateTime();assert(m:GetTime()==0 and m:GetLastUpdateTime()==1000 and saves==1)",
 'getter_not_time_comparison':"local m=accel({},900,800);assert(m:IsAccelerated())",
 'boost_to_boost_keeps_pool_flag':"local l={GetState=function() return 1 end,ReloadFileConfig=function(_,cfg,update) assert(cfg==chosen and update==false) end};GM.ActivityManager={GetModel=function() return l end};local m=setmetatable({},GeneratorBoostActivityModel);chosen={};m.GetLuckyProduceConfig=function() return chosen end;m.IsLastGeneratorBoostLuckyConfig=function() return true end;m.SetLastGeneratorBoostLuckyConfig=function(_,v) assert(v==true);marked=true end;m:ReloadLuckyProduceConfig();assert(marked)",
 'default_to_boost_resets_flag':"local l={GetState=function() return 1 end,ReloadFileConfig=function(_,cfg,update) assert(cfg==chosen and update==true and marked) end};GM.ActivityManager={GetModel=function() return l end};local m=setmetatable({},GeneratorBoostActivityModel);chosen={};m.GetLuckyProduceConfig=function() return chosen end;m.IsLastGeneratorBoostLuckyConfig=function() return false end;m.SetLastGeneratorBoostLuckyConfig=function(_,v) marked=v end;m:ReloadLuckyProduceConfig()",
 'lucky_not_started_no_reload':"GM.ActivityManager={GetModel=function() return {GetState=function() return 0 end} end};local m=setmetatable({},GeneratorBoostActivityModel);m.GetLuckyProduceConfig=function() error('unexpected load') end;m:ReloadLuckyProduceConfig()",
 'new_generators_cached_keys_only':"local removed={};local m=setmetatable({m_dbTable={GetValue=function() return 8 end,Remove=function(_,k) removed[k]=true end}},LuckyProduceModel);m:_GetTotalLeftSpreadCount('105');m:_GetLuckyLeftSpreadCount('105');m._LoadFileConfig=function(self) self.m_spreadConfigs={{generator={'105','106'}}} end;m.CalculateItemChainMap=function() end;m:ReloadFileConfig({},true);assert(removed.tl_105 and removed.ll_105 and not removed.tl_106 and not removed.ll_106)",
 'reload_false_no_clear':"local m=setmetatable({m_dbTable={Remove=function() error('unexpected delete') end}},LuckyProduceModel);m._LoadFileConfig=function(self) self.m_spreadConfigs={{generator={'105'}}} end;m.CalculateItemChainMap=function() end;m:ReloadFileConfig({},false)",
 'restore_only_changed_types':"local b={GetConfigChangedItemType=function() return {['105']=true} end};GM.ActivityManager={GetModel=function() return b end};local a={Type='105',ChainId='1'};local c={Type='106',ChainId='1'};GM.ConfigModel={GetLocalConfig=function() return {a,c} end};local m=setmetatable({m_mapModelConfigs={['105']={old=true},['106']={old=true}}},ItemDataModel);m:ReloadFileConfig(nil);assert(m.m_mapModelConfigs['105']==a and m.m_mapModelConfigs['106'].old)",
 'no_boost_model_no_replacement':"GM.ActivityManager={GetModel=function() return nil end};local original={};local m=setmetatable({m_mapModelConfigs={['105']=original}},ItemDataModel);m:ReloadFileConfig({{Type='105',ChainId='1'}});assert(m.m_mapModelConfigs['105']==original)",
}
def main():
 modules=json.loads((ROOT/'analysis_data/logic_index/lua_modules.json').read_text(encoding='utf-8'));rows=[]
 for mode in ('bytecode','recovered-source'):
  for name,body in CASES.items():
   try:
    lua=LuaRuntime();lua.execute(SETUP)
    for h in SOURCES.values():
     m=next(m for m in modules if m['sha256']==h);p=ROOT/m['standard_path'] if mode=='bytecode' else ROOT/'analysis_data/logic_index/lua/decoded'/h/'decompiled.lua'
     lua.execute(p.read_bytes() if mode=='bytecode' else p.read_text(encoding='utf-8'))
    lua.execute(body);rows.append({'case':name,'mode':mode,'status':'passed'})
   except Exception as e:rows.append({'case':name,'mode':mode,'status':'failed','error':str(e)})
 result={'cases':rows,'passed':sum(x['status']=='passed' for x in rows),'total':len(rows),'limits':'Selected direct contracts only; model eligibility, full config preprocessing, event scheduling and native DB dependencies controlled.'}
 (OUT/'reload_tests.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(result,ensure_ascii=False));assert result['passed']==result['total']
if __name__=='__main__':main()
