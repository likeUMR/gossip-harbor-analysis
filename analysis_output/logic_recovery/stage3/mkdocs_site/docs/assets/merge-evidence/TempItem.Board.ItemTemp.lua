ItemTemp = setmetatable({}, BaseItemComponent)
ItemTemp.__index = ItemTemp

function ItemTemp.Create(innerItemCode)
  local itemTemp = setmetatable({}, ItemTemp)
  itemTemp:Init(innerItemCode)
  return itemTemp
end

function ItemTemp:Init(innerItemCode)
  self.m_innerItemCode = innerItemCode
  self.m_forcedDuration = TutorialBoardHelper.GetForcedTimerDuration()
end

function ItemTemp:UpdatePerSecond()
  if self:GetTimerAmount() == 1 then
    self:_Disappear(false)
  end
end

function ItemTemp:OnSpeedUp()
  self:_Disappear(true)
end

function ItemTemp:GetInnerItemCode()
  return self.m_innerItemCode
end

function ItemTemp:GetTimerDuration()
  if self.m_forcedDuration ~= nil then
    return self.m_forcedDuration
  end
  local model = GM.ActivityManager:GetModel(ActivityType.TempItem)
  return model:GetItemDuration(self.m_innerItemCode)
end

function ItemTemp:GetStartTimer()
  if self.m_forcedDuration ~= nil then
    return GM.GameModel:GetServerTime()
  end
  local model = GM.ActivityManager:GetModel(ActivityType.TempItem)
  return model:GetItemStartTimer()
end

function ItemTemp:GetTimerAmount()
  local elapsedTime = GM.GameModel:GetServerTime() - self:GetStartTimer()
  return math.min(elapsedTime / self:GetTimerDuration(), 1)
end

function ItemTemp:_Disappear(forced)
  local model = GM.ActivityManager:GetModel(ActivityType.TempItem)
  model:MarkRoundEnd()
  local boardModel = self.m_itemModel:GetBoardModel()
  local newItem = boardModel:ReplaceItem(self.m_itemModel, model:GetTransformTargetType())
  local message = {
    Source = self.m_itemModel,
    New = newItem,
    CostEnergy = false
  }
  boardModel.event:Call(BoardEventType.TempDisappear, message)
  EventDispatcher.DispatchEvent(EEventType.TempDisappear, message)
  local action = {
    innerType = self.m_innerItemCode,
    transformType = newItem:GetType(),
    forced = forced
  }
  GM.BIManager:LogAction(EBIType.TempDisappear, action)
end
