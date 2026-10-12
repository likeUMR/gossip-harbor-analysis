ContiordersModel = setmetatable({}, BaseActivityModel)
ContiordersModel.__index = ContiordersModel
DBColumnValue = "value"
local DBKey = {
  PopEndWindow = "PopEndWindow",
  CurrentIndex = "CurrentIndex",
  CurrentStartTime = "CurrentStartTime",
  CurrentEndTime = "CurrentEndTime",
  Started = "Started",
  LastOpenMainwindowIndex = "LastOpenMainwindowIndex",
  LastReturnSmileCount = "LastReturnSmileCount"
}

function ContiordersModel:Init(activityType, activityDataTable)
  self.m_definition = ContiordersDefinition[activityType]
  BaseActivityModel.Init(self, activityType, activityDataTable)
  self.m_canCreateOrderFlag = true
  EventDispatcher.AddListener(EEventType.CloseView, self, self.OnCloseView)
end

function ContiordersModel:LateInit()
  BaseActivityModel.LateInit(self)
  self.m_lateInit = true
  if self.m_needRemoveOrder then
    self:_RemoveOrder()
  end
end

function ContiordersModel:CanCreateOrder(slot)
  if slot ~= MainOrderSlotDefinition.ContiorderSlot then
    return false
  end
  if self:GetState(false) ~= ActivityState.Started and self:GetState(false) ~= ActivityState.Ended then
    return false
  end
  if self:GetState(false) == ActivityState.Ended and not self:GetStarted() then
    return false
  end
  if self:GetIndex() < 0 or self:GetIndex() > self:GetTotalOrderCount() then
    return false
  end
  if not self:GetStarted() then
    return false
  end
  if GM.UIManager:GetOpenedViewByName(self.m_definition.MainWindowPrefabName) then
    return false
  end
  if self.m_canCreateOrderFlag == false then
    return false
  end
  return true
end

