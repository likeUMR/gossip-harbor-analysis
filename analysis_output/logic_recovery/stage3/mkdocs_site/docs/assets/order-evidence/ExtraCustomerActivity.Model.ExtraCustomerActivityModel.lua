ExtraCustomerActivityModel = setmetatable({}, BaseActivityModel)
ExtraCustomerActivityModel.__index = ExtraCustomerActivityModel
local DBColumnValue = "value"
local DBKeys = {
  CoolDownTime = "CoolDownTime",
  LimitTime = "LimitTime",
  HasActiveOrder = "HasActiveOrder",
  NeedAutoPopTip = "NeedAutoPopTip",
  FirstAppear = "FirstAppear",
  FirstAppearTime = "FirstAppearTime"
}

function ExtraCustomerActivityModel:Init(activityDataTable)
  BaseActivityModel.Init(self, ActivityType.ExtraCustomer, activityDataTable)
end

function ExtraCustomerActivityModel:LateInit()
  BaseActivityModel.LateInit(self)
  if (self:GetState(false) == ActivityState.Released or not self:HasActiveOrder()) and GM.MainBoardModel:GetOrders(OrderModelType.Slot) and GM.MainBoardModel:GetOrders(OrderModelType.Slot)[MainOrderSlotDefinition.ExtraCustomerSlot] then
    self:SaveHasActiveOrder(false)
    GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):RemoveOrder(MainOrderSlotDefinition.ExtraCustomerSlot)
  end
  if GM.MainBoardModel:GetOrders(OrderModelType.Slot) and not GM.MainBoardModel:GetOrders(OrderModelType.Slot)[MainOrderSlotDefinition.ExtraCustomerSlot] then
    self:SaveHasActiveOrder(false)
  end
  self.m_lateInit = true
end

function ExtraCustomerActivityModel:Destroy()
  EventDispatcher.RemoveTarget(self)
end

function ExtraCustomerActivityModel:_LoadOtherServerConfig(config)
  self.m_extraCustomerConfig = Table.DeepCopy(config.extraCustomerConfig)
  for _, myConfig in ipairs(self.m_extraCustomerConfig) do
    myConfig.timesMin = myConfig.timesMin or 0
    myConfig.cooldown = myConfig.cooldown.range_entry or {0, 0}
  end
  table.sort(self.m_extraCustomerConfig, function(a, b)
    return a.timesMin < b.timesMin
  end)
  for i = 1, #self.m_extraCustomerConfig - 1 do
    if self.m_extraCustomerConfig[i].timesMin == self.m_extraCustomerConfig[i + 1].timesMin then
      Log.Assert(false, "timesMin\233\133\141\231\189\174\230\156\137\233\135\141\229\143\160", LogTag.ConfigCheck)
    end
  end
end

function ExtraCustomerActivityModel:_DropData()
  BaseActivityModel._DropData(self)
  self.m_myOrder = nil
  self.m_needBanner = nil
  self.m_needTrayAnim = nil
end

function ExtraCustomerActivityModel:_OnStateChanged()
  EventDispatcher.DispatchEvent(EEventType.ExtraCustomerStateChanged)
  if self.m_lateInit and (self:GetState(false) == ActivityState.Released or not self:HasActiveOrder()) and GM.MainBoardModel:GetOrders(OrderModelType.Slot) and GM.MainBoardModel:GetOrders(OrderModelType.Slot)[MainOrderSlotDefinition.ExtraCustomerSlot] then
    self:SaveHasActiveOrder(false)
    GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):RemoveOrder(MainOrderSlotDefinition.ExtraCustomerSlot)
  end
end

function ExtraCustomerActivityModel:GetResourceLabels()
  return {
    AddressableLabel.ExtraCustomer
  }
end

function ExtraCustomerActivityModel:CanCreateOrder(slot)
  if slot ~= MainOrderSlotDefinition.ExtraCustomerSlot then
    return false
  end
  if self:GetState() ~= ActivityState.Started or self.m_config.eTime - GM.GameModel:GetServerTime() < Sec2Hour then
    return false
  end
  if self:HasActiveOrder() then
    return false
  end
  if GM.MainBoardModel:GetOrders(OrderModelType.Slot) and GM.MainBoardModel:GetOrders(OrderModelType.Slot)[MainOrderSlotDefinition.ExtraCustomerSlot] then
    return false
  end
  if not self:GetCoolDownTime() then
    return true
  elseif GM.GameModel:GetServerTime() > self:GetCoolDownTime() then
    return true
  else
    return false
  end
end

function ExtraCustomerActivityModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  if self:HasActiveOrder() then
    self.m_myOrder = self.m_myOrder or GM.MainBoardModel:GetOrders(OrderModelType.Slot)[MainOrderSlotDefinition.ExtraCustomerSlot]
    if self.m_myOrder and self.m_myOrder:GetState() ~= OrderState.Dormant and self.m_myOrder:GetState() ~= OrderState.Finished then
      if GM.GameModel:GetServerTime() >= self:GetLimitTime() then
        self:FailedOrder()
      end
    elseif self.m_myOrder and self.m_myOrder:GetState() == OrderState.Dormant and GM.GameModel:GetServerTime() >= self.m_config.eTime and GM.MainBoardModel:GetOrderModel(OrderModelType.Slot) then
      self:SaveHasActiveOrder(false)
      GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):RemoveOrder(MainOrderSlotDefinition.ExtraCustomerSlot)
    end
  end
end

function ExtraCustomerActivityModel:CreateOrder(orderModel, slot)
  if slot ~= MainOrderSlotDefinition.ExtraCustomerSlot then
    return
  end
  self:SaveHasActiveOrder(true)
  self:SaveNeedBanner(true)
  self:SaveNeedAutoPopTip(true)
  self:SaveFirstAppear(true)
  self.m_dbTable:Remove(DBKeys.CoolDownTime, DBColumnValue)
  self.m_dbTable:Remove(DBKeys.LimitTime, DBColumnValue)
  return EmptyReqOrder.Create(orderModel, MainOrderSlotDefinition.ExtraCustomerSlot, nil, {}, MainOrderType.ExtraCustomer, 3001, false)
end

function ExtraCustomerActivityModel:GetSmileRewardNumber()
  local times = self:GetExtraCustomerCompleteTimes()
  local config = self:GetSingleConfig(times)
  local rewards = config.rewards
  for _, reward in ipairs(rewards) do
    if RewardApi.CheckRewardPrefix(reward[PROPERTY_TYPE], ORDER_BOOST_SMILE_PREFIX) then
      return reward[PROPERTY_COUNT]
    end
  end
  return 0
end

function ExtraCustomerActivityModel:FinishOrder()
  local times = self:GetExtraCustomerCompleteTimes()
  local config = self:GetSingleConfig(times)
  RewardApi.AcquireRewardsLogic(config.rewards, EPropertySource.Give, EBIType.FinishOrder, EGameMode.Main, CacheItemType.Type2)
  self:IncreaseExtraCustomerCompleteTimes()
  times = self:GetExtraCustomerCompleteTimes()
  config = self:GetSingleConfig(times)
  self:SaveCoolDownTime(GM.GameModel:GetServerTime() + config.cooldown[1] * Sec2Hour)
  self:SaveHasActiveOrder(false)
end

function ExtraCustomerActivityModel:RejectOrder()
  local times = self:GetExtraCustomerCompleteTimes()
  local config = self:GetSingleConfig(times)
  self:SaveCoolDownTime(GM.GameModel:GetServerTime() + config.cooldown[2] * Sec2Hour)
  self:SaveHasActiveOrder(false)
  EventDispatcher.DispatchEvent(EEventType.ExtraCustomerRejected)
  local myOrder = GM.MainBoardModel:GetOrders(OrderModelType.Slot)[MainOrderSlotDefinition.ExtraCustomerSlot]
  GM.BIManager:LogAction(EBIType.ExtraCustomerRejected, {
    actID = self:GetId(),
    orderID = myOrder:GetId(),
    elapsed = GM.GameModel:GetServerTime() - self:GetFirstAppearTime()
  })
end

function ExtraCustomerActivityModel:AcceptOrder()
  local times = self:GetExtraCustomerCompleteTimes()
  local config = self:GetSingleConfig(times)
  if config.timelimit then
    local tempTime = GM.GameModel:GetServerTime() + config.timelimit * Sec2Hour
    tempTime = math.min(tempTime, self.m_config.rTime)
    self:SaveLimitTime(tempTime)
  else
    self:SaveLimitTime(self.m_config.rTime)
  end
  local myOrder = GM.MainBoardModel:GetOrders(OrderModelType.Slot)[MainOrderSlotDefinition.ExtraCustomerSlot]
  if myOrder then
    self:SaveNeedTrayAnim(true)
    myOrder:TryRefreshMyRequirements({
      ItemType.Flour12
    })
    EventDispatcher.DispatchEvent(EEventType.ExtraCustomerAccepted)
    GM.BIManager:LogAction(EBIType.ExtraCustomerAccepted, {
      actID = self:GetId(),
      orderID = myOrder:GetId(),
      elapsed = GM.GameModel:GetServerTime() - self:GetFirstAppearTime()
    })
  end
end

