"""Execute recovered Lua 5.3 rules with controlled inputs and explicit doubles.

This verifies source behavior, not execution inside the original Unity client.
"""
from pathlib import Path
import hashlib
import json
from lupa.lua53 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / 'analysis_output/logic_recovery/stage3'
DECODED = ROOT / 'analysis_data/logic_index/lua/decoded'
FILES = {
    'table': DECODED/'b188bdf7e176ed72dc523e1b48d75c9e990415f0497a7d26fa853580a9d5675f/decompiled.lua',
    'math': DECODED/'a94220a2bc7592a39465b45e9bb426332fb6ce0a22ff95329254881386a1b155/decompiled.lua',
    'spread': STAGE/'Board_Model_Item_ItemSpread.lua',
    'lucky': STAGE/'937d00a311a7c3e02ffe929a1d19d18288822cf8d59700f5738c8dfe9b223505.lua',
    'fixed': DECODED/'9155738fadf853bcd0d59504afdf21f00caad94271007fe8444d26a64d9bf93a/decompiled.lua',
    'chest': DECODED/'f03d9253b57f82e37f0dea724e5603ea3a62cf5fade257eb08fa80c13e0d7570/decompiled.lua',
    'smart_reward': DECODED/'552b52a4f039d7bcd8c4590854906a4c840bd3a7492fcab4999a597fc475adcd/decompiled.lua',
    'board_helper': DECODED/'4908a8d707e3b24699810f84db8fa2a299914a0f6e1aa8ee8a13c6f70e49da67/decompiled.lua',
    'generator_boost': DECODED/'e153e5646c658a0cfbd2c7ca4bce3a07202bab1ef4e5ef0782585dca7f5e7f01/decompiled.lua',
    'disco': DECODED/'0632e1008f11ab0e482f1bcc4ae5f3aa1692ccec150be24f7c53c419d42e1fd8/decompiled.lua',
    'card': DECODED/'cc281f0649d072a830a3b132ea60af33f2a2e59f7ffe521cb0ce8cb4bc52c1a6/decompiled.lua',
    'room': DECODED/'363aafacc07b4054b7974bf8d9ef8686fd65a3985b4c74af1febcf29fd556efc/decompiled.lua',
    'click_acquire': DECODED/'9b77d3a2b7d80030bbc961d24980420a21993bc5b3b335648e53c532f9981f4d/decompiled.lua',
    'token_chain': DECODED/'21edf9e951ccd56a5a76abb1e1951565f1a195acf8cdf6e366fbaae2ad1a9861/decompiled.lua',
    'config_model': DECODED/'338b600ea574dfe383694802831bb7b0c34cd95f752f9a29b4c5b9fcccc258e8/decompiled.lua',
    'boot_require': DECODED/'e36873cda5eaf1b825bd873a199220a679e29f6697d0d0da1bedab302d6aaae0/decompiled.lua',
}
SETUP = r'''
BaseItemComponent={} BaseActivityModel={} BoostChargePropertyBaseHandler={} Sec2Day=86400
GameConfig={IsTestMode=function() return false end}
Log={Assert=function(x,msg) assert(x,msg) end,Error=function() end}
GM={} EBoardType={Tutorial='Tutorial'} ActivityState={Started='Started'}
ActivityType={LuckyProduce='LuckyProduce'} EGeneralConfType={AdjustLuckyProduceBoostRatio='adjust'}
EPlayerPrefKey={LuckyProduceEnergyBoostRatioAdjustData='adjust_data'}
BoardSpreadType={Normal='Normal',Lucky='Lucky',SuperLucky='SuperLucky',FreeLucky='FreeLucky',FreeSuperLucky='FreeSuperLucky',DoubleLucky='DoubleLucky',TripleLucky1='TripleLucky1',TripleLucky2='TripleLucky2',GeneratorBoostSmart='GeneratorBoostSmart'}
PlayerPrefs={data={},GetString=function(k,d) return PlayerPrefs.data[k] or d end,SetString=function(k,v) PlayerPrefs.data[k]=v end}
StringUtil={IsNilOrEmpty=function(v) return v==nil or v=='' end, SplitToNum=function(v,sep) local r={} for x in (v or ''):gmatch('[^,]+') do r[#r+1]=tonumber(x) end return r end}
GM.GameModel={GetServerTime=function() return now end} now=1000
GM.ConfigModel={IsServerControlOpen=function() return false end}
GM.EnergyBoostModel={CanEnergyBoost=function() return false end}
GM.MainBoardModel={GetOrderCodeLackCountMap=function() return {} end}
function db()
 return {data={},GetValue=function(self,k,col) return self.data[k..':'..(col or 'value')] end,
 Set=function(self,k,col,v) self.data[k..':'..col]=v end,
 Remove=function(self,k) for key,_ in pairs(self.data) do if key:sub(1,#k+1)==k..':' then self.data[key]=nil end end end}
end
function lucky()
 return setmetatable({m_dbTable=db(),m_arrFreeLuckyProduceEnergyCostCount={}},LuckyProduceModel)
end
function spread()
 return setmetatable({m_itemRestNumber=80,m_itemMaxNumber=80,m_storageRestNumber=240,m_storageMaxNumber=240,m_spreadCount=0,m_state=3},ItemSpread)
end
function randoms(values)
 local i=0
 math.random=function() i=i+1 assert(values[i]~=nil,'unexpected random call') return values[i] end
 return function() return i end
end
'''
CASES = [
 ('random_integer_endpoints', "randoms({0,0.999999,0,0.999999}); assert(MathUtil.Random(42)==1); assert(MathUtil.Random(42)==42); assert(MathUtil.Random(3,7)==3); assert(MathUtil.Random(3,7)==7)"),
 ('weighted_boundaries', "local p={{Code='a',Weight=35},{Code='b',Weight=2},{Code='c',Weight=5}}; randoms({34/42,35/42,36/42,37/42}); assert(Table.ListWeightSelectOne(p).Code=='a'); assert(Table.ListWeightSelectOne(p).Code=='b'); assert(Table.ListWeightSelectOne(p).Code=='b'); assert(Table.ListWeightSelectOne(p).Code=='c')"),
 ('smart_disabled_fraction', "local m=lucky(); m.m_smartProduceRatio=0.25; assert(m:_UseSmartProduce()==false)"),
 ('smart_enabled_one', "local m=lucky(); m.m_smartProduceRatio=1; assert(m:_UseSmartProduce()==true)"),
 ('smart_chain_level_boost', "local m=lucky(); m.m_smartProduceRatio=3; local a={Item='a',Weight=66,ItemChainLevel=4}; local b={Item='b',Weight=7,ItemChainLevel=5}; local p={lucky_items={a,b},itemChainMap={food={a,b}}}; GM.ItemDataModel={GetChainId=function() return 'food' end,GetChainLevel=function() return 5 end}; GM.MainBoardModel.GetOrderCodeLackCountMap=function() return {target=99} end; GM.EnergyBoostModel.CanEnergyBoost=function() return true end; GM.EnergyBoostModel.GetEnergyBoostPowerRatio=function() return 1 end; m:_UpdateSpreadConfigSmartWeight('105',p); assert(a.Weight_Smart==198 and b.Weight_Smart==7); assert(a.Weight==66 and b.Weight==7)"),
 ('smart_recomputed_no_compounding', "local m=lucky(); m.m_smartProduceRatio=2; local a={Item='a',Weight=10,ItemChainLevel=1}; local p={lucky_items={a},itemChainMap={food={a}}}; GM.ItemDataModel={GetChainId=function() return 'food' end,GetChainLevel=function() return 1 end}; GM.MainBoardModel.GetOrderCodeLackCountMap=function() return {target=1} end; m:_UpdateSpreadConfigSmartWeight('105',p); assert(a.Weight_Smart==20); m:_UpdateSpreadConfigSmartWeight('105',p); assert(a.Weight_Smart==20); GM.MainBoardModel.GetOrderCodeLackCountMap=function() return {} end; m:_UpdateSpreadConfigSmartWeight('105',p); assert(a.Weight_Smart==10)"),
 ('super_no_extra_roll', "local m=lucky(); local count=randoms({0}); local code,t=m:_GetGenerateLuckyItem('105',{lucky_items={{Item='205',Weight=1}},super_items={'205'}},false); assert(code=='205' and t=='SuperLucky' and count()==1)"),
 ('free_super_classification', "local m=lucky(); randoms({0}); local code,t=m:_GetGenerateLuckyItem('105',{lucky_items={{Item='205',Weight=1}},super_items={'205'}},true); assert(code=='205' and t=='FreeSuperLucky')"),
 ('continuous_type_precedence', "local m=lucky(); randoms({0}); local code,t=m:_GetGenerateLuckyItem('105',{lucky_items={{Item='205',Weight=1}},super_items={'205'}},true,'TripleLucky1'); assert(t=='TripleLucky1')"),
 ('continuous_exact_expiry_allowed', "local m=lucky(); m:_TriggerContiLuckyProduce('105',2); now=1010; assert(m:_CanContiLuckyProduce('105')==true); now=1011; assert(m:_CanContiLuckyProduce('105')==false); assert(m.m_dbTable:GetValue('clpit','value')==nil)"),
 ('continuous_other_generator_clears', "local m=lucky(); m:_TriggerContiLuckyProduce('105',2); assert(m:_CanContiLuckyProduce('106')==false); assert(m:_CanContiLuckyProduce('105')==false)"),
 ('continuous_consume_refresh', "local m=lucky(); m:_TriggerContiLuckyProduce('105',2); now=1005; assert(m:_PostProcessOnContiLuckyProduce()=='TripleLucky1'); assert(m.m_dbTable:GetValue('clpeet','value')==1015); assert(m:_PostProcessOnContiLuckyProduce()=='TripleLucky2'); assert(m:_CanContiLuckyProduce('105')==false)"),
 ('triple_skips_second_roll', "local m=lucky(); m.m_arrLuckyProduceConfig={{triple_lucky_chance=1000,double_lucky_chance=3000}}; m.m_curLuckyProduceConfigIndex=1; local count=randoms({0.0799}); m:_Try2TriggerContiLuckyProduce('105'); assert(m.m_dbTable:GetValue('clpmc','value')==2 and count()==1)"),
 ('double_after_triple_failure', "local m=lucky(); m.m_arrLuckyProduceConfig={{triple_lucky_chance=1000,double_lucky_chance=3000}}; m.m_curLuckyProduceConfigIndex=1; local count=randoms({0.4499,0.1199}); m:_Try2TriggerContiLuckyProduce('105'); assert(m.m_dbTable:GetValue('clpmc','value')==1 and count()==2)"),
 ('free_threshold_consumed_once', "local m=lucky(); m.m_arrFreeLuckyProduceEnergyCostCount={50,80}; m.m_dbTable:Set('ecc','value',60); assert(m:_CanFreeLuckyProduce()); m:_PostProcessOnFreeLuckyProduce(); assert(not m:_CanFreeLuckyProduce()); assert(m.m_dbTable:GetValue('elpec','value')=='80')"),
 ('daily_reset_preserves_continuous', "local m=lucky(); m.m_arrLuckyProduceConfig={{energy_cost={range_entry={0,100}}}}; m.m_dbTable:Set('ecc','value',80); m.m_dbTable:Set('elpec','value','50'); m:_TriggerContiLuckyProduce('105',2); m:_ResetEnergyCost(); assert(m:_GetEnergyCostCount()==0); assert(#m.m_arrFreeLuckyProduceEnergyCostCount==0); assert(m.m_dbTable:GetValue('clpit','value')=='105')"),
 ('boost_history_ceiling', "local m=lucky(); GM.ConfigModel.IsServerControlOpen=function() return true end; m.m_cachedBoostRatioAdjustData={0,1,2,2}; assert(m:GetAdjustedMaxEnergyBoostRatio(3)==2); m.m_cachedBoostRatioAdjustData={}; assert(m:GetAdjustedMaxEnergyBoostRatio(3)==3)"),
 ('disposable_times_cost', "local s=spread(); s.m_weightType=1; s:CosetRestNumber(nil,2,'201'); assert(s.m_itemRestNumber==76 and s.m_spreadCount==1)"),
 ('explicit_zero_cost_still_counts', "local s=spread(); s:CosetRestNumber(0,3,'201'); assert(s.m_itemRestNumber==80 and s.m_spreadCount==1)"),
 ('times_clamp_zero', "local s=spread(); s.m_itemRestNumber=2; s:CosetRestNumber(10,0,'201'); assert(s.m_itemRestNumber==0)"),
 ('timer_not_lower_clamped', "local s=spread(); s.m_state=3; s.m_itemRecoveryDuration=30; s.m_startTimer=1010; assert(s:GetTimerAmount()==-1/3); assert(s:GetNextTimerAmount()==-0.3)"),
 ('timer_zero_duration', "local s=spread(); s.m_state=3; s.m_itemRecoveryDuration=0; s.m_startTimer=1000; assert(s:GetTimerAmount()==1)"),
 ('timer_missing_duration_clears', "local s=spread(); s.m_itemModel={GetType=function() return '105' end}; s.m_startTimer=1000; json={encode=function() return '' end}; assert(s:GetTimerAmount()==1 and s.m_startTimer==nil)"),
 ('recovery_storage_insufficient', "local s=spread(); s.m_itemRestNumber=0; s.m_storageRestNumber=10; s.m_itemRecoveryDuration=30; s.m_startTimer=1000; s.UpdatePerSecond=function() end; s:_UpdateRecoveryState(); assert(s.m_itemRestNumber==80 and s.m_storageRestNumber==0 and s.m_startTimer==1030)"),
 ('recovery_full_storage', "local s=spread(); s.m_itemRestNumber=0; s.m_storageRestNumber=0; s.m_startTimer=1000; s:_UpdateRecoveryState(); assert(s.m_itemRestNumber==80 and s.m_storageRestNumber==240 and s.m_startTimer==nil)"),
 ('closed_priority', "local s=spread(); s.m_state=1; s.m_itemRestNumber=0; s._NotifySpreadFailed=function(self,r) self.reason=r end; assert(not s:CheckSpreadState()); assert(s.reason==1)"),
 ('disposable_empty_silent', "local s=spread(); s.m_itemRestNumber=0; s._NotifySpreadFailed=function() error('must not notify') end; assert(not s:CheckSpreadState())"),
 ('manual_gate_short_circuit', "local s=spread(); s.CheckSpreadState=function() return false end; s.CheckSpreadPosAndAuto=function() error('must not check position') end; assert(s:_TrySpread()==false)"),
 ('lucky_skips_ordinary_times', "local s=spread(); s.CheckLuckyProduce=function() return true,'205','Lucky' end; GM.ActivityManager={GetModel=function() return lucky() end}; GM.ItemDataModel={GetModelConfig=function() return {MergedType='206'} end}; local code,t,ratio=s:GenerateItemCode(1); assert(code=='206' and t=='Lucky' and ratio==1 and s.m_spreadCount==0 and s.m_itemRestNumber==80)"),
 ('fixed_pool_depletes_and_refills', r'''local m=setmetatable({m_dbTable=db(),m_dbTableOld=db(),m_mapFixedSpreadWeight={},m_mapLeftSpreadCount={}},ItemFixedSpreadModel)
 StringUtil={IsNilOrEmpty=function(v) return v==nil or v=='' end}
 ItemUtility={StringToCodeWeightPairs=function(str) local t={} for c,w in str:gmatch('([^,:]+):(%d+)') do t[#t+1]={Code=c,Weight=tonumber(w)} end return t end, CodeWeightPairsToString=function(p) local t={} for _,v in ipairs(p) do t[#t+1]=v.Code..':'..v.Weight end return table.concat(t,',') end}
 GM.ItemDataModel={GetModelConfig=function() return {Spread_Weight_Str='a:2,b:1'} end}
 randoms({0,0,0,0}); assert(m:GenerateItemCode('105')=='a'); assert(m.m_mapLeftSpreadCount['105']==2); assert(m:GenerateItemCode('105')=='a'); assert(m:GenerateItemCode('105')=='b'); assert(m.m_mapLeftSpreadCount['105']==3); assert(m:GenerateItemCode('105')=='a')'''),
]

