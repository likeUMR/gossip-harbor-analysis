"""Execute selected order rules from original converted bytecode and recovered Lua.
Dependencies are explicit controlled doubles, not the original Unity runtime.
"""
import json
from lupa.lua53 import LuaRuntime
from stage3_order_documents import AUDIT
from stage3_merge_documents import ROOT,BY_NAME,source,sha

NAMES=['Board.Model.Base.BoardPosition','Board.Model.Board.BaseBoardModel',
 'Board.Model.Board.BaseActionBoardModel','Board.Model.Board.MainBoardModel',
 'Board.Model.Order.BaseOrder','Board.Model.Order.SlotOrder','Board.Model.Order.MainOrderDefinition',
 'Board.Model.Order.MainOrder','Board.Model.Order.SlotOrderModel',
 'Board.Model.Order.MainOrderCreator','Board.Model.Order.MainOrderCreatorRandom',
 'UI.Window.Board.UseInventoryItemConfirmWindow','ChestCustomer.Model.ChestCustomerModel',
 'Board.Model.RandomGenerateCodeHelper','Board.Model.Order.EmptyReqOrder',
 'Board.Model.Order.TutorialOrderModel','Contiorders.Model.ContiordersModel',
 'ExtraCustomerActivity.Model.ExtraCustomerActivityModel']
