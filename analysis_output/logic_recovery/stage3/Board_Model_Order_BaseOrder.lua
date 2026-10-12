OrderType = {
  Fixed = 1,
  Random = 2,
  Special = 3
}
OrderState = {
  Dormant = 0,
  Init = 1,
  PartiallyFinished = 2,
  CanDeliver = 3,
  Finished = 4
}
OrderStateChange = {Higher = 1, Lower = 2}
BaseOrder = {}
BaseOrder.__index = BaseOrder

function BaseOrder.Create(id, requirements)
  local order = setmetatable({}, BaseOrder)
  order:Init(id, requirements)
  return order
end

function BaseOrder:Init(id, requirements)
  self.m_id = id
  self.m_requirements = {}
  self.m_requirementFillStates = {}
  for i = 1, #requirements do
    if not StringUtil.IsNilOrEmpty(requirements[i]) then
      self.m_requirements[#self.m_requirements + 1] = requirements[i]
      self.m_requirementFillStates[#self.m_requirementFillStates + 1] = false
    end
  end
  self.m_filledRequirementCount = 0
  if #self.m_requirements == 0 then
    self:_SetState(OrderState.Dormant)
  else
    self:_SetState(OrderState.Init)
  end
end

function BaseOrder:GetId()
  return self.m_id
end

function BaseOrder:UpdateId(id)
  self.m_id = id
end

function BaseOrder:GetRequirements()
  return self.m_requirements
end

function BaseOrder:UpdateRequirements(requirements)
  self.m_requirements = requirements
end

function BaseOrder:GetRequirementFillStates()
  return self.m_requirementFillStates
end

function BaseOrder:GetFilledRequirementCount()
  return self.m_filledRequirementCount
end

function BaseOrder:GetState()
  return self.m_state
end

function BaseOrder:_SetState(state)
  Log.Assert(state ~= OrderState.Finished, "BaseOrder:_SetState")
  if self.m_state ~= state then
    if self.m_state == nil or state > self.m_state then
      self.m_stateChange = OrderStateChange.Higher
    else
      self.m_stateChange = OrderStateChange.Lower
    end
    self.m_state = state
    self.m_stateChangeTime = GM.GameModel:GetServerTime()
  end
end

function BaseOrder:UpdateState(codeCountMap)
  if self.m_state == OrderState.Finished then
    return
  end
  self.m_filledRequirementCount = 0
  for i, requirement in ipairs(self.m_requirements) do
    local count = 1
    for k = i - 1, 1, -1 do
      if requirement == self.m_requirements[k] then
        count = count + 1
      end
    end
    if codeCountMap[requirement] ~= nil and count <= codeCountMap[requirement] then
      self.m_requirementFillStates[i] = true
      self.m_filledRequirementCount = self.m_filledRequirementCount + 1
    else
      self.m_requirementFillStates[i] = false
    end
  end
  if #self.m_requirements == 0 then
    self:_SetState(OrderState.Dormant)
  elseif self.m_filledRequirementCount == 0 then
    self:_SetState(OrderState.Init)
  elseif self.m_filledRequirementCount == #self.m_requirements then
    self:_SetState(OrderState.CanDeliver)
  else
    self:_SetState(OrderState.PartiallyFinished)
  end
end

function BaseOrder:CanDeliver(codeCountMap)
  local canDeliver = true
  local lackedCodeCountMap = {}
  for i, requirement in ipairs(self.m_requirements) do
    local count = 1
    for k = i - 1, 1, -1 do
      if requirement == self.m_requirements[k] then
        count = count + 1
      end
    end
    if codeCountMap[requirement] == nil or count > codeCountMap[requirement] then
      canDeliver = false
      lackedCodeCountMap[requirement] = count - (codeCountMap[requirement] or 0)
    end
  end
  return canDeliver, lackedCodeCountMap
end

function BaseOrder:SetFinished()
  if Table.IsEmpty(self.m_cacheRewards) then
    self.m_cacheRewards = self:GetRewards()
  end
  self.m_state = OrderState.Finished
end

function BaseOrder:GetStateChange()
  return self.m_stateChange
end

function BaseOrder:GetStateChangeTime()
  return self.m_stateChangeTime
end

function BaseOrder:GetType()
  Log.Assert(false, "GetType()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function BaseOrder:GetAvatarName()
  Log.Assert(false, "GetAvatarName()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function BaseOrder:GetMaxPossibleRewardNumber()
  Log.Assert(false, "GetMaxPossibleRewardNumber()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function BaseOrder:GetRewards()
  Log.Assert(false, "GetRewards()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function BaseOrder:GetScore(includeGold)
  return self:_CalculateScore(self:GetRewards(), includeGold)
end

function BaseOrder:_CalculateScore(rewards, includeGold)
  local score = 0
  for i = 1, #rewards do
    if includeGold and rewards[i][PROPERTY_TYPE] == EPropertyType.Gold or rewards[i][PROPERTY_TYPE] == EPropertyType.BakeOutToken then
      score = score + rewards[i][PROPERTY_COUNT]
    end
  end
  return score
end

function BaseOrder:GetGiftRewards()
  return nil
end

function BaseOrder:IsBuffGoldDouble()
  return false
end

function BaseOrder:GetGameMode()
  return EGameMode.Main
end

function BaseOrder:GetDiffRange()
  return nil
end