CASES += [
 ('card_exact_multiple_not_enough_comparison', r'''local m=setmetatable({m_cacheData={chain='card',isFinish=false}},CardItemModel); local count=4; GM.ItemDataModel={GetChainMaxLevel=function() return 3 end,GetChainId=function() return 'card' end,GetChainLevel=function() return 1 end}; ItemModelFactory={GetCodePrefixTargetType=function() return nil end}; GM.MainBoardModel.GetCodeCountMap=function(_,a,b,c) assert(a and b and c); return {one=count} end; assert(m:CheckCanMergeMaxCardItem()==true); count=5; local ok,n=m:CheckCanMergeMaxCardItem(); assert(ok==false and n==5); count=8; assert(m:CheckCanMergeMaxCardItem()==true); count=0; assert(m:CheckCanMergeMaxCardItem()==false)'''),
 ('card_stack_finishes_then_allows_progress', r'''local m=setmetatable({m_cacheData={chain='card',isFinish=false}},CardItemModel); m.GetState=function() return 'Started' end; m.SaveCacheData=function() end; GM.ConfigModel.GetGeneralConfByType=function() return 1 end; EGeneralConfType.cardItemStack='stack'; GM.ItemDataModel={GetChainMaxLevel=function() return 3 end,GetChainId=function() return 'card' end,GetChainLevel=function() return 1 end}; ItemModelFactory={GetCodePrefixTargetType=function() return nil end}; GM.MainBoardModel.GetCodeCountMap=function() return {one=4} end; assert(m:CanGenerateCardItem()==true and m.m_cacheData.isFinish==true); m.m_cacheData.isFinish=false; GM.ConfigModel.GetGeneralConfByType=function() return 0 end; assert(m:CanGenerateCardItem()==false)'''),
 ('card_new_chain_excludes_old_then_falls_back', r'''local m=setmetatable({m_cacheData={chain='old'},m_mapCardItemTypeConfig={old={ItemChain='old',UnlockLevel=25,Weight=600},new={ItemChain='new',UnlockLevel=25,Weight=1},locked={ItemChain='locked',UnlockLevel=30,Weight=9999}}},CardItemModel); GM.LevelModel={GetCurrentLevel=function() return 25 end}; randoms({0,0}); assert(m:TryGenerateNewChain()=='new'); m.m_mapCardItemTypeConfig.new=nil; assert(m:TryGenerateNewChain()=='old')'''),
 ('card_energy_listener_has_no_source_board_filter', r'''local m=setmetatable({m_energyGenerateNum=10},CardItemModel); local n; m.AddEnergyNum=function(_,v) n=v end; m:OnItemSpread({CostEnergy=true,EnergyBoostRatio=2,Source={}}); assert(n==4); n=nil; m:OnItemSpread({CostEnergy=false,EnergyBoostRatio=2}); assert(n==nil)'''),
 ('card_generate_notification_advances_tutorial_once', r'''local m=setmetatable({m_dbTable=db()},CardItemModel); local calls=0; EEventType={TutorialStartPop='tutorial'}; EventDispatcher={DispatchEvent=function() calls=calls+1 end}; m:OnCardItemGenerate({}); assert(m.m_dbTable:GetValue('isPlayFirstTutorial','value')=='1' and calls==1); m:PopCardItemTutorial(); m:OnCardItemGenerate({}); assert(calls==1)'''),
 ('room_hit_does_not_decrement_total', r'''local m=setmetatable({m_curInfo={roomLockInfo={curClickNum=3,curAddScoreNum=1,chance={3,1}}}},RoomModel); m.SaveActivityData=function() end; local earned; m.AcquireKey=function(_,n) earned=n; return false end; m.event={Call=function() end}; randoms({1,3}); m:TryLockStartAddScore({GetType=function() return '105' end},2); assert(earned==4 and m.m_curInfo.roomLockInfo.curClickNum==3 and m.m_curInfo.roomLockInfo.curAddScoreNum==0); m:TryLockStartAddScore({},0); assert(m.m_curInfo.roomLockInfo.curClickNum==2)'''),
 ('room_unlock_rewards_only_one_round_per_event', r'''local m=setmetatable({m_curInfo={roomUnLockInfo={acuqireTokenInfo={curEnergy=2,energy=3,reward={'first'},round=1}}},m_activityDefinition={BIGetReward='reward'}},RoomModel); m.SaveActivityData=function() end; m.GetRoomGetToolConfig=function() return {energy=2,tools={'next'}} end; m.event={Call=function() end}; local calls=0; RewardApi={AcquireRewardsLogic=function() calls=calls+1 end}; EPropertySource={Give='give'}; EGameMode={Main='main'}; CacheItemType={Type2='cache'}; m:TryUnlockActivityToken({},2); local info=m.m_curInfo.roomUnLockInfo.acuqireTokenInfo; assert(calls==1 and info.curEnergy==3 and info.round==2); m:TryUnlockActivityToken({},0); assert(calls==2 and info.curEnergy==2 and info.round==3)'''),
 ('room_token_event_precedes_db_write', r'''local m=setmetatable({m_dbTable=db(),m_activityDefinition={TokenNumberChangedEvent='token'}},RoomModel); m.m_dbTable:Set('activityToken','value',4); EventDispatcher={DispatchEvent=function(_,delta) assert(delta==2 and m:GetTokenNum()==4) end}; m:SetTokenNum(6); assert(m:GetTokenNum()==6)'''),
 ('click_acquire_consumes_one_chance_for_boost', r'''local d=db(); local m=setmetatable({},ItemClickAcquireModule); local info={rewardCount=3,conditionCount=1,DBKeys={GenerateRoundTotalCountKey='T',GenerateRoundValidCountKey='V'}}; local model={GetDBTable=function() return d end}; randoms({0,0.9}); assert(m:_GenerateItemType(model,info,2)==4); assert(d:GetValue('T','value')==2 and d:GetValue('V','value')==0); assert(m:_GenerateItemType(model,info,0)==nil and d:GetValue('T','value')==1)'''),
 ('token_callback_nil_and_missing_view', r'''BaseActivityModel._OnStateChanged=function() end; EventDispatcher={DispatchEvent=function() end}; ActivityModuleManager={ModuleType={ClickAcquireProperty='click'}}; local callback,condition; GM.ActivityModuleManager={AddRegister=function(_,kind,model,total,valid,cb,keys,cond) assert(total==3 and valid==1 and keys.GenerateRoundTotalCountKey=='TotalClickTimes'); callback=cb; condition=cond end}; local m=setmetatable({m_dbTable=db(),m_tokenConfig={chance={3,1}},m_activityDefinition={StateChangedEvent='state',TokenNumChangedEvent='token'}},TokenChainActivityModel); m.GetState=function() return 'Started' end; m.CanGiveStartToken=function() return false end; m.IsFinished=function() return false end; m.LogActivity=function() end; EBIType={ActivityAddScore='add'}; GM.BIManager={TableToString=function() return '' end}; MainBoardView={GetInstance=function() return nil end}; m.m_dbTable:Set('TokenNum','value',10); m:_OnStateChanged(); assert(condition()); callback(nil,{}); assert(m:GetTokenNum()==10); callback(4,{}); assert(m:GetTokenNum()==14); m.IsFinished=function() return true end; assert(condition()==nil)'''),
 ('config_suffix_first_exact_filename', r'''StringUtil.rFindChar=function(s,c) local last; for i=1,#s do if s:sub(i,i)==c then last=i end end; return last end; local m=setmetatable({},ConfigModel); m.GetServerConfig=function() return {{file='CardItemConfig',suffix='_more'},{file='CardItemConfig',suffix='_zero'},{file='CardItemProduceConfig',suffix='_zero'}} end; assert(m:GetReplacesFilePath('Data.Config.CardItemConfig','.')=='Data.Config.CardItemConfig_more'); assert(m:GetReplacesFilePath('Data.Config.CardItemProduceConfig','.')=='Data.Config.CardItemProduceConfig_zero'); assert(m:GetReplacesFilePath('Data.Config.ItemModelConfig','.')=='Data.Config.ItemModelConfig')'''),
 ('require_replacement_failure_falls_back_default', r'''local calls={}; require=function(path) calls[#calls+1]=path; if path=='Data.Config.CardItemConfig_more' then error('missing') end; return 'default' end; GM.ConfigModel.GetReplacesFilePath=function(_,path) return path..'_more' end; assert(load(recoveredRequireChunk))(); assert(require('Data.Config.CardItemConfig')=='default'); assert(#calls==2 and calls[1]=='Data.Config.CardItemConfig_more' and calls[2]=='Data.Config.CardItemConfig')'''),
 ('require_replacement_success_does_not_load_default', r'''local calls=0; require=function(path) calls=calls+1; assert(path=='Data.Config.CardItemConfig_more'); return 'more' end; GM.ConfigModel.GetReplacesFilePath=function(_,path) return path..'_more' end; assert(load(recoveredRequireChunk))(); assert(require('Data.Config.CardItemConfig')=='more' and calls==1)'''),
]