SETUP=r'''
EBoardType={Empty=0,Main=1}; BaseOrderModel={};BaseActivityModel={};BaseWindow={OnCloseFinish=function() log('baseClose') end}
EGameMode={Main=1};CacheItemType={Type2=2};EPropertySource={Give=1};EBIType={FinishOrder='finish',FinishOrderRemoveItemError='removeError'}
EEventType={OrderFinished='orderFinished',ChestCustomerOrderFinish='chest',SmileOrderDeliver_1='smile'}
EOrderBoostType={Normal=1};BoardEventType={FinishOrder='localFinish'}
Sec2Hour=3600;ItemType={Flour09='209',Flour12='212'}
ActivityType={OrderBoost='boost',ChestCustomer='chest',Puzzle='puzzle'};ActivityState={Started='started'}
OrderModelType={Slot='slot'};PROPERTY_TYPE='type';PROPERTY_COUNT='count'
StringUtil={IsNilOrEmpty=function(v) return v==nil or v=='' end}
trace={};function log(v) trace[#trace+1]=v end
Log={Assert=function(v,m) assert(v,m) end,Error=function() log('error') end,Info=function() end,Debug=function() end}
function copy(t) if type(t)~='table' then return t end local r={} for k,v in pairs(t) do r[k]=copy(v) end return r end
Table={Empty={},IsEmpty=function(t) return t==nil or next(t)==nil end,DeepCopy=copy,
 GetKey=function(t,v) for k,x in pairs(t) do if x==v then return k end end end,
 ListWeightSelectOne=function(t) log('weightDraw');return t[1] end,
 ListRandomSelectOne=function(t) log('uniformDraw');return t[1] end}
MathUtil={IntPow=function(a,b) return a^b end}
GameConfig={IsTestMode=function() return false end}
EventDispatcher={DispatchEvent=function(e) log('event:'..e) end}
now=1000; GM={GameModel={GetServerTime=function() return now end,GetMonthPay=function() return 0 end},
 LevelModel={GetCurrentLevel=function() return 10 end}, BIManager={LogErrorInfo=function() log('error') end},
 CharacterIntimacyModel={IsOpen=function() return false end},
 CustomerUpgradeRewardModel={CanFillChestCustomerOrder=function() return false end},
 SyncModel={CheckMoreUpload=function(_,a,b,r) assert(a==nil and b==nil);log('sync') end}}
local boost={GetAddSmileScoreBySlot=function() return 0 end}
local chest={IsChestCustomerOrder=function() return false end}
GM.ActivityManager={GetModel=function(_,k) if k=='boost' then return boost elseif k=='chest' then return chest else return {GetSlotTokenNumber=function() return 0 end} end end,GetStartedButterflyActivity=function() return nil end}
RewardApi={AcquireRewardsLogic=function(r) log('acquire:'..r[1].type) end}
function db(t) return {data=t or {},GetValue=function(self,k,c) return self.data[k] end,Set=function(self,k,c,v) self.data[k]=v;log('db:'..k..'='..v) end} end
function window(member,cb)
 local b={GetOrderModel=function() return {ContainsOrder=function() return member end} end,FinishOrder=function() log('finish') end}
 return setmetatable({m_boardModel=b,m_orderModel={},m_callback=cb,Close=function() log('close') end},UseInventoryItemConfirmWindow)
end
function reqorder(r) return {GetRequirements=function() return r end} end
function board(r,stored)
 local b=setmetatable({grid=r or {},m_gameMode=1},MainBoardModel)
 b.GetItem=function(self,p) return self.grid[p:GetKey()] end
 b.RemoveItem=function(self,it,auto) assert(auto==false);self.grid[it.pos:GetKey()]=nil;log('remove:'..it.code) end
 b._RemoveItemProperty=function() log('removeProperty') end
 b.CountItemsCode=function() log('count') end;b.UpdateOrderState=function() log('refresh') end
 b.m_itemStoreModel={items=stored or {},GetItemCount=function(self) return #self.items end,GetItem=function(self,i) return self.items[i] end,RemoveItem=function(self,i) table.remove(self.items,i);log('storeRemove') end}
 return b
end
function item(c,x,y) return {code=c,pos=BoardPosition.Create(x,y),GetCode=function(self) return self.code end} end
'''
CASES=[
 ('duplicate_requirement_deficit',r'''local o=BaseOrder.Create(1,{'203','203','204'});local ok,l=o:CanDeliver({['203']=1});assert(not ok and l['203']==1 and l['204']==1)'''),
 ('three_repeats_final_deficit',r'''local o=BaseOrder.Create(1,{'x','x','x'});local ok,l=o:CanDeliver({x=1});assert(not ok and l.x==2)'''),
 ('empty_requirements_pass_dormant',r'''local o=BaseOrder.Create(1,{'',''});local ok,l=o:CanDeliver({});assert(ok and next(l)==nil and o:GetState()==0)'''),
 ('partial_state_and_time',r'''local o=BaseOrder.Create(1,{'x','x'});o:UpdateState({x=1});assert(o:GetState()==2 and o:GetFilledRequirementCount()==1);now=1200;o:UpdateState({x=1});assert(o:GetStateChangeTime()==1000);o:UpdateState({x=2});assert(o:GetState()==3 and o:GetStateChangeTime()==1200)'''),
 ('finished_state_not_recomputed',r'''local o=BaseOrder.Create(1,{'x'});o.GetRewards=function() return {{type='Gold',count=8}} end;o:SetFinished();now=2000;o:UpdateState({});assert(o:GetState()==4 and o:GetStateChangeTime()==1000 and o.m_cacheRewards[1].count==8)'''),
 ('window_cancel_no_delivery',r'''local w=window(true);w:OnRedClick();w:OnCloseFinish();assert(table.concat(trace,',')=='close,baseClose')'''),
 ('window_green_waits_close',r'''local w=window(true);w:OnGreenClick();assert(table.concat(trace,',')=='close');w:OnCloseFinish();assert(table.concat(trace,',')=='close,baseClose,finish')'''),
 ('window_member_removed',r'''local w=window(false);w:OnGreenClick();w:OnCloseFinish();assert(table.concat(trace,',')=='close,baseClose')'''),
 ('window_callback_overrides_membership',r'''local w=window(false,function() log('callback') end);w:OnGreenClick();w:OnCloseFinish();assert(table.concat(trace,',')=='close,baseClose,callback')'''),
 ('window_no_material_revalidation',r'''local w=window(true);w.m_orderModel.CanDeliver=function() error('must not recheck') end;w:OnGreenClick();w:OnCloseFinish();assert(trace[3]=='finish')'''),
 ('price_and_diff_duplicate',r'''local configs={['203']={Price=2,DiffScore=2},['204']={Price=4,DiffScore=5}};local o=setmetatable({m_requirements={'203','203','204'},m_innerType=1,m_orderModel={GetItemCodeConfigMap=function() return configs end}},MainOrder);assert(o:GetPrice()==8 and o:GetDiffScore()==9)'''),
 ('baseline_recommended_price',r'''local o=setmetatable({m_bIsBaseline=true,m_requirements={'x','y'},m_orderModel={GetItemCodeConfigMap=function() return {x={Price=2,RecommendedPrice=7},y={Price=4}} end}},MainOrder);assert(o:GetPrice()==11)'''),
 ('missing_config_discards_sum',r'''local o=setmetatable({m_innerType=1,m_requirements={'x','missing'},m_orderModel={GetItemCodeConfigMap=function() return {x={Price=2,DiffScore=2}} end}},MainOrder);assert(o:GetPrice()==0 and o:GetDiffScore()==0 and #trace==2)'''),
 ('board_valid_row_order',r'''local b=board();local keys={};for p in b:GetValidPositionIterator() do keys[#keys+1]=p:GetKey() end;assert(#keys==63 and keys[1]=='1_1' and keys[7]=='7_1' and keys[8]=='1_2' and keys[63]=='7_9')'''),
 ('board_first_store_fallback_sparse',r'''local b=board({['1_1']=item('203',1,1),['2_1']=item('203',2,1)},{item('204',1,1)});local r=b:RemoveOrderRequirementItems(reqorder({'203','203','204'}));assert(r.RemovedFromBoard[1].pos:GetKey()=='1_1' and r.RemovedFromBoard[2].pos:GetKey()=='2_1' and r.RemovedFromBoard[3]==nil);assert(r.RemovedFromInventory[1]==nil and r.RemovedFromInventory[3]=='204' and #b.m_itemStoreModel.items==0)'''),
 ('missing_item_continues_later_requirement',r'''local b=board({['1_1']=item('y',1,1)});local r=b:RemoveOrderRequirementItems(reqorder({'missing','y'}));assert(r.RemovedFromBoard[1]==nil and r.RemovedFromBoard[2]~=nil);assert(table.concat(trace,',')=='count,refresh,error,remove:y,count,refresh')'''),
 ('board_precedes_available_store',r'''local b=board({['1_1']=item('x',1,1)},{item('x',1,1)});b:RemoveOrderRequirementItems(reqorder({'x'}));assert(#b.m_itemStoreModel.items==1)'''),
 ('slot_nonmember_no_effect',r'''local s=setmetatable({ContainsOrder=function() return false end},SlotOrderModel);assert(s:FinishOrder({})==false and #trace==0)'''),
 ('slot_completion_before_event',r'''local s=setmetatable({ContainsOrder=function() return true end,_LogOrderAction=function() log('log') end,_TryFillOrders=function() log('fill') end},SlotOrderModel);assert(s:FinishOrder({SetFinished=function() log('mark') end}));assert(table.concat(trace,',')=='mark,log,fill,event:orderFinished')'''),
 ('fill_retry_after_other_slot_success',r'''local round=0;local s=setmetatable({m_orders={},m_slotCount=2,m_boardModel={UpdateOrderState=function() log('refresh') end},_DBAddOrder=function(_,o) log('save:'..o.slot) end,_LogOrderAction=function(_,o) log('unlock:'..o.slot) end,_TryCreateOrder=function(_,slot) if slot==1 then round=round+1;if round==1 then return nil end end return {slot=slot,GetState=function() return 1 end} end},SlotOrderModel);s:_TryFillOrders();assert(round==2 and s.m_orders[1] and s.m_orders[2]);assert(table.concat(trace,',')=='save:2,save:1,refresh,unlock:2,unlock:1')'''),
 ('random_qualification_consumes_point',r'''local d=db({timer='0',Random1OrderPoints='1'});local o={GetMetaData=function() return d end};assert(RandomOrderHelper.CanCreate(o,'timer',{Type=1,Point=5,RefreshTime=3600}));assert(d.data.Random1OrderPoints=='0');assert(not RandomOrderHelper.CanCreate(o,'timer',{Type=1,Point=5,RefreshTime=3600}));assert(d.data.timer=='1000')'''),
 ('random_cd_boundary',r'''local d=db({timer='1000'});local o={GetMetaData=function() return d end};now=4599;assert(not RandomOrderHelper.CanCreate(o,'timer',{Type=1,Point=5,RefreshTime=3600}));now=4600;assert(RandomOrderHelper.CanCreate(o,'timer',{Type=1,Point=5,RefreshTime=3600}));assert(d.data.timer=='0' and d.data.Random1OrderPoints=='4')'''),
 ('filter_first_match_inclusive',r'''local a={PlayerMin=10,PlayerMax=10,DiffSumMin=100,DiffSumMax=100,sMonthPay=0,eMonthPay=0};local b={};assert(RandomOrderHelper.GetSelectedFilterConfig({Filters={a,b}},{GetTotalDiffScore=function() return 100 end},1,true)==a)'''),
 ('filter_no_match_nil',r'''assert(RandomOrderHelper.GetSelectedFilterConfig({Filters={{PlayerMin=11}}},{GetTotalDiffScore=function() return 100 end},1,true)==nil)'''),
 ('repeat_weight_divisor_not_counter',r'''GM.ItemDataModel={GetChainId=function() return 'chain' end};local pool={{Code='x',Weight=100}};local info={mapChainRepeatWeight={chain=3},SelectedSynthesisLine={},TestLogInfo={}};local o={GetItemCodeConfigMap=function() return {x={RepeatWeightDecrease=4}} end};RepeatWeightDecreaseHelper.DecreaseItemWeight(pool,info,o);assert(pool[1].Weight==25 and info.SelectedSynthesisLine.chain==true);RepeatWeightDecreaseHelper.MarkSelectedLine('x',info,o);assert(info.SelectedSynthesisLine.chain==false)'''),
 ('chest_uniform_budget_overshoot_repeat',r'''local m=setmetatable({},ChestCustomerModel);local r,c=m:FindNormalRewardConfig(5,{rewards={{type='x',count=3}}},'');assert(#r==2 and r[1].count==1 and r[2].type=='x' and c==6)'''),
 ('chest_zero_budget_no_draw',r'''local m=setmetatable({},ChestCustomerModel);local r,c=m:FindNormalRewardConfig(0,{rewards={{type='x',count=3}}},'');assert(#r==0 and c==0 and #trace==0)'''),
 ('chest_inactive_no_work',r'''local m=setmetatable({GetState=function() return 'ended' end},ChestCustomerModel);m:AcquireChestCustomOrderReward({});assert(#trace==0)'''),
 ('chest_old_pick_ceiling',r'''GM.ItemDataModel={GetChainId=function() return 'chain' end,GetChainLevel=function() return 3 end,GetTypeByChainAndLevel=function(_,c,l) return 'x'..l end};local out={};local left=RandomGenerateCodeHelper._PickItems_old({code='x3'},{x3={DiffScore=30},x2={DiffScore=7},x1={DiffScore=2}},10,out,nil,0,'');assert(#out==2 and out[1]=='x2' and left==-4)'''),
 ('chest_new_pick_lack_stops_first',r'''GM.ItemDataModel={GetChainId=function() return 'chain' end,GetChainLevel=function(_,c) if c=='x3' then return 3 else return 2 end end,GetTypeByChainAndLevel=function(_,c,l) return 'x'..l end};local out={};local lacks={x3=1};local left=RandomGenerateCodeHelper._PickItems_new({code='x3'},{x3={DiffScore=30},x2={DiffScore=7}},10,out,nil,0,'',lacks);assert(#out==1 and left==3 and lacks.x3==-1)'''),
]