function ContiordersModel:CreateOrder(orderModel, slot)
  if slot ~= MainOrderSlotDefinition.ContiorderSlot then
    return
  end
  local mapRepeatWeightDecreaseInfo = RepeatWeightDecreaseHelper.InitMapInfo(MainOrderType.Contiorder, orderModel)
  local alreadyRequiredItems = {}
  
  local function selectItem(minLevel, maxLevel)
    local availableItems, backAvailableItems = RandomOrderHelper.GetAvailableItems({
      orderModel = orderModel,
      slot = MainOrderSlotDefinition.ContiorderSlot,
      alreadyRequiredItems = alreadyRequiredItems
    })
    availableItems = RandomOrderHelper.FilterByLevel(availableItems, minLevel, maxLevel, orderModel)
    backAvailableItems = RandomOrderHelper.FilterByLevel(backAvailableItems, minLevel, maxLevel, orderModel)
    local selectedItem
    if #availableItems ~= 0 then
      RepeatWeightDecreaseHelper.DecreaseItemWeight(availableItems, mapRepeatWeightDecreaseInfo, orderModel)
      selectedItem = Table.ListWeightSelectOne(availableItems).Code
      backAvailableItems = nil
    elseif #backAvailableItems == 0 then
      return nil
    else
      RepeatWeightDecreaseHelper.DecreaseItemWeight(backAvailableItems, mapRepeatWeightDecreaseInfo, orderModel)
      selectedItem = Table.ListWeightSelectOne(backAvailableItems).Code
    end
    table.insert(alreadyRequiredItems, selectedItem)
    if GameConfig.IsTestMode() then
      TestOrderLogInfo.TestPrintBackItemsInfo({
        slot = slot,
        availableItems = availableItems,
        backavailableItems = backAvailableItems,
        selectedItem = selectedItem,
        minLevel = minLevel,
        maxLevel = maxLevel,
        mapRepeatWeightDecreaseInfo = mapRepeatWeightDecreaseInfo
      })
    end
    RepeatWeightDecreaseHelper.MarkSelectedLine(selectedItem, mapRepeatWeightDecreaseInfo, orderModel)
    return selectedItem
  end
  
  local curIndex = self:GetIndex()
  local req = {}
  req[1] = selectItem(self.m_ordersConfig[curIndex].item1.range_entry[1], self.m_ordersConfig[curIndex].item1.range_entry[2])
  if req[1] and self.m_ordersConfig[curIndex].item2 then
    req[2] = selectItem(self.m_ordersConfig[curIndex].item2.range_entry[1], self.m_ordersConfig[curIndex].item2.range_entry[2])
  end
  if req[2] and self.m_ordersConfig[curIndex].item3 then
    req[3] = selectItem(self.m_ordersConfig[curIndex].item3.range_entry[1], self.m_ordersConfig[curIndex].item3.range_entry[2])
  end
  if req[1] == nil then
    req[1] = ItemType.Flour09
    GM.BIManager:LogErrorInfo(self.m_definition.ErrorNoItemBIType, "\230\178\161\230\137\190\229\136\176\228\187\187\228\189\149\229\143\175\231\148\168\230\163\139\229\173\144\239\188\140\228\189\191\231\148\168\229\133\156\229\186\149\230\163\139\229\173\144 ItemType.Flour09")
  end
  if GameConfig.IsTestMode() then
    local randomConfig = {
      Type = MainOrderType.Contiorder,
      RefreshTime = 9999,
      UnlockLevel = 9999,
      Point = 9999,
      Filters = {
        {
          FirstMin = self.m_ordersConfig[curIndex].item1.range_entry[1],
          FirstMax = self.m_ordersConfig[curIndex].item1.range_entry[2]
        }
      }
    }
    if self.m_ordersConfig[curIndex].item2 then
      randomConfig.Filters[1].SecondMin = self.m_ordersConfig[curIndex].item2.range_entry[1]
      randomConfig.Filters[1].SecondMax = self.m_ordersConfig[curIndex].item2.range_entry[2]
    end
    if self.m_ordersConfig[curIndex].item3 then
      randomConfig.Filters[1].ThirdMin = self.m_ordersConfig[curIndex].item3.range_entry[1]
      randomConfig.Filters[1].ThirdMax = self.m_ordersConfig[curIndex].item3.range_entry[2]
    end
    TestOrderLogInfo.TestPrintOrderChosenItemsInfo({
      innerType = MainOrderType.Contiorder,
      weightConfig = nil,
      firstSelectedItem = alreadyRequiredItems[1],
      secondSelectedItem = alreadyRequiredItems[2],
      thirdSelectedItem = alreadyRequiredItems[3],
      requirements = alreadyRequiredItems,
      slot = slot,
      orderModel = orderModel,
      randomConfig = randomConfig,
      mapRepeatWeightDecreaseInfo = mapRepeatWeightDecreaseInfo
    })
    local log = TestOrderLogInfo.strCreateOrderTestLog
    TestOrderLogInfo.Clear()
    Log.Info("\232\174\162\229\141\149\232\191\158\232\191\158-\232\174\162\229\141\149\231\148\159\230\136\144\230\151\165\229\191\151\n" .. log)
  end
  RepeatWeightDecreaseHelper.UpdateMapInfo(mapRepeatWeightDecreaseInfo, orderModel)
  return MainOrder.Create(orderModel, MainOrderSlotDefinition.ContiorderSlot, curIndex, req, MainOrderType.Contiorder, 2001, false)
end

function ContiordersModel:GetExtraReward()
  local index = self:GetIndex()
  if index < 0 or index > self:GetTotalOrderCount() then
    return nil
  end
  return self.m_ordersConfig[index].reward
end

function ContiordersModel:GetSmileCount()
  local index = self:GetIndex()
  if index < 0 or index > self:GetTotalOrderCount() then
    return 0
  end
  local boostModel = GM.ActivityManager:GetModel(ActivityType.OrderBoost)
  if boostModel:SmileCompleted() then
    return math.max(0, self:GetLastReturnSmileCount())
  else
    self:SetLastReturnSmileCount(self.m_ordersConfig[index].boost or 0)
    return self.m_ordersConfig[index].boost or 0
  end
end

function ContiordersModel:GetFinalReward()
  return {
    self.m_finalOrderConfig.reward
  }
end

function ContiordersModel:Destroy()
  EventDispatcher.RemoveTarget(self)
end