CASES += [
 ('disco_max_level_right_shift', "local m=setmetatable({},BoostChargeDiscoBoostHandler); assert(m:GetMaxLevelByScore(18)==5); assert(m:GetMaxLevelByScore(16)==5); assert(m:GetMaxLevelByScore(15)==4)"),
 ('disco_zero_closes_before_final_save', r'''local trace={}; EEventType={TriggerBoostDiscoUpdate='update'}; EventDispatcher={DispatchEvent=function(_,v) trace[#trace+1]='update:'..v end}; local m=setmetatable({m_cacheData={boostChargeNum=10}},BoostChargeDiscoBoostHandler); m.CloseDisco=function(self) assert(self.m_cacheData.boostChargeNum==0); trace[#trace+1]='close'; self.m_cacheData=nil end; m.SaveCacheData=function() trace[#trace+1]='save' end; m:ReduceDiscoScore(16); assert(table.concat(trace,',')=='update:16,close,save')'''),
 ('disco_reduces_code_and_index_to_affordable', r'''OrderModelType={Slot='Slot'}; local m=setmetatable({m_cacheData={boostChargeNum=1}},BoostChargeDiscoBoostHandler); m.CanSupportItem=function() return true end; m.ReduceDiscoScore=function(_,n) assert(n==8) end; GM.ItemDataModel={GetChainLevel=function(_,c) return tonumber(c) end,GetChainId=function() return 'food' end,GetTypeByChainAndLevel=function(_,c,l) return tostring(l) end}; GM.MainBoardModel.GetOrderModel=function() return {GetItemCodeConfigMap=function() return {} end} end; local c,b=m:TryUseDiscoItem('105','5',3); assert(c=='4' and b==2)'''),
 ('disco_energy_and_lucky_gates_skip_services', r'''local s=spread(); s.CostEnergy=function() return true end; s.CanSupportBoostDisco=function() return true end; s.m_itemModel={GetBoardModel=function() return {BoardType='Main'} end}; local ok,b,cost=s:CheckEnergy(); assert(ok and b==0 and cost==false); assert(s:CheckLuckyProduce()==false)'''),
 ('fishnet_only_lowers_and_preserves_index', r'''ItemModelFactory={GetCodePrefixTargetType=function() return nil end}; ItemChain={RwaFish='fish'}; EGeneralConfType.FishNetProduceSmart='fishnet'; ELogSpreadExtScene={FishNetProduceSmart='scene'}; GM.ConfigModel.IsServerControlOpen=function(_,k) return k=='fishnet' end; GM.ItemDataModel={GetChainId=function() return 'fish' end,GetChainLevel=function(_,c) return tonumber(c) end,GetChainMaxLevel=function() return 6 end,GetChain=function() return {} end,GetTypeByChainAndLevel=function(_,c,l) return tostring(l) end,GetModelConfig=function(_,c) return {MergedType=tostring(tonumber(c)+1)} end}; local board={GetOrderCodeLackCountMap=function() return {} end,GetCodeCountMap=function() return {['4']=3} end}; local s=spread(); s.m_itemModel={GetBoardModel=function() return board end}; local c,b,scene=s:SpreadCheckEnergyRatioAndCode('3',2,true); assert(c=='4' and b==2 and scene=='scene'); c,b,scene=s:SpreadCheckEnergyRatioAndCode('2',2,true); assert(c=='4' and b==2 and scene==nil)'''),
 ('fixed_same_type_shares_pool_between_instances', r'''local m=setmetatable({m_dbTable=db(),m_dbTableOld=db(),m_mapFixedSpreadWeight={},m_mapLeftSpreadCount={}},ItemFixedSpreadModel); ItemUtility={StringToCodeWeightPairs=function(str) local t={} for c,w in str:gmatch('([^,:]+):(%d+)') do t[#t+1]={Code=c,Weight=tonumber(w)} end return t end,CodeWeightPairsToString=function(p) local t={} for _,v in ipairs(p) do t[#t+1]=v.Code..':'..v.Weight end return table.concat(t,',') end}; GM.ItemDataModel={GetModelConfig=function() return {Spread_Weight_Str='a:2,b:1'} end}; GM.ItemFixedSpreadModel=m; local a=spread(); local b=spread(); local item={GetType=function() return '105' end,GetComponent=function() return nil end}; a.m_itemModel=item; b.m_itemModel=item; randoms({0,0}); assert(a:_FixedGenerateItemCode()=='a'); assert(b:_FixedGenerateItemCode()=='a'); assert(m.m_mapLeftSpreadCount['105']==1)'''),
 ('chest_tolerance_builds_more_than_first_item', r'''OrderState={Finished='Finished'} OrderModelType={Slot='Slot'}
 local cfg={a={DiffScore=8},b={DiffScore=18}}
 GM.MainBoardModel={GetCodeCountMap=function() return {} end, GetOrderModel=function() return {GetItemCodeConfigMap=function() return cfg end} end, GetOrders=function() return {{GetState=function() return 'Open' end,GetRequirements=function() return {'a','b'} end}} end}
 local codes=RandomGenerateCodeHelper.GenerateChestCustomCodeRule(20,1,false); assert(#codes==2 and codes[1]=='a' and codes[2]=='b')'''),
 ('chest_old_pick_ceil_overspends', r'''GM.ItemDataModel={GetChainId=function() return 'food' end,GetChainLevel=function() return 5 end,GetTypeByChainAndLevel=function(_,chain,l) return tostring(l) end}; local cfg={['5']={DiffScore=30},['4']={DiffScore=8}}; local codes={}; local rest=RandomGenerateCodeHelper._PickItems_old({code='5'},cfg,10,codes,1,0,''); assert(rest==-6 and #codes==2 and codes[1]=='4')'''),
 ('smart_merge_inventory_not_double_used', r'''GM.ItemDataModel={GetChainId=function() return 'food' end, GetChainLevel=function() return 5 end, GetTypeByChainAndLevel=function(_,c,l) return tostring(l) end}; local counts={['4']=1}; assert(BoardModelHelper.CalculateLackNumForMergeRequire('5',counts)==8); assert(counts['4']==0); assert(BoardModelHelper.CalculateLackNumForMergeRequire('5',counts)==16)'''),
 ('smart_binary_one_result', r'''SmartRewardHelper.AppendTestInfo=function() end; GM.ItemDataModel={GetTypeByChainAndLevel=function(_,c,l) return tostring(l) end}; local data={resultCount=1,isNeedUpFind=true}; local res={}; local rest=SmartRewardHelper.CalculateRewardItems(res,10,'food',20,{['2']=2,['4']=8},{},1,data); assert(#res==1 and res[1]=='2' and rest==18 and data.resultCount==0)'''),
 ('smart_equivalent_split_power_of_two', r'''GM.ItemDataModel={GetChainId=function() return 'food' end,GetChainLevel=function() return 5 end,GetTypeByChainAndLevel=function(_,c,l) return tostring(l) end}; local code,multi,score=SmartRewardHelper.GetEquivalentCode('5',{['3']=4},{}); assert(code=='3' and multi==4 and score==16)'''),
 ('smart_205_fallback_no_random_when_budget_small', r'''SmartRewardHelper.AppendTestInfo=function() end; local calls=randoms({}); local res={}; local rest=SmartRewardHelper.DeliverRandom205_206(res,3,{['205']=8,['206']=16},{resultCount=1}); assert(res[1]=='205' and rest==-5 and calls()==0)'''),
 ('smart_206_fallback_random_boundary', r'''SmartRewardHelper.AppendTestInfo=function() end; ItemChain={Bread='Bread'}; GM.ItemDataModel={GetTypeByChainAndLevel=function(_,c,l) return l==5 and '205' or '206' end}; randoms({0.5}); local res={}; local rest=SmartRewardHelper.DeliverRandom205_206(res,9,{['205']=8,['206']=16},{resultCount=1}); assert(res[1]=='206' and rest==-7)'''),
 ('boost_finite_extra_pool', r'''local m=setmetatable({m_dbTable=db(),m_extraProduceChance={3,1}},GeneratorBoostActivityModel); randoms({0,0,0}); assert(m:_CanExtraProduceItem()==true); assert(m:_CanExtraProduceItem()==false); assert(m:_CanExtraProduceItem()==false); assert(m.m_dbTable:GetValue('ExtraProduceTotalSpreadCount','value')==0)'''),
 ('boost_no_space_caches_boolean_qualification', r'''local m=setmetatable({m_dbTable=db()},GeneratorBoostActivityModel); GM.MainBoardModel.FindEmptyPositionInSpreadOrderWithNum=function() return {} end; local item={GetPosition=function() return 'P' end}; assert(m:_ExtraProduceItem(item,false)==false); assert(m:IsCachedExtraProduce()); GM.MainBoardModel.FindEmptyPositionInSpreadOrderWithNum=function() return {'P','Q'} end; assert(m:_ExtraProduceItem(item,true)==true); assert(not m:IsCachedExtraProduce())'''),
 ('boost_lucky_listener_excludes_continuous', r'''local called=0; local m=setmetatable({},GeneratorBoostActivityModel); m.TryExtraLuckyProduceItem=function() called=called+1 end; local source={GetComponent=function() return {CanSupportGeneratorBoost=function() return true end} end}; m:_OnItemSpread({Source=source,BoardSpreadType='SuperLucky'}); assert(called==1); m:_OnItemSpread({Source=source,BoardSpreadType='TripleLucky1'}); m:_OnItemSpread({Source=source,BoardSpreadType='DoubleLucky'}); assert(called==1)'''),
 ('order_empty_unlock_fallback_is_uniform_codes', r'''local s=spread(); s._Log=function() end; s.m_codeWeightPairs={{Code='a',Weight=100},{Code='b',Weight=1}}; GM.ItemDataModel={GetModelConfig=function() return nil end}; randoms({0.75}); assert(s:_TryGenerateItemCodeAll()=='b')'''),
 ('ordinary_state_saved_before_actual_landing', r'''local order={}; local s=spread(); s.CheckLuckyProduce=function() return false end; s.CanSupportBoostDisco=function() return false end; s.SafeSpreadItem=function() end; s._GenerateItemCode=function() return 'a',false,1 end; s.SpreadCheckEnergyRatioAndCode=function() return 'a',0 end; s.DealActivityLimit=function(_,c,b,n) return c,b,n end; s.UpdatePerSecond=function() order[#order+1]='timer' end; s.event={Call=function() order[#order+1]='state' end}; s.m_itemModel={GetBoardModel=function() return {SaveItemProperty=function() order[#order+1]='save' end} end}; s:GenerateItemCode(0); assert(table.concat(order,',')=='timer,state,save'); assert(s.m_itemRestNumber==79 and s.m_spreadCount==1)'''),
]