FINISH=r'''
local b=board();b.m_orderModels={{ContainsOrder=function() return owner end,FinishOrder=function() log('ownerFinish') end}}
b.RemoveOrderRequirementItems=function() log('consume');return {} end
b.TryAcquireCookingFrenzyReward=function() log('cooking') end
b.event={Call=function(_,e,msg) log('localFinish');assert(msg.Rewards[1].type=='Gold') end}
local o={GetInnerType=function() return 1 end,GetOrderRewardByFinishOrder=function() log('getRewards');return {{type='Gold',count=8}}, {chest={{type='delayed'}}} end,
GetGiftRewards=function() return nil end,GetGameMode=function() return 1 end,GetSlot=function() return 1 end,
SetFinished=function() log('mark') end,GetRequirements=function() return {'203'} end}
'''
CASES += [
 ('ordinary_finish_order_sequence',FINISH+r'''owner=true;b:FinishOrder(o);assert(table.concat(trace,',')=='getRewards,acquire:Gold,mark,consume,cooking,acquire:delayed,ownerFinish,refresh,sync,localFinish')'''),
 ('ordinary_nonmember_still_awards',FINISH+r'''owner=false;b:FinishOrder(o);assert(table.concat(trace,',')=='getRewards,acquire:Gold,mark,consume,cooking,acquire:delayed,refresh,sync,localFinish')'''),
 ('special_dispatch_early_return',r'''local b=board();b._FinishSpecialOrder=function() log('special') end;b:FinishOrder({GetInnerType=function() return 5 end});assert(table.concat(trace,',')=='special')'''),
 ('branch_dispatch_early_return',r'''local b=board();b._FinishBranchOrder=function() log('branch') end;b:FinishOrder({GetInnerType=function() return 7 end});assert(table.concat(trace,',')=='branch')'''),
 ('lucky_missing_config_still_consumes_trigger',r'''local d=db();local o={CanTriggerLucky=function() return true end,CloseTriggerLucky=function() log('closeTrigger') end,GetMetaData=function() return d end,GetLuckyOrderConfig=function() return nil end};assert(not MainOrderCreatorLuckyOrder.CanCreate(o,17));assert(table.concat(trace,',')=='closeTrigger')'''),
 ('lucky_one_point_starts_cd_no_create',r'''local d=db({LuckyOrderPoints='1'});local o={CanTriggerLucky=function() return true end,CloseTriggerLucky=function() log('closeTrigger') end,GetMetaData=function() return d end,GetLuckyOrderConfig=function() return {UnlockLevel=3,RefreshTime=3600} end};assert(not MainOrderCreatorLuckyOrder.CanCreate(o,17));assert(d.data.LuckyOrderPoints=='0' and d.data.LuckyOrderTimer=='1000')'''),
 ('lucky_two_points_qualify_without_decrement',r'''local d=db({LuckyOrderPoints='2'});local o={CanTriggerLucky=function() return true end,CloseTriggerLucky=function() log('closeTrigger') end,GetMetaData=function() return d end,GetLuckyOrderConfig=function() return {UnlockLevel=3,RefreshTime=3600} end};assert(MainOrderCreatorLuckyOrder.CanCreate(o,17));assert(d.data.LuckyOrderPoints=='2')'''),
 ('lucky_cd_inclusive',r'''local d=db({LuckyOrderPoints='0',LuckyOrderTimer='1000'});local o={CanTriggerLucky=function() return true end,CloseTriggerLucky=function() end,GetMetaData=function() return d end,GetLuckyOrderConfig=function() return {UnlockLevel=3,RefreshTime=3600} end};now=4599;assert(not MainOrderCreatorLuckyOrder.CanCreate(o,17));now=4600;assert(MainOrderCreatorLuckyOrder.CanCreate(o,17))'''),
 ('branch_pool_all_six_cache',r'''local b=board();b.m_orderModels={slot={FinishOrder=function() log('owner') end}};b.GetSpecialOrderConfig=function() return {Requirement='x',GeneratorChain={},Rewards={},EndTimeline='end'} end;GM.ItemDataModel={GetChainId=function() return 'chain' end};b._BatchRemoveItems=function() log('batch');return {} end;ItemModelFactory={GetCodeAndWeightPairs=function() return {{Code='2402',Weight=2},{Code='2405',Weight=1},{Code='2502',Weight=2},{Code='2503',Weight=1}} end};b.FindEmptyPositionInValidOrder=function() return nil end;local emitted={};b.CacheItems=function(_,r,t) assert(t==2);emitted[r[1]]=(emitted[r[1]] or 0)+1 end;GM.MapDataModel={SetSlot=function(_,k,v) assert(k=='end' and v=='1');log('timeline') end};b.event={Call=function(_,e,m) assert(#m.New==0);log('finish') end};b:_FinishBranchOrder({});assert(emitted['2402']==2 and emitted['2405']==1 and emitted['2502']==2 and emitted['2503']==1)'''),
 ('empty_req_dormant_rejects_delivery',r'''local o=EmptyReqOrder.Create({},19,1,{},21,3001,false);assert(o:GetState()==0 and not o:CanDeliver({}) and #o:GetRewards()==0 and o:GetDiffScore()==0)'''),
 ('extra_cooldown_strict_and_remaining_hour',r'''GM.MainBoardModel={GetOrders=function() return {} end};local m=setmetatable({m_config={eTime=4600},GetState=function() return 'started' end,HasActiveOrder=function() return false end,GetCoolDownTime=function() return 1000 end},ExtraCustomerActivityModel);now=1000;assert(not m:CanCreateOrder(19));m.m_config.eTime=4601;now=1001;assert(m:CanCreateOrder(19));m.m_config.eTime=4600;assert(not m:CanCreateOrder(19))'''),
 ('conti_gate_nil_flag_and_window',r'''GM.UIManager={GetOpenedViewByName=function() return nil end};local m=setmetatable({m_definition={MainWindowPrefabName='window'},GetState=function() return 'started' end,GetStarted=function() return true end,GetIndex=function() return 0 end,GetTotalOrderCount=function() return 5 end},ContiordersModel);assert(m:CanCreateOrder(18));m.m_canCreateOrderFlag=false;assert(not m:CanCreateOrder(18));m.m_canCreateOrderFlag=true;GM.UIManager.GetOpenedViewByName=function() return {} end;assert(not m:CanCreateOrder(18))'''),
 ('tutorial_completion_after_fill_same_slot',r'''local d=db();local m=setmetatable({m_dbTable=d,GetCurOrderAndState=function() return 1,'2' end,GetTutorialInfoById=function() return {Slot=11} end},TutorialOrderModel);m:OnOrderFinished({order={GetSlot=function() return 1 end}});assert(next(d.data)==nil);m:OnOrderFinished({order={GetSlot=function() return 11 end}});assert(d.data.TutorialOrderModel_CurTutorialID=='2_1')'''),
]

