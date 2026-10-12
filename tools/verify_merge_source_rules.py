"""Controlled original converted-bytecode and recovered-source comparison.

No Unity/client/server or native persistence is exercised. Dependencies are
explicit doubles; these cases verify selected rules, never full closure.
"""
import json
from lupa.lua53 import LuaRuntime
from stage3_merge_documents import ROOT, AUDIT, BY_NAME, source, sha

NAMES=[
 'Board.Model.Base.BoardPosition','Board.Model.Board.BaseBoardModel',
 'Board.Model.Board.BaseActionBoardModel','Board.Model.Board.MainBoardModel',
 'Board.Model.Board.BaseItemLayerModel','Board.Model.Item.ItemModel',
 'Board.Model.Item.ItemSwallow','Board.Model.Item.ItemSplit',
 'CardItem.CardItemModel','EnergyBubble.Model.EnergyBubbleModel',
 'BubbleDecrease.Model.BubbleDecreaseModel','TempItem.Model.TempItemModel',
 'Board.Model.Board.ItemFixedSwallowModel',
]
SETUP=r'''
EBoardType={Empty=0,Main=1}; BaseItemComponent={}; BaseActivityModel={}; Sec2Day=86400
EnergyType={Main=1}; ActivityType={ScoreRace='score',TempItem='temp',CardItem='card',EnergyBubble='energy',BubbleSale='sale'}
ItemSpecialType={LevelUp=1,LevelDown=2}; ActivityState={Started='started'}
ItemPaperBox='paper'; ItemCobweb='web'; ItemLocked='locked'; ItemSwallow='swallow'
ItemSpread='spread'; ItemTemp='temp'; ItemTransform='transform'; ItemAccelerate='accelerate'
ItemBubble='bubble'; ItemSplit='split'; ItemCodePrefix={Bubble='bubble_'}; ItemCodeOffset={Bubble=30000}
BoardEventType={MergeItem='localMerge',SplitItem='localSplit'}
BoardSpreadType={CardItem='card'}
EEventType={ItemMoveEnd='moveEnd',ItemMerged='globalMerge',ItemShocked='shock',BubbleSpread='bubble'}
EBIType={}; ItemType={Coin01='coin'}; SystemConfigKey={SpreadCoinMinChainLevel='coinLevel'}
EFunction={Bubble='bubble'}; EGeneralConfType={BubbleOrderBonus='bonus',BubbleOrderDecrease='orderDecrease',BubbleChainDecreaseLevel='chainLevel',BubbleChainDecreaseRatio='chainRatio'}
ConfigModel={EGeneralConfigParam={Int='int',Float='float'}}; OrderModelType={Slot='slot'}
GameConfig={IsTestMode=function() return false end}; PlayerPrefs={GetInt=function() return 0 end}
EPlayerPrefKey={TestBubbleMustSpread='forceBubble',TestForceCreateCard='forceCard'}
Log={Debug=function() end,Assert=function(v,msg) assert(v,msg) end}
function IsNil(v) return v==nil end
Table={IsEmpty=function(t) return t==nil or next(t)==nil end}
function db()
 return {data={},GetValue=function(self,k,c) return self.data[k..':'..c] end,
 Set=function(self,k,c,v) self.data[k..':'..c]=v end}
end
trace={}; function log(v) trace[#trace+1]=v end
EventDispatcher={DispatchEvent=function(e) log('event:'..e) end}
now=1000; conf={}
GM={GameModel={GetServerTime=function() return now end},
 ConfigModel={GetGeneralConfByType=function(_,k) return conf[k] end,HasBubbleBuyBonus=function() return true end},
 OpenFunctionModel={IsFunctionOpen=function() return true end},
 BubbleDecreaseModel={GetBubbleDecreaseRatio=function() return 1 end}}
function item(code,pos,components,nextType,special)
 return {code=code,pos=pos,components=components or {},nextType=nextType,special=special,
 GetPosition=function(self) return self.pos end,SetPosition=function(self,p) self.pos=p; log('position:'..code) end,
 GetType=function(self) return self.code end,GetCode=function(self) return self.code end,
 GetMergedType=function(self) return self.nextType end,GetSpecialType=function(self) return self.special end,
 GetComponent=function(self,k) return self.components[k] end}
end
function board()
 return setmetatable({HorizontalTiles=7,VerticalTiles=9,grid={},
 GetItem=function(self,p) return p and self.grid[p:GetKey()] end,
 _SetItem=function(self,p,i,auto) self.grid[p:GetKey()]=i; log('write:'..p:GetKey()..':'..tostring(auto)) end,
 _LogMove=function() log('logMove') end,_UpdateAccelerate=function() log('accelerate') end,
 IsGeneratorFactoryOpen=function() return false end},MainBoardModel)
end
function bubble(p)
 local b=board(); b.IsBoardFull=function() return false end
 b._HasBubbleItemWithInnerCode=function() return false end
 b._CanBubbleBuyBonus=function() return false end; b._CanBubbleOrderBonus=function() return false end
 b._GetDecreaseBubbleChanceRatio=function() return nil end; b._GetDecreaseBubbleChanceRatio2=function() return nil end
 b.FindEmptyPositionInSpreadOrder=function() return BoardPosition.Create(3,3) end
 b.SpreadItem=function() log('spreadBubble') end
 local n=item('204',BoardPosition.Create(4,3)); n.GetBubbleChance=function() return p end
 local t=item('203',BoardPosition.Create(4,3)); return b,n,t
end
MathUtil={Random=function(n) log('rng:'..n); return 1 end}
'''
CASES=[
 ('coordinate_edges',r'''local b=board(); assert(b:PositionIsValid(BoardPosition.Create(1,1))); assert(b:PositionIsValid(BoardPosition.Create(7,9))); assert(not b:PositionIsValid(BoardPosition.Create(0,3))); assert(not b:PositionIsValid(BoardPosition.Create(8,9)))'''),
 ('stale_identity_same_code',r'''local b=board(); local p=BoardPosition.Create(3,3); local old=item('201',p); b.grid[p:GetKey()]=item('201',p); b:DragItem(old,BoardPosition.Create(4,3)); assert(#trace==1 and trace[1]=='position:201')'''),
 ('same_cell_still_move_end',r'''local b=board(); local p=BoardPosition.Create(3,3); local a=item('201',p); b.grid[p:GetKey()]=a; b:DragItem(a,p); assert(#trace==5 and trace[5]=='event:moveEnd'); for _,v in ipairs(trace) do assert(v~='logMove') end'''),
 ('empty_move_no_order_auto',r'''local b=board(); local p=BoardPosition.Create(3,3); local a=item('201',p); b.grid[p:GetKey()]=a; b:DragItem(a,BoardPosition.Create(4,3)); assert(trace[1]=='write:3_3:false' and trace[2]=='write:4_3:false' and trace[6]=='event:moveEnd')'''),
 ('swap_third_write_default',r'''local b=board(); local s=BoardPosition.Create(3,3); local t=BoardPosition.Create(4,3); local a=item('201',s); local z=item('202',t); b.grid[s:GetKey()]=a; b.grid[t:GetKey()]=z; b.CanItemAffect=function() return false end; b.CanItemMerge=function() return false end; b.CanItemMove=function() return true end; b:DragItem(a,t); assert(trace[3]=='write:3_3:nil'); assert(a.pos==t and z.pos==s); for _,v in ipairs(trace) do assert(v~='event:moveEnd') end'''),
 ('special_priority_stops_merge',r'''local b=board(); local s=BoardPosition.Create(3,3); local t=BoardPosition.Create(4,3); local a=item('201',s); b.grid[s:GetKey()]=a; b.grid[t:GetKey()]=item('201',t); b.CanItemAffect=function() return true end; b._AffectItem=function() log('special'); return true end; b.CanItemMerge=function() error('merge must not run') end; b:DragItem(a,t); assert(trace[1]=='special' and #trace==1)'''),
 ('ordinary_merge_before_swallow',r'''local b=board(); local s=BoardPosition.Create(3,3); local t=BoardPosition.Create(4,3); local a=item('201',s); local z=item('201',t,{[ItemSwallow]={CanSwallow=function() error('swallow must not run') end}}); b.grid[s:GetKey()]=a; b.grid[t:GetKey()]=z; b.CanItemAffect=function() return false end; b.CanItemMerge=function() return true end; b._MergeItem=function() log('merge') end; b:DragItem(a,t); assert(trace[1]=='merge')'''),
 ('source_mobility_not_rechecked_model',r'''local b=board(); local s=BoardPosition.Create(3,3); local a=item('201',s,{[ItemLocked]={}}); b.grid[s:GetKey()]=a; b:DragItem(a,BoardPosition.Create(4,3)); assert(a.pos:GetX()==4)'''),
 ('target_locked_reverts_after_failed_routes',r'''local b=board(); local s=BoardPosition.Create(3,3); local t=BoardPosition.Create(4,3); local a=item('201',s); b.grid[s:GetKey()]=a; b.grid[t:GetKey()]=item('202',t,{[ItemLocked]={}}); b.CanItemAffect=function() return false end; b.CanItemMerge=function() return false end; b:DragItem(a,t); assert(#trace==1 and trace[1]=='position:201')'''),
 ('merge_second_plain_overwrites_next',r'''local b=board(); local p=BoardPosition.Create(1,1); assert(not b:CanItemMerge(item('x',p,{},'y'),item('x',p,{},nil))); assert(b:CanItemMerge(item('x',p,{},nil),item('x',p,{},'y')))'''),
 ('wrapper_target_and_double_wrapper',r'''local b=board(); local p=BoardPosition.Create(1,1); local w={GetInnerItemCode=function() return '201' end}; assert(b:CanItemMerge(item('201',p,{},'202'),item('web201',p,{[ItemCobweb]=w}))); assert(not b:CanItemMerge(item('web201',p,{[ItemCobweb]=w}),item('web201',p,{[ItemCobweb]=w})))'''),
 ('used_chest_blocks_merge',r'''local b=board(); local p=BoardPosition.Create(1,1); local used={IsChestUsedOnce=function() return true end}; assert(not b:CanItemMerge(item('x',p,{[ItemSpread]=used},'y'),item('x',p,{},'y')))'''),
 ('full_board_double_scissors_exception',r'''local z=setmetatable({m_specialType=2,m_boardModel={IsBoardFull=function() return true end}},ItemModel); assert(z:CanSpecialTypeAffect(2)); z.m_specialType=nil; z.m_mapSpecialTypeTarget={[2]=true}; assert(not z:CanSpecialTypeAffect(2))'''),
 ('accelerate_twice',r'''local b=board(); local p=BoardPosition.Create(1,1); b.UpdatePerSecond=function() log('tick') end; local a=item('x',p,{[ItemTransform]={CanAccelerate=function() return true end}}); MainBoardModel._UpdateAccelerate(b,a,nil); assert(#trace==2 and trace[1]=='tick' and trace[2]=='tick')'''),
 ('spread_ring_seventh_slot',r'''local model=board(); local b=setmetatable({m_boardModel=model,GetItem=function(_,p) if p:GetKey()~='3_3' then return true end end},BaseItemLayerModel); local p=b:FindEmptyPositionInSpreadOrder(BoardPosition.Create(4,3)); assert(p:GetKey()=='3_3')'''),
 ('spread_ring_first_and_fallback',r'''local model=board(); local b=setmetatable({m_boardModel=model,GetItem=function() return nil end},BaseItemLayerModel); assert(b:FindEmptyPositionInSpreadOrder(BoardPosition.Create(4,3)):GetKey()=='4_2'); b.GetItem=function() return true end; local fallback=BoardPosition.Create(2,2); assert(b:FindEmptyPositionInSpreadOrder(BoardPosition.Create(4,3),fallback)==fallback)'''),
 ('zero_bubble_still_draws',r'''local b,n,t=bubble(0); assert(b:_TrySpreadBubbleByMerge(n,t)==nil); assert(#trace==1 and trace[1]=='rng:100')'''),
 ('full_board_no_bubble_rng',r'''local b,n,t=bubble(3); b.IsBoardFull=function() return true end; b:_TrySpreadBubbleByMerge(n,t); assert(#trace==0)'''),
 ('duplicate_bubble_no_rng',r'''local b,n,t=bubble(3); b._HasBubbleItemWithInnerCode=function() return true end; b:_TrySpreadBubbleByMerge(n,t); assert(#trace==0)'''),
 ('bubble_multipliers_order_and_floor',r'''local b,n,t=bubble(3); b._GetDecreaseBubbleChanceRatio=function() log('r1'); return 0.5 end; b._GetDecreaseBubbleChanceRatio2=function() log('r2'); return 0.64 end; GM.BubbleDecreaseModel.GetBubbleDecreaseRatio=function() log('r3'); return 0.5 end; MathUtil.Random=function() log('rng'); return 1 end; assert(b:_TrySpreadBubbleByMerge(n,t)=='204'); assert(trace[1]=='r1' and trace[2]=='r2' and trace[3]=='r3' and trace[4]=='rng')'''),
 ('bonus_skips_multipliers',r'''local b,n,t=bubble(3); b._CanBubbleOrderBonus=function() return true end; b._GetDecreaseBubbleChanceRatio=function() error('should skip') end; MathUtil.Random=function() return 100 end; assert(b:_TrySpreadBubbleByMerge(n,t)=='204')'''),
 ('force_bubble_overrides_duplicate',r'''local b,n,t=bubble(0); b._HasBubbleItemWithInnerCode=function() return true end; GameConfig.IsTestMode=function() return true end; PlayerPrefs.GetInt=function() return 1 end; GM.BubbleDecreaseModel.RecordBubbleDecreaseInfo=function() end; assert(b:_TrySpreadBubbleByMerge(n,t)=='204')'''),
 ('purchase_type_helper_and_clear',r'''local b=board(); b.m_lastBreakBubbleType='203'; assert(b:_CanBubbleBuyBonus('203')); b.m_lastBreakBubbleType=nil; assert(not b:_CanBubbleBuyBonus('203'))'''),
 ('login_decrease_strict_day',r'''local days=3; GM.MiscModel={GetBubbleNoPurchaseLoginDaysInNumber=function() return days end}; local b=setmetatable({m_bGeneralConfEnabled=true,m_arrDays={3,5},m_mapDay2DecreaseRatio={[3]=50,[5]=25}},BubbleDecreaseModel); assert(b:GetBubbleDecreaseRatio()==1); days=4; assert(b:GetBubbleDecreaseRatio()==0.5); days=5; assert(b:GetBubbleDecreaseRatio()==0.5); days=6; assert(b:GetBubbleDecreaseRatio()==0.25)'''),
 ('energy_bubble_time_boundary_and_minutes',r'''local m=setmetatable({m_dbTable=db(),GetState=function() return 'started' end},EnergyBubbleModel); m.m_dbTable:Set('TriggerTime','value',1000); assert(not m:CanSpreadEnergyBubble()); now=1001; assert(m:CanSpreadEnergyBubble()); m:SetTriggerTime(5); assert(m:GetTriggerTime()==1301)'''),
 ('card_array_unlock_exits_before_rng',r'''GM.LevelModel={GetCurrentLevel=function() return 25 end}; local m=setmetatable({m_mapCardItemProduceConfig={x={{LevelMin=1,Chance=10000}}},m_mapCardItemTypeConfig={{UnlockLevel=25}},CanGenerateCardItem=function() return true end,GenerateCardItem=function() return 'card' end},CardItemModel); math.random=function() error('rng should not run') end; assert(m:TryGenerateItem('x')==nil)'''),
 ('card_string_keyed_map_skips_ipairs',r'''GM.LevelModel={GetCurrentLevel=function() return 25 end}; local m=setmetatable({m_mapCardItemProduceConfig={x={{LevelMin=1,Chance=10000}}},m_mapCardItemTypeConfig={chain={UnlockLevel=25}},CanGenerateCardItem=function() return true end,GenerateCardItem=function() return 'card' end},CardItemModel); math.random=function(n) assert(n==10000); log('rngCard'); return 10000 end; assert(m:TryGenerateItem('x')=='card'); assert(trace[1]=='rngCard')'''),
 ('card_threshold_inclusive',r'''GM.LevelModel={GetCurrentLevel=function() return 10 end}; local m=setmetatable({m_mapCardItemProduceConfig={x={{LevelMin=10,LevelMax=10,Chance=250}}},m_mapCardItemTypeConfig={},CanGenerateCardItem=function() return true end,GenerateCardItem=function() return 'card' end},CardItemModel); math.random=function() return 250 end; assert(m:TryGenerateItem('x')=='card'); math.random=function() return 251 end; assert(m:TryGenerateItem('x')==nil)'''),
 ('swallow_full_code_and_duplicate_slot',r'''local m=setmetatable({m_swallowInfo={{Code='201',Swallowed=1,Count=1},{Code='201',Swallowed=0,Count=2}}},ItemSwallow); local a=item('201',nil); assert(m:CanSwallow(a)); local b={SaveItemProperty=function() end,RemoveItem=function() end,event={Call=function() end}}; m.m_itemModel={GetBoardModel=function() return b end,GetCode=function() return 'swallow' end}; GM.BIManager={LogAction=function() end}; m.event={Call=function() end}; EEventType.ItemSwallow='swallow'; m:Swallow(a); assert(m.m_swallowInfo[1].Swallowed==2 and m.m_swallowInfo[2].Swallowed==0); assert(not m:CanSwallow(item('bubble_201',nil)))'''),
 ('temp_diff_cumulative',r'''GM.ItemDataModel={GetChain=function() return {'201','202','203'} end}; local m=setmetatable({},TempItemModel); local d=m:_GetLevelOneCountDiffs('flour',{['202']=1}); assert(d[1]==1 and d[2]==0 and d[3]==2)'''),
]