CASES += [
 ('disco_acquire_adds_balance_changes_type_and_resets_max', r'''local m=setmetatable({m_mapDiscoConfig={new={score=4}},m_cacheData={boostChargeNum=5,MaxChargeNum=20,curProperty='old',canPopUpWindow=false}},BoostChargeDiscoBoostHandler); PROPERTY_TYPE='type'; PROPERTY_COUNT='count'; EPropertySource={Give='give'}; EEventType={TriggerBoostDiscoStarted='start'}; EBIType={TriggerBoostBuffActivation='activation'}; local order={}; m.SaveCacheData=function() order[#order+1]='save' end; EventDispatcher={DispatchEvent=function(e) assert(e=='start'); order[#order+1]='event' end}; GM.ActivityManager={GetModel=function() return nil end}; GM.BIManager={LogAction=function() end,LogAcquire=function() end}; m:Acquire({type='new',count=3},{scene='test',source='give'}); assert(m.m_cacheData.boostChargeNum==17 and m.m_cacheData.MaxChargeNum==17 and m.m_cacheData.curProperty=='new' and m.m_cacheData.canPopUpWindow==true); assert(table.concat(order,',')=='save,event'); m:PopWindowFinished(); assert(m.m_cacheData.canPopUpWindow==false and m.m_cacheData.boostChargeNum==17 and m:IsDiscoDoing())'''),
 ('disco_missing_reward_config_does_not_activate', r'''local m=setmetatable({m_mapDiscoConfig={}},BoostChargeDiscoBoostHandler); PROPERTY_TYPE='type'; PROPERTY_COUNT='count'; m.SaveCacheData=function() error('must not save') end; m:Acquire({type='missing',count=3},{}); assert(m.m_cacheData==nil)'''),
]

