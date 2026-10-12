"""Run real Lua serialization/restore rules with explicit DB/creation substitutes."""
import json
from lupa.lua53 import LuaRuntime
from reconcile_generator_logic import ROOT,OUT
from reconcile_generator_persistence import SOURCES
SETUP=r'''
IsNil=function(v) return v==nil end
Table={Contain=function(t,v) for _,x in ipairs(t) do if x==v then return true end end return false end}
GM={};Log={Error=function() end};ItemSpread={};ItemTransform={};ItemSwallow={};ItemBubble={};ItemPropertyBubble={};ItemAccelerate={};ItemAccelerateTime={};ItemSplit={}
function build(s)
 return {GetId=function() return 'one' end,GetCode=function() return '105' end,GetComponent=function(_,c) if c==ItemSpread then return s end end}
end
function spread(state,start,rest,storage,count,pool)
 return {GetState=function() return state end,GetStartTimer=function() return start end,GetItemRestNumber=function() return rest end,GetStorageRestNumber=function() return storage end,GetSpreadCount=function() return count end,GetCodeWeightPairs=function() return pool end}
end
'''
CASES={
 'pool_round_trip':"local p={{Code='201',Weight=2},{Code='202',Weight=1}};local s=ItemUtility.CodeWeightPairsToString(p);assert(s=='201-2;202-1');local out=ItemUtility.StringToCodeWeightPairs(s);assert(#out==2 and out[1].Code=='201' and out[1].Weight==2 and out[2].Code=='202' and out[2].Weight==1)",
 'empty_and_nil_pool':"assert(ItemUtility.CodeWeightPairsToString({})=='');assert(#ItemUtility.StringToCodeWeightPairs('')==0);assert(#ItemUtility.StringToCodeWeightPairs(nil)==0)",
 'no_negative_weight_repair':"local a=ItemUtility.StringToCodeWeightPairs('201--1');assert(a[1].Code=='201' and a[1].Weight==nil)",
 'save_six_fields':"local out={};local m=setmetatable({},ItemManager);m:_FillDBTable(build(spread(3,1000,2,10,1,{{Code='201',Weight=1},{Code='202',Weight=1}})),out);assert(out.spreadState==3 and out.spreadStartTimer==1000 and out.spreadItemRestNumber==2 and out.spreadStorageRestNumber==10 and out.spreadCount==1 and out.spreadCodeWeightPairs=='201-1;202-1')",
 'clear_old_timer_after_batch':"local db={row={spreadStartTimer=1000},BatchSet=function(self,rows) for k,v in pairs(rows.one) do self.row[k]=v end;assert(self.row.spreadStartTimer==1000) end,Remove=function(self,id,col) assert(id=='one' and col=='spreadStartTimer');self.row[col]=nil end};local m=setmetatable({m_itemTable={},m_dbTable=db},ItemManager);m:SetItem(build(spread(3,nil,80,240,1,{})));assert(db.row.spreadStartTimer==nil and db.row.spreadItemRestNumber==80)",
 'restore_overrides_initial_pool':"local restored={m_itemRestNumber=3,m_spreadCount=0,m_codeWeightPairs={{Code='201',Weight=2},{Code='202',Weight=1}}};ItemModelFactory.CreateWithCode=function() return build(restored) end;local item=ItemModelFactory.CreateWithData({}, {id='one',codeStr='105',spreadState=3,spreadStartTimer=1000,spreadItemRestNumber=2,spreadStorageRestNumber=10,spreadCount=1,spreadCodeWeightPairs='201-1;202-1'});assert(item.m_id=='one' and restored.m_state==3 and restored.m_startTimer==1000 and restored.m_itemRestNumber==2 and restored.m_storageRestNumber==10 and restored.m_spreadCount==1 and #restored.m_codeWeightPairs==2 and restored.m_codeWeightPairs[1].Weight==1)",
 'missing_timer_and_count':"local s={m_startTimer=999,m_spreadCount=7};ItemModelFactory.CreateWithCode=function() return build(s) end;ItemModelFactory.CreateWithData({}, {codeStr='105',spreadState=3,spreadItemRestNumber=80,spreadStorageRestNumber=240,spreadCodeWeightPairs=''});assert(s.m_startTimer==nil and s.m_spreadCount==0 and #s.m_codeWeightPairs==0)",
 'creation_failure_returns_nil':"ItemModelFactory.CreateWithCode=function() return nil end;assert(ItemModelFactory.CreateWithData({}, {codeStr='missing'})==nil)",
}
def main():
 modules=json.loads((ROOT/'analysis_data/logic_index/lua_modules.json').read_text(encoding='utf-8'))
 rows=[]
 for mode in ('bytecode','recovered-source'):
  for name,body in CASES.items():
   try:
    lua=LuaRuntime();lua.execute(SETUP)
    for module in ('StringUtil','ItemModelFactory','ItemUtility','ItemManager'):
     h=SOURCES[module];m=next(m for m in modules if m['sha256']==h)
     p=ROOT/m['standard_path'] if mode=='bytecode' else ROOT/'analysis_data/logic_index/lua/decoded'/h/'decompiled.lua'
     lua.execute(p.read_bytes() if mode=='bytecode' else p.read_text(encoding='utf-8'))
    lua.execute(body);rows.append(dict(case=name,mode=mode,status='passed'))
   except Exception as e:rows.append(dict(case=name,mode=mode,status='failed',error=str(e)))
 result={'cases':rows,'passed':sum(r['status']=='passed' for r in rows),'total':len(rows),'limits':'Real encode, field fill, SetItem and restore executed. DB cache and configured object creation are substitutes; no native disk/server or complete creation validation.'}
 (OUT/'persistence_tests.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(result,ensure_ascii=False));assert result['passed']==result['total']
if __name__=='__main__':main()
