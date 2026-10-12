ItemTransformEventType = {StateChanged = 1}
ItemTransform = setmetatable({}, BaseItemComponent)
ItemTransform.__index = ItemTransform

function ItemTransform.Create(itemConfig)
  local itemTransform = setmetatable({}, ItemTransform)
  itemTransform:Init(itemConfig)
  return itemTransform
end

function ItemTransform:Init(itemConfig)
  self.event = PairEvent.Create(self)
  self.m_codeWeightPairs = itemConfig.Transform_Weight
  self.m_duration = itemConfig.Transform_Duration
  self.m_allowTap = itemConfig.Transform_AllowTap == 1
  self.m_speedUpCost = itemConfig.Transform_SpeedUpCost
  if self.m_duration ~= nil then
    self.m_startTimer = GM.GameModel:GetServerTime()
  end
end

function ItemTransform:UpdatePerSecond()
  if self.m_duration == nil then
    return
  end
  if self:GetTimerAmount() == 1 then
    self:Transform()
  end
  self.event:Call(ItemTransformEventType.StateChanged)
end

function ItemTransform:AllowTap()
  return self.m_allowTap
end

function ItemTransform:CanAccelerate()
  return self.m_duration ~= nil and self.m_startTimer ~= nil
end

function ItemTransform:ShowCountdownAnimation()
  local itemAccelerateTime = self.m_itemModel:GetComponent(ItemAccelerateTime)
  return self:CanAccelerate() and itemAccelerateTime:IsAccelerated()
end

function ItemTransform:OnTap()
  if not self.m_allowTap then
    return
  end
  local boardModel = self.m_itemModel:GetBoardModel()
  if not GM.EnergyModel:HasEnoughEnergy(boardModel:GetCostEnergyType(), 1) then
    boardModel.event:Call(BoardEventType.LackEnergy)
    return
  end
  local propertyType = GM.EnergyModel:EnergyTypeToPropertyType(boardModel:GetCostEnergyType())
  GM.PropertyDataManager:Consume(propertyType, 1, EBIType.TransformItem, self.m_itemModel:GetCode())
  self:Transform(true)
end

function ItemTransform:OnSpeedUp(isFree)
  if self.m_duration == nil then
    return
  end
  self:_SpeedUp(isFree)
end

function ItemTransform:_SpeedUp(isFree)
  if not isFree then
    local cost = self:GetSpeedUpCost()
    local gemNumber = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Gem)
    if cost > gemNumber then
      local boardModel = self.m_itemModel:GetBoardModel()
      boardModel.event:Call(BoardEventType.LackGem, {
        LackNumber = cost - gemNumber,
        Scene = EGemCostScene.TimeSkip
      })
      return
    end
    GM.PropertyDataManager:Consume(EPropertyType.Gem, cost, EBIType.SpeedUp, self.m_itemModel:GetCode())
  end
  GM.BIManager:LogAction(EBIType.SpeedUp, {
    t = self.m_itemModel:GetType(),
    d = self.m_duration - (self.m_startTimer and GM.GameModel:GetServerTime() - self.m_startTimer or 0),
    s = isFree and "ad" or "gem"
  })
  self:Transform()
end

function ItemTransform:Transform(costEnergy)
  local targetItemType = Table.ListWeightSelectOne(self.m_codeWeightPairs).Code
  local boardModel = self.m_itemModel:GetBoardModel()
  local newItem = boardModel:ReplaceItem(self.m_itemModel, targetItemType)
  local message = {
    Source = self.m_itemModel,
    New = newItem,
    CostEnergy = costEnergy == true
  }
  boardModel.event:Call(BoardEventType.TransformItem, message)
  EventDispatcher.DispatchEvent(EEventType.ItemTransform, message)
  GM.BIManager:LogAction(EBIType.TransformItem, {
    s = self.m_itemModel:GetCode(),
    t = newItem:GetCode(),
    e = costEnergy == true and 1 or 0
  })
  return newItem
end

function ItemTransform:GetCodeWeightPairs()
  return self.m_codeWeightPairs
end

function ItemTransform:GetDuration()
  return self.m_duration
end

function ItemTransform:GetStartTimer()
  return self.m_startTimer
end

function ItemTransform:GetSpeedUpCost()
  local timerAmount = self:GetTimerAmount()
  local speedUpCost = (1 - timerAmount) * self.m_speedUpCost
  speedUpCost = math.ceil(speedUpCost)
  return math.max(speedUpCost, 1)
end

function ItemTransform:GetTimerAmount()
  local elapsedTime = GM.GameModel:GetServerTime() - self.m_startTimer
  return self:_GetTimerAmount(elapsedTime)
end

function ItemTransform:GetNextTimerAmount()
  local nextElapsedTime = GM.GameModel:GetServerTime() - self.m_startTimer + 1
  return self:_GetTimerAmount(nextElapsedTime)
end

function ItemTransform:_GetTimerAmount(elapsedTime)
  return math.min(elapsedTime / self.m_duration, 1)
end