def run():
 results=[]
 for kind in ('bytecode','recovered-source'):
  for name,body in CASES:
   lua=LuaRuntime();lua.execute(SETUP);r=dict(case=name,kind=kind)
   try:
    for module in NAMES:
     m=BY_NAME[module];lua.execute((ROOT/m['standard_path']).read_bytes() if kind=='bytecode' else source(module).read_text(encoding='utf-8'))
    lua.execute(body);r['status']='passed';t=lua.globals().trace;r['trace']=[t[i] for i in range(1,len(t)+1)]
   except Exception as exc:r.update(status='failed',error=str(exc))
   results.append(r)
 report=dict(passed=sum(r['status']=='passed' for r in results),total=len(results),cases=results,
  original_client_runtime_confirmed=False,limitations='Selected real functions with explicit service doubles; not full operation closure or original runtime/native DB verification.',
  module_hashes={n:dict(bytecode=BY_NAME[n]['sha256'],source=sha(source(n))) for n in NAMES})
 AUDIT.mkdir(exist_ok=True);(AUDIT/'rule_tests.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps(dict(passed=report['passed'],total=report['total'],failed=[r for r in results if r['status']=='failed']),ensure_ascii=False,indent=2))
 if report['passed']!=report['total']:raise SystemExit(1)
if __name__=='__main__':run()