def main():
    results=[]
    for name, code in CASES:
        lua=LuaRuntime(unpack_returned_tuples=True)
        try:
            lua.execute(SETUP)
            for key,path in FILES.items():
                source=path.read_text(encoding='utf-8')
                if key=='boot_require':
                    lua.globals().recoveredRequireChunk=source[source.index('local formerRequire = require'):source.index('package.path =')]
                else:
                    lua.execute(source)
            lua.execute("LuckyProduceModel.Try2ProduceLuckyItem({GetState=function() return nil end})")
            lua.execute(code)
            results.append({'id':name,'status':'passed','input_and_assertions':code})
        except Exception as e:
            results.append({'id':name,'status':'failed','error':str(e),'input_and_assertions':code})
    payload={'verification_kind':'recovered-source-execution', 'original_client_runtime_confirmed':False,
             'environment':'Lupa Lua 5.3; recovered modules; controlled RNG and explicitly mocked GM/DB services',
             'source_hashes':{k:hashlib.sha256(v.read_bytes()).hexdigest() for k,v in FILES.items()},
             'limitations':'Selected rules only; mocks do not verify original events, account configs, Unity or native persistence. Not all branches or full operation closure.',
             'cases':results,'passed':sum(r['status']=='passed' for r in results),'total':len(results)}
    out=STAGE/'generator_gate_audit/source_rule_tests.json'
    out.write_text(json.dumps(payload,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'passed':payload['passed'],'total':len(results),'failures':[r for r in results if r['status']=='failed']},ensure_ascii=False))
    if payload['passed']!=len(results): raise SystemExit(1)


if __name__=='__main__': main()