POST_SETUP=r'''
local b=board(); local p=BoardPosition.Create(4,3); local a=item('201',BoardPosition.Create(3,3)); local t=item('201',p); local n=item('202',p)
BaseActionBoardModel._DoMergeItem=function() log('baseMerge'); return {New=n,Source=a,Target=t,itemType='201'} end
b.m_lastBreakBubbleType='201'; b.IsBoardFull=function() return full end; full=false
b.FindEmptyPositionInSpreadOrder=function() log('positionSearch'); return p end
b.SpreadItem=function(_,src,pos,code) log('spread:'..code); if fillOnSpread then full=true end end
b._TrySpreadBubbleByMerge=function() log('ordinaryBubble'); return bubbleResult end
b.m_itemLayerModel={GetItem=function() return nil end}
local models={score={_OnItemMerged=function() assert(b.m_lastBreakBubbleType==nil); log('score'); return nil end},
temp={GenerateType=function() log('temp'); return tempResult end},
card={TryGenerateItem=function(_,c) assert(c=='201'); log('card'); return cardResult end},
energy={CanSpreadEnergyBubble=function() log('energyCheck'); return energyEnabled end,
GetBubbleInfo=function() log('energyInfo'); return energyResult end},
sale={IsActivityOpen=function() return false end}}
GM.ActivityManager={GetModel=function(_,k) return models[k] end}
GM.SystemConfigModel={GetConfig=function() log('coinThreshold'); return 8 end}
GM.ItemDataModel={GetChainLevel=function() return newLevel or 2 end}
GM.SyncModel={CheckMoreUpload=function() log('sync') end}
EEventType.CardItemGenerate='cardGenerate'; ItemCodePrefix.Temp='temp_'
'''
CASES += [
 ('post_temp_exclusive_coin_independent',POST_SETUP+r'''tempResult='204'; newLevel=8; b:_DoMergeItem(a,t,p); assert(table.concat(trace,',')=='baseMerge,score,temp,positionSearch,spread:temp_204,coinThreshold,positionSearch,spread:coin,sync')'''),
 ('post_card_then_no_energy',POST_SETUP+r'''cardResult='card1'; b:_DoMergeItem(a,t,p); assert(table.concat(trace,',')=='baseMerge,score,temp,card,positionSearch,spread:card1,event:cardGenerate,coinThreshold,sync')'''),
 ('post_energy_before_ordinary',POST_SETUP+r'''energyEnabled=true; energyResult={Code='energybubble',Group=2}; local r=b:_DoMergeItem(a,t,p); assert(r.BubbleType=='energybubble' and r.Group==2); assert(table.concat(trace,',')=='baseMerge,score,temp,card,energyCheck,energyInfo,positionSearch,spread:energybubble,coinThreshold,sync')'''),
 ('post_full_still_calls_energy_branch',POST_SETUP+r'''full=true; energyEnabled=true; energyResult={Code='energybubble',Group=2}; b.FindEmptyPositionInSpreadOrder=function() log('nilPosition'); return nil end; b.SpreadItem=function(_,src,pos,code) assert(pos==nil); log('savedWithoutPosition') end; b:_DoMergeItem(a,t,p); assert(table.concat(trace,',')=='baseMerge,score,energyCheck,energyInfo,nilPosition,savedWithoutPosition,sync')'''),
 ('post_last_space_suppresses_coin',POST_SETUP+r'''tempResult='204'; newLevel=8; fillOnSpread=true; b:_DoMergeItem(a,t,p); assert(table.concat(trace,',')=='baseMerge,score,temp,positionSearch,spread:temp_204,sync')'''),
 ('post_no_activity_checks_bubble_then_coin',POST_SETUP+r'''b:_DoMergeItem(a,t,p); assert(table.concat(trace,',')=='baseMerge,score,temp,card,energyCheck,ordinaryBubble,coinThreshold,sync')'''),
 ('post_clears_purchase_before_score',POST_SETUP+r'''b.m_lastBreakBubbleType='201'; b:_DoMergeItem(a,t,p); assert(b.m_lastBreakBubbleType==nil)'''),
]