function ContiordersModel:_LoadOtherServerConfig(config)
  if config.contiordersConfig == nil then
    Log.Error("failed to read database contiordersConfig")
    return
  end
  self.m_ordersConfig = {}
  self.m_finalOrderConfig = nil
  for _, config in ipairs(config.contiordersConfig) do
    if config.index == 0 then
      self.m_finalOrderConfig = config
      self.m_groupId = config.groupId
    else
      table.insert(self.m_ordersConfig, config)
      self.m_ordersConfig[#self.m_ordersConfig].timeInSecond = self.m_ordersConfig[#self.m_ordersConfig].time * 60
    end
  end
  table.sort(self.m_ordersConfig, function(a, b)
    return a.index < b.index
  end)
end

function ContiordersModel:_DropData()
  BaseActivityModel._DropData(self)
  self.m_needRemoveOrder = true
  if self.m_lateInit then
    self:_RemoveOrder()
  end
end

function ContiordersModel:_OnStateChanged()
  EventDispatcher.DispatchEvent(self.m_definition.StateChangedEvent)
  if self:GetState(false) ~= ActivityState.Started and self:GetState(false) ~= ActivityState.Ended or self:GetState(false) ~= ActivityState.Started and self:GetStarted() == false then
    self.m_needRemoveOrder = true
    if self.m_lateInit then
      self:_RemoveOrder()
    end
  end
end

function ContiordersModel:_RemoveOrder()
  local startedContiModel
  for activityType, definition in pairs(ContiordersDefinition) do
    local model = GM.ActivityManager:GetModel(activityType)
    if model and (model:GetState(false) == ActivityState.Started or model:GetState(false) == ActivityState.Ended) then
      startedContiModel = model
      break
    end
  end
  if startedContiModel == nil or startedContiModel:GetIndex() < 0 then
    GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):RemoveOrder(MainOrderSlotDefinition.ContiorderSlot)
  end
  local orders = GM.MainBoardModel:GetOrders(OrderModelType.Slot)
  local order = orders[MainOrderSlotDefinition.ContiorderSlot]
  if order and order:GetAvatarName() == self.m_definition.OrderAvatarName then
    GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):RemoveOrder(MainOrderSlotDefinition.ContiorderSlot)
  end
end

function ContiordersModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  if self:GetState(false) ~= ActivityState.Started and self:GetState(false) ~= ActivityState.Ended then
    return
  end
  if self:GetIndex() < 0 or self:GetIndex() > self:GetTotalOrderCount() or not self:GetStarted() then
    return
  end
  if GM.GameModel:GetServerTime() >= self:GetEndTime() then
    self:SetIndex(-2)
    self.m_needRemoveOrder = true
    if self.m_lateInit then
      self:_RemoveOrder()
    end
    EventDispatcher.DispatchEvent(self.m_definition.OrderFailedEvent)
    return
  end
end

function ContiordersModel:UnlockFirstOrder()
  if self:GetState(false) ~= ActivityState.Started then
    return
  end
  PrintContiInfo("unlock first order")
  self:SetIndex(1)
  self:SetStartTime(GM.GameModel:GetServerTime())
  self:SetEndTime(self:GetStartTime() + self.m_ordersConfig[1].timeInSecond)
  self:SetStarted(true)
  self:ResetPopEndWindow(false)
  self:SetLastReturnSmileCount(0)
end

function ContiordersModel:UnlockNextOrder()
  if self:GetState(false) ~= ActivityState.Started and self:GetState(false) ~= ActivityState.Ended then
    return
  end
  if GM.GameModel:GetServerTime() > self:GetEndTime() then
    return
  end
  local curIndex = self:GetIndex()
  local nextIndex = curIndex + 1
  self:SetIndex(nextIndex)
  if nextIndex <= self:GetTotalOrderCount() then
    PrintContiInfo("unlock next order, index = ", nextIndex)
    self:SetStartTime(GM.GameModel:GetServerTime())
    self:SetEndTime(self:GetStartTime() + self.m_ordersConfig[nextIndex].timeInSecond)
  else
    RewardApi.AcquireRewardsLogic(self:GetFinalReward(), EPropertySource.Give, self.m_definition.RewardBIType, EGameMode.Main, CacheItemType.Type2)
    GM.BIManager:LogActivity(self:GetType(), self:GetId(), EBIType.ActivityGetRewards, 0, self:GetServerConfigGroupId())
  end
  self:SetLastReturnSmileCount(0)
