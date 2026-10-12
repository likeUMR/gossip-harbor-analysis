"""Discriminating local entry rules, executed in bytecode and recovered Lua."""
from pathlib import Path
import json
from lupa.lua53 import LuaRuntime
from reconcile_generator_logic import ROOT,OUT
SETUP=r'''
GM={MainBoardModel={},BoostChargeManager={GetHandler=function() return {CanSupportItem=function() return false end} end}}
TutorialBoardHelper={GetForcedCostEnergy=function() return forced end}
EBoostChargeType={BoostCharge_disco=1}
BoardEventType={LackEnergy=1}
'''
CASES={
 'closed_before_zero':"local m=setmetatable({m_state=1,m_itemRestNumber=0},ItemSpread);m._NotifySpreadFailed=function(_,r) reason=r end;assert(not m:CheckSpreadState() and reason==1)",
 'opening_before_zero':"local m=setmetatable({m_state=2,m_itemRestNumber=0},ItemSpread);m._NotifySpreadFailed=function(_,r) reason=r end;assert(not m:CheckSpreadState() and reason==2)",
 'initializing_recoverable':"local m=setmetatable({m_state=4,m_itemRestNumber=80,m_itemRecoveryDuration=30},ItemSpread);m._NotifySpreadFailed=function(_,r) reason=r end;assert(not m:CheckSpreadState() and reason==3)",
 'initializing_disposable_silent':"local m=setmetatable({m_state=4,m_itemRestNumber=80},ItemSpread);m._NotifySpreadFailed=function() error('unexpected notification') end;assert(not m:CheckSpreadState())",
 'zero_recoverable':"local m=setmetatable({m_state=3,m_itemRestNumber=0,m_itemRecoveryDuration=30},ItemSpread);m._NotifySpreadFailed=function(_,r) reason=r end;assert(not m:CheckSpreadState() and reason==3)",
 'zero_disposable_silent':"local m=setmetatable({m_state=3,m_itemRestNumber=0},ItemSpread);m._NotifySpreadFailed=function() error('unexpected notification') end;assert(not m:CheckSpreadState())",
 'not_opened_whitelist':"local m=setmetatable({m_state=99,m_itemRestNumber=80},ItemSpread);assert(m:CheckSpreadState())",
 'not_less_equal_zero':"local m=setmetatable({m_state=3,m_itemRestNumber=-1},ItemSpread);assert(m:CheckSpreadState())",
 'forced_false_overrides_one':"forced=false;local m=setmetatable({m_costEnergy=1},ItemSpread);assert(m:CostEnergy()==false)",
 'forced_true_overrides_zero':"forced=true;local m=setmetatable({m_costEnergy=0},ItemSpread);assert(m:CostEnergy()==true)",
 'numeric_one_only':"local m=setmetatable({m_costEnergy=1},ItemSpread);assert(m:CostEnergy());m.m_costEnergy=true;assert(not m:CostEnergy());m.m_costEnergy=2;assert(not m:CostEnergy())",
 'zero_recovery_not_disposable':"local m=setmetatable({m_itemRecoveryDuration=0},ItemSpread);assert(not m:IsDisposable());m.m_itemRecoveryDuration=nil;assert(m:IsDisposable())",
 'auto_numeric_one_only':"local m=setmetatable({m_auto=1},ItemSpread);assert(m:IsAutoSpread());m.m_auto=true;assert(not m:IsAutoSpread())",
 'free_preserves_popup_flag':"GM.EnergyModel={popupBundleEnergyWindowForLackingEnergy=true};local m=setmetatable({m_costEnergy=0},ItemSpread);m.CanSupportBoostDisco=function() return false end;local ok,ratio,cost=m:CheckEnergy();assert(ok and ratio==0 and cost==false and GM.EnergyModel.popupBundleEnergyWindowForLackingEnergy==true)",
 'disco_after_forced_cost':"forced=true;local m=setmetatable({},ItemSpread);m.CanSupportBoostDisco=function() return true end;local ok,ratio,cost=m:CheckEnergy();assert(ok and ratio==0 and cost==false)",
 'lack_flag_before_event':"local b={GetCostEnergyType=function() return 'energy' end,event={Call=function(_,e) assert(e==1 and GM.EnergyModel.popupBundleEnergyWindowForLackingEnergy==true);fired=true end}};GM.EnergyModel={HasEnoughEnergy=function(_,t,n) assert(t=='energy' and n==4);return false end};ItemSpread.GetCostEnergyNum=function() return 4,2 end;local m=setmetatable({m_costEnergy=1,m_itemModel={GetBoardModel=function() return b end,GetType=function() return '105' end}},ItemSpread);m.CanSupportBoostDisco=function() return false end;assert(not m:CheckEnergy() and fired)",
 'enough_returns_max_without_consumption':"local b={GetCostEnergyType=function() return 'energy' end};GM.EnergyModel={popupBundleEnergyWindowForLackingEnergy=true,HasEnoughEnergy=function() return true end};ItemSpread.GetCostEnergyNum=function() return 4,2 end;local m=setmetatable({m_costEnergy=1,m_itemModel={GetBoardModel=function() return b end,GetType=function() return '105' end}},ItemSpread);m.CanSupportBoostDisco=function() return false end;local ok,ratio,cost=m:CheckEnergy();assert(ok and ratio==2 and cost==true and GM.EnergyModel.popupBundleEnergyWindowForLackingEnergy==false)",
}
def main():
 modules=json.loads((ROOT/'analysis_data/logic_index/lua_modules.json').read_text(encoding='utf-8'))
 original=next(m for m in modules if m['name']=='Board.Model.Item.ItemSpread')
 rows=[]
 for mode,path in [('bytecode',ROOT/original['standard_path']),('recovered-source',ROOT/'analysis_output/logic_recovery/stage3/Board_Model_Item_ItemSpread.lua')]:
  for name,body in CASES.items():
   try:
    lua=LuaRuntime();lua.execute(SETUP);lua.execute(path.read_bytes() if mode=='bytecode' else path.read_text(encoding='utf-8'));lua.execute(body)
    rows.append(dict(case=name,mode=mode,status='passed'))
   except Exception as e:rows.append(dict(case=name,mode=mode,status='failed',error=str(e)))
 result={'cases':rows,'passed':sum(r['status']=='passed' for r in rows),'total':len(rows),'scope':'Local rules only; unusual-value cases describe exact comparisons, not claimed reachable normal gameplay. Controlled dependencies; not original runtime or persistence validation.'}
 OUT.mkdir(parents=True,exist_ok=True);(OUT/'entry_rule_tests.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps(result,ensure_ascii=False));assert result['passed']==result['total']
if __name__=='__main__':main()