def run():
    results=[]
    for kind in ('bytecode','recovered-source'):
        for name,body in CASES:
            lua=LuaRuntime(); lua.execute(SETUP)
            result={'case':name,'kind':kind}
            try:
                for module in NAMES:
                    m=BY_NAME[module]
                    payload=(ROOT/m['standard_path']).read_bytes() if kind=='bytecode' else source(module).read_text(encoding='utf-8')
                    lua.execute(payload)
                lua.execute(body)
                result['status']='passed'
                t=lua.globals().trace
                result['trace']=[t[i] for i in range(1,len(t)+1)]
            except Exception as e:result.update(status='failed',error=str(e))
            results.append(result)
    AUDIT.mkdir(exist_ok=True)
    report={'verification':'controlled-bytecode-and-source','original_client_runtime_confirmed':False,
        'limitations':'Selected rules; GM, event, DB, item and view services are doubles. Does not approve full operation closure, account values or native persistence.',
        'module_hashes':{n:{'bytecode':BY_NAME[n]['sha256'],'source':sha(source(n))} for n in NAMES},
        'cases':results,'passed':sum(r['status']=='passed' for r in results),'total':len(results)}
    (AUDIT/'rule_tests.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'passed':report['passed'],'total':report['total'],'failed':[r for r in results if r['status']=='failed']},ensure_ascii=False,indent=2))
    if report['passed']!=report['total']:raise SystemExit(1)


if __name__=='__main__':run()