function ExtraCustomerActivityModel:FailedOrder()
  local myOrder = GM.MainBoardModel:GetOrders(OrderModelType.Slot)[MainOrderSlotDefinition.ExtraCustomerSlot]
  if myOrder and myOrder:GetState() ~= OrderState.Finished then
    local times = self:GetExtraCustomerCompleteTimes()
    local config = self:GetSingleConfig(times)
    self:SaveCoolDownTime(self:GetLimitTime() + config.cooldown[1] * Sec2Hour)
    GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):RemoveOrder(MainOrderSlotDefinition.ExtraCustomerSlot)
  end
  self:SaveHasActiveOrder(false)
end

function ExtraCustomerActivityModel:CanShowCountDown()
  local myOrder = GM.MainBoardModel:GetOrders(OrderModelType.Slot)[MainOrderSlotDefinition.ExtraCustomerSlot]
  if not myOrder or myOrder:GetState() == OrderState.Dormant then
    return false
  end
  local times = self:GetExtraCustomerCompleteTimes()
  if self:GetSingleConfig(times).timelimit then
    return true
  elseif self:GetRTime() - GM.GameModel:GetServerTime() <= 2 * Sec2Hour then
    return true
  else
    return false
  end
end

function ExtraCustomerActivityModel:NeedAutoPopTip()
  return self.m_dbTable:GetValue(DBKeys.NeedAutoPopTip, DBColumnValue) or false
end

function ExtraCustomerActivityModel:SaveNeedAutoPopTip(value)
  self.m_dbTable:Set(DBKeys.NeedAutoPopTip, DBColumnValue, value)
end

function ExtraCustomerActivityModel:HasActiveOrder()
  return self.m_dbTable:GetValue(DBKeys.HasActiveOrder, DBColumnValue) or false
end

function ExtraCustomerActivityModel:SaveHasActiveOrder(has)
  self.m_dbTable:Set(DBKeys.HasActiveOrder, DBColumnValue, has)
  if not has then
    self.m_myOrder = nil
  end
end

function ExtraCustomerActivityModel:GetLimitTime()
  return self.m_dbTable:GetValue(DBKeys.LimitTime, DBColumnValue)
end

function ExtraCustomerActivityModel:SaveLimitTime(time)
  self.m_dbTable:Set(DBKeys.LimitTime, DBColumnValue, time)
end

function ExtraCustomerActivityModel:GetCoolDownTime()
  return self.m_dbTable:GetValue(DBKeys.CoolDownTime, DBColumnValue)
end

function ExtraCustomerActivityModel:SaveCoolDownTime(time)
  self.m_dbTable:Set(DBKeys.CoolDownTime, DBColumnValue, time)
end

function ExtraCustomerActivityModel:GetFirstAppear()
  return self.m_dbTable:GetValue(DBKeys.FirstAppear, DBColumnValue) or false
end

function ExtraCustomerActivityModel:SaveFirstAppear(v)
  self.m_dbTable:Set(DBKeys.FirstAppear, DBColumnValue, v)
end

function ExtraCustomerActivityModel:GetFirstAppearTime()
  return self.m_dbTable:GetValue(DBKeys.FirstAppearTime, DBColumnValue) or 0
end

function ExtraCustomerActivityModel:SaveFirstAppearTime(v)
  self.m_dbTable:Set(DBKeys.FirstAppearTime, DBColumnValue, v)
end

function ExtraCustomerActivityModel:SaveNeedBanner(need)
  self.m_needBanner = need
end

function ExtraCustomerActivityModel:GetNeedBanner()
  return self.m_needBanner
end

function ExtraCustomerActivityModel:SaveNeedTrayAnim(need)
  self.m_needTrayAnim = need
end

function ExtraCustomerActivityModel:NeedTrayAnim()
  return self.m_needTrayAnim
end

function ExtraCustomerActivityModel:GetSingleConfig(times)
  times = times or self:GetExtraCustomerCompleteTimes()
  for i, conf in ipairs(self.m_extraCustomerConfig) do
    if times < conf.timesMin then
      return self.m_extraCustomerConfig[i - 1]
    end
  end
  return self.m_extraCustomerConfig[#self.m_extraCustomerConfig]
end

function ExtraCustomerActivityModel:IncreaseExtraCustomerCompleteTimes()
  local res = self:GetExtraCustomerCompleteTimes()
  res = res + 1
  GM.MiscModel:SetExtraCustomerCompleteTimes(tostring(res))
end

function ExtraCustomerActivityModel:ResetExtraCustomerCompleteTimes()
  GM.MiscModel:SetExtraCustomerCompleteTimes(tostring(0))
end

function ExtraCustomerActivityModel:GetExtraCustomerCompleteTimes()
  local res = GM.MiscModel:GetExtraCustomerCompleteTimes()
  return res == nil and 0 or tonumber(res)
end

function ExtraCustomerActivityModel:GetRTime()
  return self.m_config.rTime
end

function ExtraCustomerActivityModel:GetETime()
  return self.m_config.eTime
end