end

function ContiordersModel:GetResourceLabels()
  return self.m_definition.ResourceLabels
end

function ContiordersModel:SetPopEndWindow()
  self.m_dbTable:Set(DBKey.PopEndWindow, "value", "1")
end

function ContiordersModel:ResetPopEndWindow()
  self.m_dbTable:Set(DBKey.PopEndWindow, "value", "0")
end

function ContiordersModel:CanPopEndWindow()
  return self.m_dbTable:GetValue(DBKey.PopEndWindow, "value") ~= "1"
end

function ContiordersModel:GetServerConfigGroupId()
  return self.m_groupId
end

function ContiordersModel:GetIndex()
  return self.m_dbTable:GetValue(DBKey.CurrentIndex, DBColumnValue) or 1
end

function ContiordersModel:SetIndex(index)
  self.m_dbTable:Set(DBKey.CurrentIndex, DBColumnValue, index)
end

function ContiordersModel:GetStartTime()
  return self.m_dbTable:GetValue(DBKey.CurrentStartTime, DBColumnValue) or 0
end

function ContiordersModel:SetStartTime(time)
  self.m_dbTable:Set(DBKey.CurrentStartTime, DBColumnValue, time)
end

function ContiordersModel:GetEndTime()
  return self.m_dbTable:GetValue(DBKey.CurrentEndTime, DBColumnValue) or 0
end

function ContiordersModel:SetEndTime(time)
  self.m_dbTable:Set(DBKey.CurrentEndTime, DBColumnValue, time)
end

function ContiordersModel:GetTotalOrderCount()
  return #self.m_ordersConfig
end

function ContiordersModel:SetStarted(status)
  self.m_dbTable:Set(DBKey.Started, DBColumnValue, status)
end

function ContiordersModel:GetStarted()
  return self.m_dbTable:GetValue(DBKey.Started, DBColumnValue) or false
end

function ContiordersModel:SetLastOpenMainwindowIndex(index)
  self.m_dbTable:Set(DBKey.LastOpenMainwindowIndex, DBColumnValue, index)
end

function ContiordersModel:GetLastOpenMainwindowIndex()
  return self.m_dbTable:GetValue(DBKey.LastOpenMainwindowIndex, DBColumnValue) or 1
end

function ContiordersModel:SetLastReturnSmileCount(index)
  self.m_dbTable:Set(DBKey.LastReturnSmileCount, DBColumnValue, index)
end

function ContiordersModel:GetLastReturnSmileCount()
  return self.m_dbTable:GetValue(DBKey.LastReturnSmileCount, DBColumnValue) or 0
end

function ContiordersModel:OnCloseView(msg)
  if msg.name == self.m_definition.MainWindowPrefabName then
    self.m_canCreateOrderFlag = true
    GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):UpdatePerSecond()
  end
end

function ContiordersModel:SetFlag(flag)
  self.m_canCreateOrderFlag = flag
end

function ContiordersModel:GetTestPopupWindowConfig()
  return {
    CheckFunc = function()
      return self:GetState() == ActivityState.Started
    end,
    config = {
      GroupName = "\232\174\162\229\141\149\232\191\158\232\191\158(contiorder)",
      WindowList = {
        {
          BtnName = "main",
          BtnClickFunc = function()
            GM.UIManager:OpenView(UIPrefabConfigName.PalaceContiordersMainWindow, self:GetType(), false)
          end
        },
        {
          BtnName = "suc",
          BtnClickFunc = function()
            GM.UIManager:OpenView(UIPrefabConfigName.PalaceContiordersSucWindow, self:GetType(), false)
          end
        },
        {
          BtnName = "end",
          BtnClickFunc = function()
            GM.UIManager:OpenView(UIPrefabConfigName.PalaceContiordersEndWindow, self:GetType())
          end
        }
      }
    }
  }
end

function ContiConcatenate(...)
  local info = "[conti]"
  local t = {
    ...
  }
  for i = 1, #t do
    if t[i] == nil then
      t[i] = "nil"
    end
    info = info .. tostring(t[i]) .. " "
  end
  return info
end

function PrintContiInfo(...)
  if not GameConfig.IsTestMode() then
    return
  end
  Log.Info(ContiConcatenate(...))
end
